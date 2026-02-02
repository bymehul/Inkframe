# `say` command (Vnefall)

The `say` command displays dialogue text on the screen.

## Syntax
```bash
say <speaker_name> "<dialogue_text>"
```

- **speaker_name**: The name of the character currently speaking. This will appear above the text box.
- **dialogue_text**: The actual text the character says. This **must** be enclosed in double quotes.

## Example
```bash
say Alice "Hello! I'm Alice."
say Narrator "She greeted the player with a smile."
```

## Behavior
- Automatically wraps text if it's too long for the box.
- Changes the window state to "waiting" until the user clicks or presses space/enter.
