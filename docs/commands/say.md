# Command: `say`

Displays dialogue on the screen with an optional speaker name.

## Usage
```vnef
say <speaker> "<text>"
```

## Parameters
- `<speaker>`: The name of the character speaking. If empty, the textbox will only show the dialogue.
- `"<text>"`: The dialogue text, wrapped in double quotes.

## Variable Interpolation
You can include variables in the dialogue using the `${var}` syntax.
```vnef
set gold = 100
say Alice "You have ${gold} gold pieces."
```

## Example
```vnef
say Alice "Hello there!"
say "..." # Narrator style
```

## Notes
- Text automatically wraps based on the `textbox_padding` and `textbox_margin` in `config.vnef`.
- The speaker name is styled using `color_speaker` from the configuration.
