package vnefall

import "core:fmt"
import "core:os"
import "core:strings"
import "core:strconv"

Command_Type :: enum {
    None,
    Bg,
    Say,
    Wait,
    End,
    Music,
    Title,
    Label,
    Jump,
    JumpFile,   // jump_file "chapter_2.vnef" (load new script)
    Choice,
    ChoiceAdd,
    ChoiceShow,
    Set,
    If,
    Else,
    BlockStart, // For {
    BlockEnd,   // For }
    Scene,      // scene "chapter_1"
    SceneNext,  // scene_next "chapter_2" (prefetch)
}

Command :: struct {
    type: Command_Type,
    who:  string, // arg1: image path or character name
    what: string, // arg2: dialogue text
    args: [dynamic]string, // arg3+: for multi-param commands like 'choice'
    jump: int,    // Jump index for blocks (IF false, or BlockEnd skip ELSE)
    indented: bool, // True if the line had leading whitespace
}

Script :: struct {
    commands:  [dynamic]Command,
    labels:    map[string]int,
    variables: map[string]int, // 0/1 for bools, any value for ints
    ip:        int,
    waiting:   bool,
}

script_load :: proc(s: ^Script, path: string) -> bool {
    // Clear any existing data first (for reload case)
    clear(&s.labels)
    clear(&s.variables)
    clear(&s.commands)
    
    // Initialize maps if they don't exist yet
    if s.labels == nil {
        s.labels = make(map[string]int)
    }
    if s.variables == nil {
        s.variables = make(map[string]int)
    }
    
    s.ip = 0
    s.waiting = false
    
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
        trimmed := strings.trim_space(line)
        if len(trimmed) == 0 || trimmed[0] == '#' do continue
        
        is_indented := len(line) > 0 && (line[0] == ' ' || line[0] == '\t')
        
        // Revised approach: Just check specific combo tokens first (no allocation)
        if strings.contains(trimmed, "} else {") {
            append(&s.commands, Command{type = .BlockEnd, indented = is_indented})
            append(&s.commands, Command{type = .Else, indented = is_indented})
            append(&s.commands, Command{type = .BlockStart, indented = is_indented})
            continue
        }
        if strings.contains(trimmed, "} else") {
            append(&s.commands, Command{type = .BlockEnd, indented = is_indented})
            append(&s.commands, Command{type = .Else, indented = is_indented})
            continue
        }
        
        // Handle trailing { on commands like if/else
        has_trailing_brace := strings.has_suffix(trimmed, "{") && trimmed != "{" && !strings.has_prefix(trimmed, "say ")
        
        cmd := parse_line(trimmed)
        if cmd.type != .None {
            cmd.indented = is_indented
            append(&s.commands, cmd)
            if has_trailing_brace {
                append(&s.commands, Command{type = .BlockStart, indented = is_indented})
            }
        }
    }
    
    // Pre-scan for labels so we can jump instantly
    for cmd, i in s.commands {
        if cmd.type == .Label {
            s.labels[cmd.who] = i
        }
    }
    
    // Pass 2: Resolve blocks and if/else jumps
    block_stack := make([dynamic]int)
    defer delete(block_stack)
    
    for i := 0; i < len(s.commands); i += 1 {
        cmd := &s.commands[i]
        
        // Indentation check: commands inside blocks or after labels should be indented
        in_block := len(block_stack) > 0
        is_structural := cmd.type == .Label || cmd.type == .BlockStart || cmd.type == .BlockEnd || cmd.type == .Else
        
        if in_block && !is_structural && !cmd.indented {
            fmt.printf("[script] Warning: Missing indentation inside block at instruction %d\n", i)
        }
        
        // After-label check
        if i > 0 && s.commands[i-1].type == .Label && !cmd.indented && !is_structural {
             fmt.printf("[script] Warning: Missing indentation after label '%s' at instruction %d\n", s.commands[i-1].who, i)
        }

        #partial switch cmd.type {
        case .BlockStart:
            append(&block_stack, i)
        
        case .BlockEnd:
            if len(block_stack) == 0 {
                fmt.eprintln("Error: Unmatched } at instruction", i)
                continue
            }
            start_idx := pop(&block_stack)
            start_cmd := &s.commands[start_idx]
            
            // Link the parent (IF or ELSE) to the end of its block
            parent_idx := start_idx - 1
            if parent_idx >= 0 {
                parent := &s.commands[parent_idx]
                if parent.type == .If || parent.type == .Else {
                    parent.jump = i + 1
                }
                
                // If we just finished an ELSE block, we need to check if the 
                // preceding IF block's end needs to be patched to jump HERE.
                if parent.type == .Else {
                    // Search for the preceding IF's block end
                    // (It would have been pushed if an else followed it)
                    if len(block_stack) > 0 {
                        potential_if_end_idx := block_stack[len(block_stack)-1]
                        if s.commands[potential_if_end_idx].type == .BlockEnd {
                            if_end_idx := pop(&block_stack)
                            s.commands[if_end_idx].jump = i + 1
                        }
                    }
                }
            }
            
            // If an ELSE follows this block, we need to skip it if the IF was true.
            // Push this BlockEnd so the ELSE's BlockEnd can patch its jump.
            if i + 1 < len(s.commands) && s.commands[i+1].type == .Else {
                append(&block_stack, i) 
            }
        }
    }
    
    fmt.printf("[script] Parsed %d commands (%d labels) from %s\n", len(s.commands), len(s.labels), path)
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
    
    // label <name> or label <name>:
    if strings.has_prefix(line, "label ") {
        cmd.type = .Label
        rest := strings.trim_space(line[6:])
        if strings.has_suffix(rest, ":") {
            rest = rest[:len(rest)-1]
        }
        cmd.who = strings.clone(strings.trim_space(rest))
        return
    }
    
    // jump <label>
    if strings.has_prefix(line, "jump ") && !strings.has_prefix(line, "jump_file") {
        cmd.type = .Jump
        cmd.who  = strings.clone(strings.trim_space(line[5:]))
        return
    }
    
    // jump_file "chapter_2.vnef" - load a different script file
    if strings.has_prefix(line, "jump_file ") {
        cmd.type = .JumpFile
        rest := strings.trim_space(line[10:])
        cmd.who = strings.clone(strings.trim(rest, "\""))
        return
    }

    // choice_add "Text" label
    if strings.has_prefix(line, "choice_add ") {
        cmd.type = .ChoiceAdd
        rest := strings.trim_space(line[11:])
        // Split text and label
        q1 := strings.index(rest, "\"")
        if q1 != -1 {
            q2 := strings.index(rest[q1+1:], "\"")
            if q2 != -1 {
                cmd.who = strings.clone(rest[q1+1 : q1+1+q2])
                cmd.what = strings.clone(strings.trim_space(rest[q1+1+q2+1:]))
            }
        }
        return
    }

    if line == "choice_show" do return Command{type = .ChoiceShow}

    // set money = 100  OR  set flag true
    if strings.has_prefix(line, "set ") {
        cmd.type = .Set
        rest := strings.trim_space(line[4:])
        if idx := strings.index(rest, "="); idx != -1 {
            cmd.who  = strings.clone(strings.trim_space(rest[:idx]))
            cmd.what = strings.clone(strings.trim_space(rest[idx+1:]))
        } else {
            parts := strings.split(rest, " ")
            if len(parts) >= 2 {
                cmd.who  = strings.clone(parts[0])
                cmd.what = strings.clone(parts[1])
            }
        }
        return
    }

    // if (expr) {
    if strings.has_prefix(line, "if ") {
        cmd.type = .If
        rest := strings.trim_space(line[3:])
        
        // Strip trailing {
        if strings.has_suffix(rest, "{") {
            rest = strings.trim_space(rest[:len(rest)-1])
        }

        // Handle JS-style if (expr)
        if strings.has_prefix(rest, "(") {
            end := strings.last_index(rest, ")")
            if end != -1 {
                cmd.who = strings.clone(rest[1:end]) // The expression
            }
        } else {
            // Legacy: if <flag> jump <label>
            parts := strings.split(rest, " ")
            if len(parts) >= 3 && parts[1] == "jump" {
                cmd.who  = strings.clone(parts[0])
                cmd.what = strings.clone(parts[2])
            }
        }
        return
    }

    if line == "else" || line == "else {" do return Command{type = .Else}
    if line == "{"    do return Command{type = .BlockStart}
    if line == "}"    do return Command{type = .BlockEnd}
    
    // scene "chapter_1" - bind to a manifest
    if strings.has_prefix(line, "scene ") && !strings.has_prefix(line, "scene_next") {
        cmd.type = .Scene
        rest := strings.trim_space(line[6:])
        cmd.who = strings.clone(strings.trim(rest, "\""))
        return
    }
    
    // scene_next "chapter_2" - prefetch next scene
    if strings.has_prefix(line, "scene_next ") {
        cmd.type = .SceneNext
        rest := strings.trim_space(line[11:])
        cmd.who = strings.clone(strings.trim(rest, "\""))
        return
    }
    
    if line == "wait" do return Command{type = .Wait}
    if line == "end"  do return Command{type = .End}
    
    fmt.eprintln("Unrecognized command:", line)
    return
}

script_cleanup :: proc(s: ^Script) {
    for cmd in s.commands {
        if cmd.who != "" do delete(cmd.who)
        if cmd.what != "" do delete(cmd.what)
        for arg in cmd.args {
            delete(arg)
        }
        delete(cmd.args)
    }
    clear(&s.commands)  // Clear but keep the dynamic array
    clear(&s.labels)    // Clear but keep the map
    // Keep variables across file jumps for persistent state
}

// Final cleanup that frees all memory (call on game exit)
script_destroy :: proc(s: ^Script) {
    script_cleanup(s)
    delete(s.commands)
    delete(s.labels)
    delete(s.variables)
}

script_execute :: proc(s: ^Script, state: ^Game_State) {
    if s.ip >= len(s.commands) {
        state.running = false
        return
    }
    
    c := s.commands[s.ip]
    
    #partial switch c.type {
    case .Bg:
        tex := scene_get_texture(c.who)
        if tex != 0 do state.current_bg = tex
        s.ip += 1
        
    case .Music:
        path := strings.concatenate({cfg.path_music, c.who})
        defer delete(path)
        audio_play_music(&state.audio, path)
        s.ip += 1
        
    case .Title:
        window_set_title(&state.window, c.who)
        s.ip += 1
        
    case .Label:
        // Labels do nothing at runtime, skip them
        s.ip += 1
        
    case .Jump:
        if target, ok := s.labels[c.who]; ok {
            fmt.printf("[script] Jump to label: %s (IP: %d)\n", c.who, target)
            s.ip = target
        } else {
            fmt.eprintln("Error: Jump to non-existent label:", c.who)
            s.ip += 1
        }
    
    case .JumpFile:
        // Load a completely new script file
        // Clone the path BEFORE cleanup since c.who will be freed
        target_file := strings.clone(c.who)
        path := strings.concatenate({cfg.path_scripts, target_file})
        delete(target_file)
        fmt.printf("[script] Jumping to file: %s\n", path)
        
        // Cleanup old script
        script_cleanup(s)
        
        // Handle Scene transition
        if g_scenes.next != nil && g_scenes.next.name == path {
            scene_switch()
        } else {
            // No prefetch or wrong prefetch, sync load
            scene_system_cleanup() // Clear anything currently loaded
            g_scenes.current = scene_load_sync(path)
            state.current_bg = 0
        }
        
        // Load new script
        if !script_load(s, path) {
            fmt.eprintln("Error: Failed to load script file:", path)
            delete(path)
            state.running = false
            return
        }
        delete(path)
        
        // Reset state for new script
        state.textbox.visible = false
        s.waiting = false
        // IP is already 0 from script_load

    case .Choice:
        if len(c.args) < 2 {
            fmt.eprintln("Error: choice command needs at least 2 arguments (text, label).")
            s.ip += 1
            return
        }
        
        fmt.printf("[script] Choice menu activated with %d options\n", len(c.args)/2)
        state.choice.active = true
        state.choice.selected = 0
        choice_clear(state)
        
        for i := 0; i < len(c.args); i += 2 {
            if i + 1 >= len(c.args) {
                break
            }
            append(&state.choice.options, Choice_Option{
                text  = c.args[i],
                label = c.args[i+1],
            })
        }
        s.waiting = true
        
    case .ChoiceAdd:
        text := interpolate_text(s, c.who)
        defer delete(text)
        
        fmt.printf("[script] Adding dynamic choice: %s -> %s\n", text, c.what)
        append(&state.choice.options, Choice_Option{
            text  = strings.clone(text),
            label = strings.clone(c.what),
        })
        s.ip += 1

    case .ChoiceShow:
        if len(state.choice.options) == 0 {
            fmt.eprintln("Warning: choice_show called with 0 options.")
            s.ip += 1
            return
        }
        fmt.printf("[script] Showing dynamic choice menu with %d options\n", len(state.choice.options))
        state.choice.active = true
        state.choice.selected = 0
        s.waiting = true

    case .Set:
        val := 0
        if c.what == "true"  do val = 1
        else if c.what == "false" do val = 0
        else {
            // Check if it's a number
            v, ok := strconv.parse_int(c.what)
            if ok do val = v
            else {
                // Check if it's another variable
                if other, exists := s.variables[c.what]; exists {
                    val = other
                }
            }
        }
        fmt.printf("[script] Set variable: %s = %d\n", c.who, val)
        s.variables[c.who] = val
        s.ip += 1

    case .If:
        // Evaluate the expression in c.who
        result := evaluate_expression(s, c.who)
        
        if result {
            fmt.printf("[script] If (%s) is TRUE\n", c.who)
            // If it's a legacy jump, jump now
            if c.what != "" {
                if target, ok := s.labels[c.what]; ok {
                    s.ip = target
                } else {
                    fmt.eprintln("Error: if-jump to non-existent label:", c.what)
                    s.ip += 1
                }
            } else {
                // JS-style: proceed into the block
                s.ip += 1
            }
        } else {
            fmt.printf("[script] If (%s) is FALSE\n", c.who)
            // Skip to the jump target (Else or after BlockEnd)
            if c.jump > 0 {
                s.ip = c.jump
            } else {
                s.ip += 1 
            }
        }

    case .Else:
        // If we hit an ELSE naturally, it means the IF was TRUE and we finished its block.
        // We shouldn't even reach the ELSE command because the BlockEnd should have jumped past it.
        // But if we do (e.g. no BlockEnd jump or just logic falling through), we skip into it.
        s.ip += 1

    case .BlockStart:
        s.ip += 1

    case .BlockEnd:
        // If this BlockEnd has a jump, it's because it needs to skip an ELSE block
        if c.jump > 0 {
            fmt.printf("[script] BlockEnd skipping to: %d\n", c.jump)
            s.ip = c.jump
        } else {
            s.ip += 1
        }

    case .Say:
        state.textbox.visible = true
        state.textbox.speaker = c.who
        
        // Handle interpolation
        text := interpolate_text(s, c.what)
        fmt.printf("[script] Say %s: %s\n", c.who, text)
        delete(state.textbox.text)
        state.textbox.text = text 
        s.waiting = true
        
    case .Wait:
        s.waiting = true
    
    case .Scene:
        // Load or switch to a scene
        script_path := strings.concatenate({cfg.path_scripts, c.who, ".vnef"})
        defer delete(script_path)
        scene := scene_load_sync(script_path)
        if g_scenes.current != nil {
            scene_cleanup(g_scenes.current)
        }
        g_scenes.current = scene
        fmt.println("[script] Activated scene:", c.who)
        s.ip += 1
    
    case .SceneNext:
        // Prefetch next scene in background
        script_path := strings.concatenate({cfg.path_scripts, c.who, ".vnef"})
        defer delete(script_path)
        scene_prefetch(script_path)
        s.ip += 1
        
    case .End:
        state.running = false
    }
}

choice_clear :: proc(state: ^Game_State) {
    for opt in state.choice.options {
        delete(opt.text)
        delete(opt.label)
    }
    clear(&state.choice.options)
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

evaluate_expression :: proc(s: ^Script, expr: string) -> bool {
    trimmed := strings.trim_space(expr)
    
    // Simple boolean check
    if val, ok := s.variables[trimmed]; ok {
        return val != 0
    }
    
    // Check for comparisons: ==, !=, >, <, >=, <=
    ops := []string{">=", "<=", "==", "!=", ">", "<"}
    for op in ops {
        if idx := strings.index(trimmed, op); idx != -1 {
            lhs_s := strings.trim_space(trimmed[:idx])
            rhs_s := strings.trim_space(trimmed[idx + len(op):])
            
            lhs := 0
            rhs := 0
            
            // Resolve LHS
            if v, ok := s.variables[lhs_s]; ok do lhs = v
            else {
                v, _ := strconv.parse_int(lhs_s)
                lhs = v
            }
            
            // Resolve RHS
            if v, ok := s.variables[rhs_s]; ok do rhs = v
            else {
                v, _ := strconv.parse_int(rhs_s)
                rhs = v
            }
            
            switch op {
            case "==": return lhs == rhs
            case "!=": return lhs != rhs
            case ">":  return lhs > rhs
            case "<":  return lhs < rhs
            case ">=": return lhs >= rhs
            case "<=": return lhs <= rhs
            }
        }
    }
    
    // Fallback to literal number
    v, _ := strconv.parse_int(trimmed)
    return v != 0
}

interpolate_text :: proc(s: ^Script, input: string) -> string {
    sb := strings.builder_make()
    
    i := 0
    for i < len(input) {
        if i + 1 < len(input) && input[i] == '$' && input[i+1] == '{' {
            end := strings.index(input[i:], "}")
            if end != -1 {
                var_name := input[i+2 : i+end]
                if val, ok := s.variables[var_name]; ok {
                    fmt.sbprintf(&sb, "%d", val)
                } else {
                    strings.write_string(&sb, input[i : i+end+1])
                }
                i += end + 1
                continue
            }
        }
        strings.write_byte(&sb, input[i])
        i += 1
    }
    
    return strings.to_string(sb)
}
