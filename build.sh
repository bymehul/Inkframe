#!/bin/bash
# Vnefall build script

set -e

echo "Building Vnefall..."
if [ ! -f ./utils/vnef-video/build/libvnef_video.so ]; then
  echo "Building vnef-video (requires FFmpeg dev libs)..."
  cmake -S ./utils/vnef-video -B ./utils/vnef-video/build
  cmake --build ./utils/vnef-video/build
fi

if [ -f ./utils/vnef-video/build/libvnef_video.so ]; then
  cp ./utils/vnef-video/build/libvnef_video.so ./libvnef_video.so
fi
odin build src -out:vnefall -debug \
  -collection:vneui=./vneui \
  -collection:vnefvideo=./utils/vnef-video/bindings \
  -extra-linker-flags:"-L./utils/vnef-video/build -lvnef_video"

echo "Done. Run with: ./vnefall demo/assets/scripts/demo_game.vnef"
