package inkframe

import "core:fmt"
import "core:os"
import "core:strings"

Command_Type :: enum {
    None,
    Bg,
    Say,
    Wait,
    End,
    Music,
    Title,
}

Command :: struct {
    type: Command_Type,
    who:  string, // arg1: image path or character name
    what: string, // arg2: dialogue text
}

Script :: struct {
    commands: [dynamic]Command,
    ip:       int,
    waiting:  bool,
}

script_load :: proc(s: ^Script, path: string) -> bool {
    data, ok := os.read_entire_file(path)
    if !ok {
        fmt.eprintln("Could not read script:", path)
        return false
    }
    defer delete(data)
    
    content := string(data)
    lines := strings.split_lines(content)
    defer delete(lines)
    
    for line in lines {
        line := strings.trim_space(line)
        if len(line) == 0 || line[0] == '#' do continue
        
        cmd := parse_line(line)
        if cmd.type != .None do append(&s.commands, cmd)
    }
    
    fmt.printf("[script] Parsed %d commands from %s\n", len(s.commands), path)
    return len(s.commands) > 0
}

parse_line :: proc(line: string) -> (cmd: Command) {
    // bg / images
    if strings.has_prefix(line, "bg ") {
        cmd.type = .Bg
        cmd.who  = strings.clone(strings.trim_space(line[3:]))
        return
    }
    
    // dialogue: say Alice "Hello"
    if strings.has_prefix(line, "say ") {
        rest := line[4:]
        
        // Find quotes for the text
        q1 := strings.index(rest, "\"")
        if q1 < 0 {
            fmt.eprintln("Missing quotes in say:", line)
            return
        }
        
        cmd.type = .Say
        cmd.who  = strings.clone(strings.trim_space(rest[:q1]))
        
        q2_part := rest[q1+1:]
        q2 := strings.index(q2_part, "\"")
        if q2 < 0 {
            cmd.what = strings.clone(q2_part)
        } else {
            cmd.what = strings.clone(q2_part[:q2])
        }
        return
    }
    
    // Audio / Music
    if strings.has_prefix(line, "music ") || strings.has_prefix(line, "play ") {
        off := strings.has_prefix(line, "music ") ? 6 : 5
        cmd.type = .Music
        cmd.who  = strings.clone(strings.trim_space(line[off:]))
        return
    }
    
    // title "My Story"
    if strings.has_prefix(line, "title ") {
        cmd.type = .Title
        rest := strings.trim_space(line[6:])
        // Strip quotes if present
        if len(rest) >= 2 && rest[0] == '"' && rest[len(rest)-1] == '"' {
            cmd.who = strings.clone(rest[1:len(rest)-1])
        } else {
            cmd.who = strings.clone(rest)
        }
        return
    }
    
    if line == "wait" do return Command{type = .Wait}
    if line == "end"  do return Command{type = .End}
    
    fmt.eprintln("Unrecognized command:", line)
    return
}

script_execute :: proc(s: ^Script, state: ^Game_State) {
    if s.ip >= len(s.commands) {
        state.running = false
        return
    }
    
    c := s.commands[s.ip]
    
    #partial switch c.type {
    case .Bg:
        path := strings.concatenate({"assets/images/", c.who})
        defer delete(path)
        
        tex := texture_load(path)
        if tex != 0 do state.current_bg = tex
        s.ip += 1
        
    case .Music:
        path := strings.concatenate({"assets/music/", c.who})
        defer delete(path)
        audio_play_music(&state.audio, path)
        s.ip += 1
        
    case .Title:
        window_set_title(&state.window, c.who)
        s.ip += 1
        
    case .Say:
        state.textbox.visible = true
        state.textbox.speaker = c.who
        state.textbox.text    = c.what
        s.waiting = true
        
    case .Wait:
        s.waiting = true
        
    case .End:
        state.running = false
    }
}

script_advance :: proc(s: ^Script, state: ^Game_State) {
    if !s.waiting do return
    
    s.waiting = false
    s.ip += 1
    
    // If next command isn't a say, hide the box
    if s.ip >= len(s.commands) || s.commands[s.ip].type != .Say {
        state.textbox.visible = false
    }
}
