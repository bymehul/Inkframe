package vnefall

import "core:fmt"
import "core:math"
import gl "vendor:OpenGL"

// High-quality full-res Gaussian blur (ping-pong).
BLUR_RADIUS :: 8
BLUR_TAPS   :: BLUR_RADIUS + 1

BLUR_FS_SRC :: `#version 330 core
in vec2 TexCoord;
out vec4 FragColor;

uniform sampler2D uTexture;
uniform vec2 uDirection;
uniform vec2 uTexelSize;
uniform float uWeights[9];

void main() {
    vec2 step = uDirection * uTexelSize;
    vec4 color = texture(uTexture, TexCoord) * uWeights[0];
    for (int i = 1; i <= 8; ++i) {
        vec2 o = step * float(i);
        color += texture(uTexture, TexCoord + o) * uWeights[i];
        color += texture(uTexture, TexCoord - o) * uWeights[i];
    }
    FragColor = color;
}
`

BG_Blur_State :: struct {
    ready: bool,
    width, height: i32,
    scale: f32,
    iterations: int,
    fbo_a, fbo_b: u32,
    tex_a, tex_b: u32,
    blur_prog: u32,
    u_proj: i32,
    u_tex: i32,
    u_dir: i32,
    u_texel: i32,
    u_weights: i32,
    sigma: f32,
    strength: f32,
    weights: [BLUR_TAPS]f32,
    last_bg_tex: u32,
    last_strength: f32,
}

bg_blur_init :: proc(b: ^BG_Blur_State, r: ^Renderer) -> bool {
    if b.ready do return true
    
    b.scale = bg_blur_quality_scale(cfg.bg_blur_quality)
    b.iterations = bg_blur_quality_iters(cfg.bg_blur_quality)
    if b.scale <= 0 do b.scale = 1
    
    b.width = i32(cfg.design_width * b.scale)
    b.height = i32(cfg.design_height * b.scale)
    if b.width <= 0 || b.height <= 0 do return false
    
    // Create two render targets (ping-pong)
    b.tex_a, b.fbo_a = bg_blur_create_target(b.width, b.height)
    b.tex_b, b.fbo_b = bg_blur_create_target(b.width, b.height)
    if b.tex_a == 0 || b.tex_b == 0 do return false
    
    // Blur shader (reuse same vertex shader)
    vs := compile_shader(gl.VERTEX_SHADER, VS_SRC)
    fs := compile_shader(gl.FRAGMENT_SHADER, BLUR_FS_SRC)
    if vs == 0 || fs == 0 do return false
    
    b.blur_prog = gl.CreateProgram()
    gl.AttachShader(b.blur_prog, vs)
    gl.AttachShader(b.blur_prog, fs)
    gl.LinkProgram(b.blur_prog)
    
    ok: i32
    gl.GetProgramiv(b.blur_prog, gl.LINK_STATUS, &ok)
    if ok == 0 {
        fmt.eprintln("Blur shader link failed.")
        return false
    }
    
    gl.DeleteShader(vs)
    gl.DeleteShader(fs)
    
    b.u_proj = gl.GetUniformLocation(b.blur_prog, "uProjection")
    b.u_tex = gl.GetUniformLocation(b.blur_prog, "uTexture")
    b.u_dir = gl.GetUniformLocation(b.blur_prog, "uDirection")
    b.u_texel = gl.GetUniformLocation(b.blur_prog, "uTexelSize")
    b.u_weights = gl.GetUniformLocation(b.blur_prog, "uWeights")
    
    b.ready = true
    return true
}

bg_blur_cleanup :: proc(b: ^BG_Blur_State) {
    if b.blur_prog != 0 do gl.DeleteProgram(b.blur_prog)
    if b.fbo_a != 0 do gl.DeleteFramebuffers(1, &b.fbo_a)
    if b.fbo_b != 0 do gl.DeleteFramebuffers(1, &b.fbo_b)
    if b.tex_a != 0 do gl.DeleteTextures(1, &b.tex_a)
    if b.tex_b != 0 do gl.DeleteTextures(1, &b.tex_b)
    b.ready = false
}

bg_blur_set_strength :: proc(b: ^BG_Blur_State, strength: f32) {
    s := strength
    if s < 0 do s = 0
    if s == b.strength do return
    b.strength = s
    if s <= 0 {
        b.sigma = 0
        b.weights[0] = 1
        for i in 1..<BLUR_TAPS do b.weights[i] = 0
        return
    }
    b.sigma = s
    bg_blur_compute_weights(b, s)
}

bg_blur_compute_weights :: proc(b: ^BG_Blur_State, sigma: f32) {
    if sigma <= 0 {
        b.weights[0] = 1
        for i in 1..<BLUR_TAPS do b.weights[i] = 0
        return
    }
    // Gaussian weights for radius 8
    sum: f32 = 0
    for i in 0..<BLUR_TAPS {
        v := math.exp(-f32(i*i) / (2 * sigma * sigma))
        b.weights[i] = v
        if i == 0 {
            sum += v
        } else {
            sum += v * 2
        }
    }
    if sum <= 0 do sum = 1
    for i in 0..<BLUR_TAPS do b.weights[i] /= sum
}

bg_blur_begin_capture :: proc(b: ^BG_Blur_State, r: ^Renderer) {
    gl.BindFramebuffer(gl.FRAMEBUFFER, b.fbo_a)
    gl.Viewport(0, 0, b.width, b.height)
    gl.ClearColor(0, 0, 0, 1)
    gl.Clear(gl.COLOR_BUFFER_BIT)
    
    gl.UseProgram(r.shader)
    proj := ortho_matrix(0, cfg.design_width, cfg.design_height, 0)
    gl.UniformMatrix4fv(r.u_proj, 1, false, &proj[0, 0])
}

bg_blur_end_capture :: proc(b: ^BG_Blur_State, r: ^Renderer, w: ^Window) {
    gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
    gl.Viewport(0, 0, w.width, w.height)
    
    gl.UseProgram(r.shader)
    proj := ortho_matrix(0, cfg.design_width, cfg.design_height, 0)
    gl.UniformMatrix4fv(r.u_proj, 1, false, &proj[0, 0])
}

bg_blur_apply :: proc(b: ^BG_Blur_State, r: ^Renderer, w: ^Window, iterations: int) {
    if !b.ready || b.strength <= 0 do return
    iters := iterations
    if iters < 1 do iters = 1
    
    gl.Disable(gl.BLEND)
    gl.UseProgram(b.blur_prog)
    gl.BindVertexArray(r.vao)
    gl.BindBuffer(gl.ARRAY_BUFFER, r.vbo)
    
    // Fullscreen quad (design coords)
    x := f32(0)
    y := f32(0)
    dw := f32(cfg.design_width)
    dh := f32(cfg.design_height)
    verts := [6][4]f32{
        {x,     y,     0, 0},
        {x + dw, y,     1, 0},
        {x + dw, y + dh, 1, 1},
        {x,     y,     0, 0},
        {x + dw, y + dh, 1, 1},
        {x,     y + dh, 0, 1},
    }
    gl.BufferSubData(gl.ARRAY_BUFFER, 0, size_of(verts), &verts)
    
    proj := ortho_matrix(0, cfg.design_width, cfg.design_height, 0)
    gl.UniformMatrix4fv(b.u_proj, 1, false, &proj[0, 0])
    gl.Uniform1i(b.u_tex, 0)
    gl.Uniform2f(b.u_texel, 1.0/f32(b.width), 1.0/f32(b.height))
    gl.Uniform1fv(b.u_weights, BLUR_TAPS, &b.weights[0])
    
    src_tex := b.tex_a
    for _ in 0..<iters {
        // Horizontal
        gl.BindFramebuffer(gl.FRAMEBUFFER, b.fbo_b)
        gl.Viewport(0, 0, b.width, b.height)
        gl.Clear(gl.COLOR_BUFFER_BIT)
        
        gl.ActiveTexture(gl.TEXTURE0)
        gl.BindTexture(gl.TEXTURE_2D, src_tex)
        gl.Uniform2f(b.u_dir, 1, 0)
        gl.DrawArrays(gl.TRIANGLES, 0, 6)
        
        // Vertical
        gl.BindFramebuffer(gl.FRAMEBUFFER, b.fbo_a)
        gl.Clear(gl.COLOR_BUFFER_BIT)
        
        gl.BindTexture(gl.TEXTURE_2D, b.tex_b)
        gl.Uniform2f(b.u_dir, 0, 1)
        gl.DrawArrays(gl.TRIANGLES, 0, 6)
        
        src_tex = b.tex_a
    }
    
    gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
    gl.Viewport(0, 0, w.width, w.height)
    gl.UseProgram(r.shader)
    proj = ortho_matrix(0, cfg.design_width, cfg.design_height, 0)
    gl.UniformMatrix4fv(r.u_proj, 1, false, &proj[0, 0])
    gl.Enable(gl.BLEND)
}

bg_blur_create_target :: proc(w, h: i32) -> (tex: u32, fbo: u32) {
    gl.GenTextures(1, &tex)
    gl.BindTexture(gl.TEXTURE_2D, tex)
    gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA8, w, h, 0, gl.RGBA, gl.UNSIGNED_BYTE, nil)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
    
    gl.GenFramebuffers(1, &fbo)
    gl.BindFramebuffer(gl.FRAMEBUFFER, fbo)
    gl.FramebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, tex, 0)
    
    status := gl.CheckFramebufferStatus(gl.FRAMEBUFFER)
    if status != gl.FRAMEBUFFER_COMPLETE {
        fmt.eprintln("Blur framebuffer incomplete.")
        gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
        return 0, 0
    }
    gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
    return tex, fbo
}

bg_blur_quality_scale :: proc(quality: string) -> f32 {
    switch quality {
    case "high":   return 1.0
    case "medium": return 0.5
    case "low":    return 0.5
    }
    return 1.0
}

bg_blur_quality_iters :: proc(quality: string) -> int {
    switch quality {
    case "high":   return 2
    case "medium": return 2
    case "low":    return 1
    }
    return 2
}
