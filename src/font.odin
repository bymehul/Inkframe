package inkframe

import "core:fmt"
import "core:os"
import "core:strings"
import gl "vendor:OpenGL"
import stbtt "vendor:stb/truetype"

FONT_SIZE       :: 32
FONT_ATLAS_SIZE :: 512
FONT_FIRST_CHAR :: 32
FONT_NUM_CHARS  :: 96

Font :: struct {
    texture:   u32,
    char_data: [FONT_NUM_CHARS]stbtt.bakedchar,
    loaded:    bool,
}

g_font: Font

font_load :: proc(path: string) -> bool {
    data, ok := os.read_entire_file(path)
    if !ok {
        fmt.eprintln("Truetype file not found:", path)
        return false
    }
    defer delete(data)
    
    pixels := make([]u8, FONT_ATLAS_SIZE * FONT_ATLAS_SIZE)
    defer delete(pixels)
    
    bake_res := stbtt.BakeFontBitmap(
        raw_data(data), 0, FONT_SIZE,
        raw_data(pixels), FONT_ATLAS_SIZE, FONT_ATLAS_SIZE,
        FONT_FIRST_CHAR, FONT_NUM_CHARS,
        &g_font.char_data[0],
    )
    
    if bake_res <= 0 {
        fmt.eprintln("Font baking failed.")
        return false
    }
    
    gl.GenTextures(1, &g_font.texture)
    gl.BindTexture(gl.TEXTURE_2D, g_font.texture)
    gl.PixelStorei(gl.UNPACK_ALIGNMENT, 1)
    
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
    
    gl.TexImage2D(
        gl.TEXTURE_2D, 0, gl.RED,
        FONT_ATLAS_SIZE, FONT_ATLAS_SIZE, 0,
        gl.RED, gl.UNSIGNED_BYTE, raw_data(pixels),
    )
    
    g_font.loaded = true
    return true
}

font_get_glyph :: proc(char: u8, x, y: ^f32) -> (quad: stbtt.aligned_quad) {
    if char < FONT_FIRST_CHAR || char >= FONT_FIRST_CHAR + FONT_NUM_CHARS do return
    stbtt.GetBakedQuad(&g_font.char_data[0], FONT_ATLAS_SIZE, FONT_ATLAS_SIZE, i32(char - FONT_FIRST_CHAR), x, y, &quad, true)
    return
}

font_text_width :: proc(text: string) -> (w: f32) {
    x, y: f32
    for char in text {
        if char >= FONT_FIRST_CHAR && char < FONT_FIRST_CHAR + FONT_NUM_CHARS {
            font_get_glyph(u8(char), &x, &y)
        }
    }
    return x
}

font_wrap_text :: proc(text: string, max_width: f32) -> []string {
    lines: [dynamic]string
    words := strings.split(text, " ")
    defer delete(words)
    
    b: strings.Builder
    strings.builder_init(&b)
    defer strings.builder_destroy(&b)
    
    for word in words {
        current := strings.to_string(b)
        spacer := len(current) > 0 ? " " : ""
        test_line := strings.concatenate({current, spacer, word})
        defer delete(test_line)
        
        if font_text_width(test_line) > max_width && len(current) > 0 {
            append(&lines, strings.clone(current))
            strings.builder_reset(&b)
            strings.write_string(&b, word)
        } else {
            if len(current) > 0 do strings.write_string(&b, " ")
            strings.write_string(&b, word)
        }
    }
    
    last := strings.to_string(b)
    if len(last) > 0 do append(&lines, strings.clone(last))
    
    return lines[:]
}

font_cleanup :: proc() {
    if g_font.loaded {
        gl.DeleteTextures(1, &g_font.texture)
        g_font.loaded = false
    }
}
