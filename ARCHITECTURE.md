# Vnefall Architecture

This document explains how the engine is put together, so you don't have to guess when you want to add new features.

## Core Flow
Vnefall uses a simple "State" pattern. Everything is held in a global `g` (Game_State) in `main.odin`.

1. **Init**: Set up SDL, OpenGL, Audio, and Load the script.
2. **Poll**: Check for clicks or keypresses.
3. **Update**: Advance the script instruction pointer (IP) if the user clicked.
4. **Draw**: Clear the screen, draw the current background, then draw the text box on top.

## Adding a New Script Command
If you want to add a command like `shake_screen` or `show_character`:

1. **`src/script.odin`**: 
   - Add the new command to the `Command_Type` enum.
   - Update `parse_line` to recognize the command in a text file.
   - Update `script_execute` to handle what the command actually does (e.g., setting a flag).

2. **`src/main.odin`**:
   - If the command needs to change something on screen (like a shake), add a field to `Game_State`.
   - Update the drawing logic in the main loop to react to that state.

## Systems
- **Renderer (`renderer.odin`)**: Uses a single shader and a single buffer. We draw everything as textured quads (2 triangles, 6 vertices).
- **Text (`font.odin`)**: Uses `stb_truetype` to bake a font into a single atlas texture.
- **Audio (`audio.odin`)**: A thin wrapper around `SDL_mixer`.

## Folder Structure
- `src/`: All Odin source code.
- `assets/images/`: Put your `.png` or `.jpg` backgrounds here.
- `assets/music/`: Put your `.mp3` or `.ogg` tracks here.
- `assets/scripts/`: This is where the `.vnef` story files live.

## Maintenance & Debugging

- **Logging**: Use `fmt.printf` sparingly for debug logs. For v1, we keep things quiet unless there's an error (`fmt.eprintln`).
- **Memory**: Most assets are loaded into caches (see `texture.odin`). If you add new asset types, ensure you add them to the `cleanup_game` proc in `main.odin`.
- **Coordinate System**: We use top-left (0,0). If the screen looks flipped, check `ortho_matrix` in `renderer.odin`.

## Known Constraints
- **VBO Size**: The current VBO is sized for a single quad (6 vertices). If you plan to draw many sprites at once, you'll need to update `renderer_init` to handle a larger buffer or implement batching.
- **Script Buffer**: We read the entire `.vnef` file into memory. For massive stories, we might eventually need a streaming parser.

## Troubleshooting
- **No Sound**: Ensure `SDL2_mixer` is installed and the file path starts with `assets/music/`.
- **Corrupted Textures**: OpenGL needs correct pixel alignment. We use `gl.PixelStorei(gl.UNPACK_ALIGNMENT, 1)` to handle non-power-of-two widths.
