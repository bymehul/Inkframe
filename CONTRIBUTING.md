# Contributing to Vnefall

We're glad you want to help! Vnefall is built to be simple, fast, and easy to read.

## Code Quality

We prioritize code that is clean, readable. Whether you write it by hand or use tools (including AI) to help, the end result should look like it was thoughtfully crafted by a human for other humans to read. Avoid over-templated boilerplate or rigid, machine-like patterns that add unnecessary complexity.

### 1. Meaningful Comments
Don't just state what the code does—the code should be clear enough to speak for itself. Use comments to explain **why** a certain choice was made or to point out tricky logic.
- **Bad**: `// Increment the instruction pointer`
- **Good**: `// Move to the next command. We stay here until the user interacts.`

### 2. Code Style
We follow idiomatic Odin naming conventions:
- **Procedures & Variables**: `snake_case` (e.g., `init_game`, `script_path`)
- **Types & Structs**: `Snake_Case` (e.g., `Game_State`, `Audio_State`)
- **Constants**: `SCREAMING_SNAKE_CASE` (e.g., `FONT_SIZE`)

### 3. Avoid Hardcoding
Try to keep logic flexible. Use constants for magic numbers and configurable paths when possible. If a value belongs in a script or a config file, don't bury it deep in the engine code.

### 4. Conciseness over Complexity
If there's a simpler way to write something that's still clear, do it. We prefer organic-looking logic over rigid design patterns that add unnecessary layers.

## Building the Project

Building should always be simple. Use the provided build script:

```bash
chmod +x build.sh
./build.sh
```

This runs the standard Odin build command:
`odin build src -out:vnefall`

## How to Submit Changes
1. Keep your PRs small and focused.
2. Ensure the project builds without errors before submitting.
3. Update the `README.md` if you add a new script command.

Happy coding!
