# Command: `bg`

Changes the current background image of the scene.

## Usage
```vnef
bg <filename>
```

## Parameters
- `<filename>`: The name of the image file (including extension) located in the images directory.
  - Default directory: `assets/images/`

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
