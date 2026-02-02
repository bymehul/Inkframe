# `music` command (Vnefall)

The `music` command starts playing a background music track. It can also be called using `play`.

## Syntax
```bash
music <audio_file>
play <audio_file>
```

- **audio_file**: The filename of the track located in `assets/music/`.

## Example
```bash
music theme.mp3
play scary_ambience.ogg
```

## Behavior
- Loops infinitely until changed or the game ends.
- Stops any previously playing music immediately.
- Supports MP3 and OGG formats.
