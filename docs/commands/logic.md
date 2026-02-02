# Command: `set` / `if` / `else`

Logic and conditional branching using variables.

## Usage
```vnef
set <var> = <value>
if (<expression>) { ... }
else { ... }
```

## Parameters
- `<var>`: Variable name.
- `<value>`: An integer, `true` (1), `false` (0), or another variable name.
- `<expression>`: A comparison using `==`, `!=`, `>`, `<`, `>=`, `<=`.

## Logic Blocks
Blocks are wrapped in curly braces `{}`. **Indentation is MANDATORY** for all commands inside a block.

```vnef
set money = 100

if (money >= 50) {
    say Alice "You can afford the room."
} else {
    say Alice "You're too poor."
}
```

## Notes
- **Mandatory Indentation**: Always indent the "children" of an `if` or `else` statement. This makes it easy to see which code belongs to which branch.
- Variables are global to the current script file.
- The `if` line and `else` line can optionally end with `{`.
- `}` must be on its own line or followed by `else`.
