# Flow Commands

Flow commands control script execution, jumping between labels and files.

## Commands

### `label <name>:`

Creates a named marker in the script.

```vnef
label start:
    say Alice "Hello!"
```

### `jump <label>`

Jumps to a label within the same script file.

```vnef
jump start
```

### `jump_file "filename.vnef"`

Loads a completely different script file and starts execution from the beginning.

```vnef
jump_file "chapter_2.vnef"
```

**Key features:**
- Clean state on every file jump (until Database system is added)
- Old script is cleaned up automatically
- Combine with `scene_next` for instant transitions

### `wait`

Pauses script execution until the player clicks.

```vnef
say Alice "..."
wait
say Alice "Thanks for waiting."
```

**Notes**
- This is a hard pause; no automatic advance.

## Multi-File Game Example

### chapter_1.vnef
```vnef
bg forest.png
say Alice "We're in the forest."

# Prefetch next chapter while player reads
scene_next "chapter_2"

say Alice "Let's head to the beach!"
jump_file "chapter_2.vnef"
```

### chapter_2.vnef
```vnef
bg beach.png
say Alice "The beach is beautiful!"
say Alice "And it loaded instantly!"
end
```

## Variable Persistence

Variables set in one file remain available in subsequent files:

### chapter_1.vnef
```vnef
set player_gold = 100
jump_file "chapter_2.vnef"
```

### chapter_2.vnef
```vnef
say Merchant "You have ${player_gold} gold."
# Shows: "You have 100 gold."
```

## Best Practices

1. **Prefetch Before Jump**: Always call `scene_next` a few lines before `jump_file` to preload assets.

2. **One Main Script Per Chapter**: Keep chapters in separate files for organization.

3. **Use Labels for Internal Branching**: For choices within the same chapter, use `label` and `jump`. For chapter transitions, use `jump_file`.
