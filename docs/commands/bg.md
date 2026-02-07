# Command: `bg`

Changes the current background image of the scene.

## Usage
```vnef
bg <filename>
bg <filename> blur=<value>
bg_blur <value>
```

## Parameters
- `<filename>`: The name of the image file (including extension) located in the images directory.
  - Default directory: `demo/assets/images/`

## Example
```vnef
bg room.png
say Alice "Welcome to my room!"
bg night.jpg
say Alice "It's getting late."
```

## Notes
- Images are scaled to fit the design resolution automatically.
- Supported formats: `.png`, `.jpg`, `.bmp`.
- For cinematic transitions, use `with fade|wipe|slide|dissolve|zoom|blur|flash|shake|none` before `bg`.
- `shake` strength is controlled by `bg_shake_px` in `demo/ui.vnef`.
- `bg_blur` is stateful: it applies to the current background and stays until you set it to `0`.
- `bg <file> blur=<value>` is **one-shot**: it applies only to that background. The next `bg` without `blur=` reverts to the last `bg_blur` value.
- Quality is controlled by `bg_blur_quality` in `demo/config.vnef` (`high | medium | low`).

## Examples
```vnef
bg "room.png"
bg_blur 12
say Narrator "Soft focus."
bg_blur 0
bg "hallway.png" blur=8
```
