# `wait` & `end` commands (Vnefall)

These commands manage the flow and termination of the script.

---

## `wait`
Pauses the script and waits for user input (left click, space, or enter).

### Syntax
```bash
wait
```

### Behavior
- Useful for making the player pause between background changes or sound effects.

---

## `end`
Gracefully closes the game window and terminates the program.

### Syntax
```bash
end
```

### Behavior
- Triggers the engine's cleanup process and exits.
- Should usually be the last command in your script.
