package inkframe

import "vendor:sdl2"
import gl "vendor:OpenGL"
import "core:fmt"
import "core:strings"

Window :: struct {
    handle:     ^sdl2.Window,
    gl_context: sdl2.GLContext,
    width, height: i32,
}

window_create :: proc(w: ^Window, title: cstring, width, height: i32) -> bool {
    if sdl2.Init(sdl2.INIT_VIDEO | sdl2.INIT_AUDIO) != 0 {
        fmt.eprintln("SDL2 init failed:", sdl2.GetError())
        return false
    }
    
    // We want a modern-ish GL context
    sdl2.GL_SetAttribute(.CONTEXT_MAJOR_VERSION, 3)
    sdl2.GL_SetAttribute(.CONTEXT_MINOR_VERSION, 3)
    sdl2.GL_SetAttribute(.CONTEXT_PROFILE_MASK, cast(i32)sdl2.GLprofile.CORE)
    
    w.handle = sdl2.CreateWindow(
        title,
        sdl2.WINDOWPOS_CENTERED, sdl2.WINDOWPOS_CENTERED,
        width, height,
        sdl2.WINDOW_OPENGL | sdl2.WINDOW_SHOWN,
    )
    
    if w.handle == nil {
        fmt.eprintln("Coulnd't create window:", sdl2.GetError())
        return false
    }
    
    w.gl_context = sdl2.GL_CreateContext(w.handle)
    if w.gl_context == nil {
        fmt.eprintln("GL context creation failed:", sdl2.GetError())
        return false
    }
    
    // Odin's GL loader expects a callback with a specific signature.
    // We wrap GetProcAddress to match what it wants.
    gl.load_up_to(3, 3, proc(p: rawptr, name: cstring) {
        ptr := sdl2.GL_GetProcAddress(name)
        (cast(^rawptr)p)^ = ptr
    })
    
    sdl2.GL_SetSwapInterval(1) // VSync is usually better for visual novels
    
    w.width = width
    w.height = height
    
    return true
}

window_destroy :: proc(w: ^Window) {
    if w.gl_context != nil do sdl2.GL_DeleteContext(w.gl_context)
    if w.handle != nil do sdl2.DestroyWindow(w.handle)
    sdl2.Quit()
}

window_swap :: proc(w: ^Window) {
    sdl2.GL_SwapWindow(w.handle)
}

window_set_title :: proc(w: ^Window, title: string) {
    c_title := strings.clone_to_cstring(title)
    defer delete(c_title)
    sdl2.SetWindowTitle(w.handle, c_title)
}
