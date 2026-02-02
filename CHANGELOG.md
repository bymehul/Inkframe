# Changelog

All notable changes to Vnefall will be documented in this file.

## [1.1.0] - 2026-02-02
### Added
- **Scene System**: Per-chapter asset management with auto-generated manifests (`scene.odin`, `manifest.odin`).
- **Background Prefetching**: `scene_next` command preloads next scene's assets while player reads.
- **Multi-File Support**: `jump_file` command loads and executes a different `.vnef` script file.
- **Branching**: Labels, jumps, choices, variables, and `if/else` blocks (`choice_add`, `choice_show`).
- **Variable Interpolation**: `${var}` syntax in dialogue and choices.
- **Roadmap**: Added persistence to disk (Save/Load system) to `future.md`.
- **Memory Optimization**: `script_cleanup()` for reuse, `script_destroy()` for final cleanup.
- **Documentation**: New docs for `scenes.md`, `flow.md`, expanded `memory.md`.

### Changed
- **Script Loader**: Now supports reloading without memory leaks.
- **ARCHITECTURE.md**: Added Scene System to systems list.

### Fixed
- Use-after-free bug when jumping between script files.
- Memory leaks in config string handling.

---

## [1.0.0] - 2026-02-01
### Added
- **Core Engine**: Initial release of the Vnefall engine.
- **Rendering**: OpenGL 3.3 Core Profile renderer with support for textured quads.
- **Text System**: Bitmap font rendering using `stb_truetype` with automated word wrapping.
- **Script Engine**: Support for `bg`, `say`, `music`, `play`, `title`, `wait`, and `end` commands.
- **Audio**: Background music support with looping via `SDL_mixer`.
- **Polish**: Full code refactor for organic, human-readable style.
- **Documentation**: Comprehensive README, CONTRIBUTING, technical ARCHITECTURE guide, and detailed Command Documentation.
