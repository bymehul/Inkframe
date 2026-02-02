# `bg` command (Vnefall)

The `bg` command changes the fullscreen background image.

## Syntax
```bash
bg <image_file>
```

- **image_file**: The filename of the image located in `assets/images/`.

## Example
```bash
bg room.png
bg forest.jpg
```

## Behavior
- Immediately clears the previous background and draws the new one.
- Supports common formats like PNG, JPG, and BMP.
- The engine expects images to be in the `assets/images/` directory.
