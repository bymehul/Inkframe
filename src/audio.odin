package inkframe

import "core:fmt"
import "core:strings"
import "vendor:sdl2"
import mix "vendor:sdl2/mixer"

Audio_State :: struct {
    inited: bool,
    music:  ^mix.Music,
}

audio_init :: proc(a: ^Audio_State) -> bool {
    // We want MP3 and OGG support for v1
    if i32(mix.Init({.MP3, .OGG})) == 0 {
        fmt.eprintln("mixer flags failed to init, but we'll try to continue.")
    }

    if mix.OpenAudio(44100, mix.DEFAULT_FORMAT, 2, 2048) < 0 {
        fmt.eprintln("Audio device failed:", sdl2.GetError())
        return false
    }
    
    a.inited = true
    return true
}

audio_cleanup :: proc(a: ^Audio_State) {
    if a.music != nil {
        mix.FreeMusic(a.music)
        a.music = nil
    }
    
    if a.inited {
        mix.CloseAudio()
        mix.Quit()
        a.inited = false
    }
}

audio_play_music :: proc(a: ^Audio_State, path: string) {
    if !a.inited do return
    
    if a.music != nil {
        mix.FreeMusic(a.music)
        a.music = nil
    }
    
    cpath := strings.clone_to_cstring(path)
    defer delete(cpath)
    
    a.music = mix.LoadMUS(cpath)
    if a.music == nil {
        fmt.eprintln("Couldn't load music:", path, sdl2.GetError())
        return
    }
    
    mix.PlayMusic(a.music, -1) // -1 for infinite loop
}

audio_stop_music :: proc(a: ^Audio_State) {
    mix.HaltMusic()
}
