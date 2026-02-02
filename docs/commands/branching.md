# Command: `label` / `jump`

Markers and movement for non-linear story branching.

## Usage
```vnef
label <name>:
jump <name>
```

## Parameters
- `<name>`: A unique identifier for the location in the script.
  - The colon after the label name is optional but recommended.

## Example
```vnef
say Alice "Do you want to go left or right?"

choice_add "Left" go_left
choice_add "Right" go_right
choice_show

label go_left:
    say Alice "You went left."
    jump finished

label go_right:
    say Alice "You went right."

label finished:
    say Alice "The end."
    end
```

## Notes
- Labels are scanned at startup, allowing you to jump forward or backward in the file.
- `label` commands do nothing during normal execution; they are just markers.
- Indentation after labels is recommended for readability.
