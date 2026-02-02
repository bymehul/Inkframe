# Vnefall — Future Roadmap

> Features planned for v1.x releases
>
> **Technical Philosophy**: "High-Spirit, Low-Spec." 🚀🥔
> We prioritize OpenGL 3.3 compatibility to ensure beautiful effects run on everything from modern rigs to decade-old laptops.

---

## v1.1.0: Scenes & Multi-File ✅ COMPLETE

- [x] **External Configuration**: A `config.vnef` file to remove hardcoded values.
- [x] **Labels & Jumps**: Organize scripts with labels and non-linear navigation.
- [x] **Choice Menus**: Simple choices for the player to influence the story.
- [x] **Flags & Logic**: Boolean flags, integers, and `if/else` blocks.
- [x] **Variable Interpolation**: `${var}` syntax in dialogue.
- [x] **Scene System**: Per-chapter asset management with manifests.
- [x] **Background Prefetching**: Zero-stutter chapter transitions.
- [x] **Multi-File Scripts**: `jump_file` to load different `.vnef` files.
- [x] **Memory Safety**: Tracking allocator, zero leaks verified.

---

## v1.2.0: Variables & Choices Enhancement (Next Target)

- [ ] **String Variables**: Support `set name = "Alice"` in addition to integers.
- [ ] **Arithmetic Expressions**: Support `set gold = gold + 10`.
- [ ] **Choice Pagination**: Show N choices at a time (e.g., `choice_show 3`).
- [ ] **Choice Clear Command**: Manual `choice_clear` before showing different subsets.
- [ ] **Type-Safe Variables**: Union type for int/string with runtime checks.

---

## v1.3.0: Character Sprites

- [ ] **Sprite System**: Show character sprites on screen.
- [ ] **Sprite Positions**: Left, center, right positioning.
- [ ] **Sprite Expressions**: Swap faces/emotions dynamically.
- [ ] **Sprite Commands**: `sprite show`, `sprite hide`, `sprite move`.

---

## v1.4.0: Save System & Persistence

- [ ] **Native Save Database**: Built-in Odin/C key-value store for game saves.
  - Pure Odin implementation (no external dependencies)
  - Binary format for fast read/write
  - Human-readable fallback (JSON-like)
- [ ] **Save / Load Commands**: `save "slot_1"`, `load "slot_1"`.
- [ ] **Auto-Save**: Optional checkpoint saves.
- [ ] **Variable Persistence**: All `set` variables saved to disk.
- [ ] **Save Metadata**: Timestamps, chapter name, playtime.

---

## v1.5.0: Visual Polish

- [ ] **Fade-to-Black Transitions**: Default cinematic fade during `jump_file`.
- [ ] **Loading Icon**: Pulsing icon in corner while `scene_next` is prefetching.
- [ ] Visual transitions (cross-fades)
- [ ] Text animations (typewriter effect)
- [ ] Shake / flash effects
- [ ] Custom shaders
- [ ] Particle effects (rain, snow, sparkles)

---

## v1.6.0: Audio Expansion

- [ ] Sound effects (SFX)
- [ ] Voice acting support
- [ ] Per-character voice playback
- [ ] Audio ducking

---

## v1.7.0: UI & UX

- [ ] Settings menu (volume, text speed)
- [ ] Backlog (dialogue history)
- [ ] Skip read text
- [ ] Auto-advance mode
- [ ] Gallery Mode (unlock and view CGs)

---

## v1.8.0: Localization & Modding

- [ ] Multi-language support
- [ ] External translation files
- [ ] Custom font loading

---

## v1.9.0: Tooling

- [ ] Script editor GUI
- [ ] Asset packer
- [ ] Debug console
- [ ] Hot reload scripts

---

## v2: Someday / Maybe

- [ ] Mobile port (Android / iOS)
- [ ] Web export (Emscripten)
- [ ] CG gallery
- [ ] Music box (soundtrack viewer)
- [ ] EnvelopeDB integration for cloud saves
- [ ] Mini-games framework
- [ ] Live2D-style animations
- [ ] **Rendering Abstraction**: Move to `wgpu` or `sokol_gfx` to support Web/Mobile and ensure long-term macOS safety.
