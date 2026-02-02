package vnefall

import "core:fmt"
import "core:strings"
import "core:c"
import gl "vendor:OpenGL"
import stbi "vendor:stb/image"

// cache to avoid reloading same image twice
@(private)
cache: map[string]u32

texture_load :: proc(path: string) -> u32 {
    if tex, ok := cache[path]; ok do return tex
    
    w, h, chans: c.int
    cp := strings.clone_to_cstring(path)
    defer delete(cp)
    
    // Force 4 channels (RGBA)
    data := stbi.load(cp, &w, &h, &chans, 4)
    if data == nil {
        fmt.eprintln("Image failed to load:", path)
        return 0
    }
    defer stbi.image_free(data)
    
    tex: u32
    gl.GenTextures(1, &tex)
    gl.BindTexture(gl.TEXTURE_2D, tex)
    
    // PixelStorei is important for non-power-of-two widths
    gl.PixelStorei(gl.UNPACK_ALIGNMENT, 1)
    
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
    
    gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, w, h, 0, gl.RGBA, gl.UNSIGNED_BYTE, data)
    
    cache[path] = tex
    return tex
}

texture_cleanup :: proc() {
    for _, &tex in cache {
        gl.DeleteTextures(1, &tex)
    }
    delete(cache)
}
