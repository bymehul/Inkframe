# Command: `music` / `play`

Plays background music or sound effects.

## Usage
```vnef
music <filename>
play <filename>
```

## Parameters
- `<filename>`: The name of the audio file in the music directory.
  - Default directory: `assets/music/`

## Example
```vnef
music dungeon_theme.ogg
say Alice "It's cold in here..."
```

## Notes
- `music` and `play` currently behave the same in v1.1.0, looping the track until changed.
- Supported formats: `.ogg`, `.mp3`, `.wav`.
