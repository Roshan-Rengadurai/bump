#!/bin/bash
# Generate Resources/AppIcon.icns from Scripts/IconGen.swift.
set -euo pipefail
cd "$(dirname "$0")/.."

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
MASTER="$TMP/icon_1024.png"

echo "▸ rendering master icon…"
swift Scripts/IconGen.swift "$MASTER"

ICONSET="$TMP/AppIcon.iconset"
mkdir -p "$ICONSET"
gen() { sips -z "$1" "$1" "$MASTER" --out "$ICONSET/$2" >/dev/null; }
gen 16   icon_16x16.png
gen 32   icon_16x16@2x.png
gen 32   icon_32x32.png
gen 64   icon_32x32@2x.png
gen 128  icon_128x128.png
gen 256  icon_128x128@2x.png
gen 256  icon_256x256.png
gen 512  icon_256x256@2x.png
gen 512  icon_512x512.png
cp "$MASTER" "$ICONSET/icon_512x512@2x.png"

echo "▸ iconutil → Resources/AppIcon.icns"
iconutil -c icns "$ICONSET" -o Resources/AppIcon.icns
echo "✓ wrote Resources/AppIcon.icns ($(du -h Resources/AppIcon.icns | cut -f1))"
