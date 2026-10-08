#!/usr/bin/env bash
# Download the official FontPatcher.zip from a tagged Nerd Fonts release.
# Update font-patcher, Python helpers, glyphnames.json and glyph assets together.
# Usage: /path/to/nerd/download_glyphs.sh [version] (default: 3.5.1).
# Run from any working directory; files are installed beside this script.
# Leave the local maintenance guide in nerd/README.md untouched.
# Extract in a temporary directory, remove it on exit, and leave changes uncommitted.
set -euo pipefail

VERSION=${1:-3.5.1}
DEST=$(cd "$(dirname "$0")" && pwd)
TEMP=$(mktemp -d)
trap 'rm -rf "$TEMP"' EXIT

curl -fSL --retry 3 \
    "https://github.com/ryanoasis/nerd-fonts/releases/download/v${VERSION}/FontPatcher.zip" \
    -o "$TEMP/FontPatcher.zip"
unzip -q "$TEMP/FontPatcher.zip" -d "$TEMP/upstream"
cp "$TEMP/upstream/font-patcher" "$DEST/font-patcher"
cp "$TEMP/upstream/glyphnames.json" "$DEST/glyphnames.json"
mkdir -p "$DEST/bin" "$DEST/glyphs"
cp -R "$TEMP/upstream/bin/." "$DEST/bin/"
cp -R "$TEMP/upstream/src/glyphs/." "$DEST/glyphs/"
