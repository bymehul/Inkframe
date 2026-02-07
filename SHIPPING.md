# Vnefall — Shipping & Dependencies

This document lists the **runtime libraries** you must ship with exported games, plus build-time requirements.

## Future Work
- **Vulkan backend (Windows/Linux)** for long-term support and performance.
- **Metal backend (macOS)** to replace deprecated OpenGL.
- **Packaging scripts** for Windows `.zip`, macOS `.app`, and Linux AppImage.

## Runtime Libraries (Required)
- **SDL2**
- **SDL2_mixer**
- **OpenGL 3.3** (system-provided on desktop; no separate shipping)

These are required by the engine at runtime for window/input, audio, and rendering.

## Runtime Libraries (Optional — Video)
If you enable the `movie` command (vnef-video), you must also ship:
- **vnef_video** shared library
- **FFmpeg libs**: `libavformat`, `libavcodec`, `libavutil`, `libswscale`, `libswresample`

Build note: if you see `Path does not exist: vnef_video`, build with `./build.sh` or pass `-collection:vnefvideo=./utils/vnef-video/bindings` (see `build.sh`).

## Embedded (No External Shipping Needed)
- `stb_image`
- `stb_truetype`

These are compiled into the binary via Odin vendor packages.

---

## Windows Shipping
Place these next to your game `.exe`:
- `SDL2.dll`
- `SDL2_mixer.dll`

If your SDL2_mixer build enables these codecs, include the matching DLLs:
- `libogg-0.dll`, `libvorbis-0.dll`, `libvorbisfile-3.dll` (Ogg/Vorbis)
- `libmpg123-0.dll` (MP3)
- `libFLAC-8.dll` (FLAC)
- `libmodplug-1.dll` (MOD/XM)

## macOS Shipping
Bundle these inside your `.app`:
- `SDL2.framework`
- `SDL2_mixer.framework`

OpenGL is provided by macOS. No additional GL runtime shipping is required.

## Linux Shipping
Option A: rely on system packages:
- `libsdl2`
- `libsdl2-mixer`

Option B: ship a self-contained build (AppImage/Flatpak) including SDL2 libs.

---

## Build-Time Requirements (Developers)
- Odin compiler
- SDL2 development headers
- SDL2_mixer development headers

Linux (Debian/Ubuntu):
```bash
sudo apt install libsdl2-dev libsdl2-mixer-dev libsdl2-ttf-dev
```

macOS:
```bash
brew install sdl2 sdl2_mixer
```

Windows:
- Install Odin
- Download SDL2 + SDL2_mixer development packages and set include/lib paths

---

## Notes
- If a shipped build fails to play audio, it is almost always a missing SDL2_mixer codec DLL on Windows.
- The engine uses **OpenGL 3.3**; older GPUs may fail to run.
