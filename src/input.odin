package inkframe

import "vendor:sdl2"

Input_State :: struct {
    advance_pressed: bool,
}

input_poll :: proc(input: ^Input_State, running: ^bool) {
    input.advance_pressed = false
    
    ev: sdl2.Event
    for sdl2.PollEvent(&ev) {
        #partial switch ev.type {
        case .QUIT:
            running^ = false
            
        case .KEYDOWN:
            #partial switch ev.key.keysym.sym {
            case .SPACE, .RETURN:
                input.advance_pressed = true
            case .ESCAPE:
                running^ = false
            }
            
        case .MOUSEBUTTONDOWN:
            if ev.button.button == sdl2.BUTTON_LEFT {
                input.advance_pressed = true
            }
        }
    }
}
