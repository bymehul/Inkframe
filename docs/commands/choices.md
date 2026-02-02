# Command: `choice_add` / `choice_show`

Dynamically builds and displays a player choice menu.

## Usage
```vnef
choice_add "<text>" <label>
choice_show
```

## Parameters
- `"<text>"`: The text to display on the button. Supports `${var}` interpolation.
- `<label>`: The script label to jump to if this option is selected.

## Example
```vnef
set has_key = true

say Alice "What will you do?"

choice_add "Run away" leave_town
if (has_key) {
    choice_add "Unlock the gate" open_gate
}

choice_show
```

## Notes
- **Mandatory Indentation**: Commands inside `if` blocks or following a `choice_add` sequence must be indented (4 spaces or 1 tab) to clearly show the parent-child relationship.
- `choice_add` only stages the option; nothing is visible until `choice_show` is called.
- The menu is automatically cleared after a selection is made.
- This system allows for complex, state-based menus.
