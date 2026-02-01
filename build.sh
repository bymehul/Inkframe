#!/bin/bash
# Inkframe build script

set -e

echo "Building Inkframe..."
odin build src -out:inkframe -debug

echo "Done. Run with: ./inkframe assets/scripts/demo.ink"
