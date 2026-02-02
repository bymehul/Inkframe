/*
    Inkframe — A simple VN engine.
    
    This is the main entry point where we glue everything together. 
    It handles the lifecycle: init, the loop, and cleaning up.
*/

package vnefall

import "core:fmt"
import "core:os"
import "core:strings"

VERSION :: "1.0.0"

// State of the whole game world
Game_State :: struct {
    running:      bool,
    window:       Window,
    renderer:     Renderer,
    audio:        Audio_State,
    script:       Script,
    input:        Input_State,
    
    current_bg:   u32,           // OpenGL texture handle
    textbox:      Textbox_State,
}

Textbox_State :: struct {
    visible:      bool,
    speaker:      string,
    text:         string,
}

// Global state to keep things simple for v1
g: Game_State

main :: proc() {
    // Check if we passed a script path, otherwise fallback to demo
    args := os.args
    script_path := "assets/scripts/demo.vnef"
    
    if len(args) >= 2 {
        script_path = args[1]
    } else {
        fmt.println("[inkframe] using default script:", script_path)
    }
    
    // Kick things off
    if !init_game(script_path) {
        fmt.eprintln("Failed to start engine.")
        os.exit(1)
    }
    defer cleanup_game()
    
    // Game loop
    for g.running {
        input_poll(&g.input, &g.running)
        
        if g.input.advance_pressed {
            script_advance(&g.script, &g)
        }
        
        // IP stays here until the user clicks to advance
        if !g.script.waiting && g.script.ip < len(g.script.commands) {
            script_execute(&g.script, &g)
        }
        
        renderer_begin(&g.renderer, &g.window)
        
        if g.current_bg != 0 {
            renderer_draw_fullscreen(&g.renderer, g.current_bg)
        }
        
        if g.textbox.visible {
            renderer_draw_textbox(&g.renderer, g.textbox.speaker, g.textbox.text)
        }
        
        renderer_end(&g.renderer, &g.window)
    }
    
    fmt.println("Cleaning up and exiting.")
}

init_game :: proc(script_path: string) -> bool {
    fmt.printf("[vnefall] Starting up v%s...\n", VERSION)
    
    // Need a window first
    if !window_create(&g.window, "Vnefall", 1280, 720) do return false
    
    // Setup GL state
    if !renderer_init(&g.renderer) do return false
    
    // Audio is optional, don't crash if it fails
    if !audio_init(&g.audio) {
        fmt.eprintln("Warning: Audio init failed.")
    }
    
    // Try to get our default font
    if !font_load("assets/fonts/default.ttf") {
        fmt.eprintln("Warning: Could not load default font.")
    }
    
    // Finally, load the script file
    if !script_load(&g.script, script_path) {
        fmt.eprintln("Error: Failed to load script:", script_path)
        return false
    }
    
    g.running = true
    return true
}

cleanup_game :: proc() {
    audio_cleanup(&g.audio)
    renderer_cleanup(&g.renderer)
    window_destroy(&g.window)
}
