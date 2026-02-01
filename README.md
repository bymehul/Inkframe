# Inkframe

A minimal visual novel engine written in Odin.

## Quick Start

### 1. Build the engine
Make sure you have [Odin](https://odin-lang.org/) installed, then run:
```bash
chmod +x build.sh
./build.sh
```

### 2. Run the demo
```bash
./inkframe assets/scripts/demo.ink
```

## Script Format

```
bg room.png
say Alice "Hello there!"
say Bob "Welcome to the story."
wait
bg night.png
say Alice "Good night."
end
```

## Controls

- **Click** / **Space** / **Enter** — Advance dialogue

## License

Open source. The current license can be updated at any time as the project evolves. I am also planning to transition to a **dual-licensing** model in the future to support long-term development.

