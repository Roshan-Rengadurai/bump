#!/bin/bash
# Build a distributable Bump-<version>.dmg.
#
#   ./Scripts/make-dmg.sh           # builds release, outputs dist/Bump-<version>.dmg
#
# Requires: Xcode command-line tools (hdiutil, codesign are built-in).
# The resulting DMG is unsigned/unnotarized. Users must remove Gatekeeper
# quarantine before first launch:
#   xattr -dr com.apple.quarantine /Applications/Bump.app
set -euo pipefail
cd "$(dirname "$0")/.."

# 1. Release build → build/Bump.app
./Scripts/bundle.sh release

# 2. Read version from Info.plist
VERSION=$(defaults read "$(pwd)/build/Bump.app/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo "0.1.0")
DMG_NAME="Bump-${VERSION}"
DIST_DIR="dist"
STAGING="/tmp/${DMG_NAME}-staging"
RW_DMG="/tmp/${DMG_NAME}-rw.dmg"
FINAL_DMG="${DIST_DIR}/${DMG_NAME}.dmg"

echo "▸ packaging Bump ${VERSION}…"
mkdir -p "$DIST_DIR"
rm -rf "$STAGING" "$RW_DMG" "$FINAL_DMG"
mkdir -p "$STAGING"

# 3. Stage app + /Applications shortcut
cp -r "build/Bump.app" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

# 4. Create writable DMG from staging folder
hdiutil create \
  -volname "Bump ${VERSION}" \
  -srcfolder "$STAGING" \
  -ov -fs HFS+ \
  "$RW_DMG" \
  > /dev/null

# 5. Convert to compressed read-only DMG
hdiutil convert "$RW_DMG" -format UDZO -o "$FINAL_DMG" > /dev/null

# 6. Cleanup
rm -rf "$STAGING" "$RW_DMG"

echo "✓ ${FINAL_DMG}"
echo ""
echo "Install instructions for users:"
echo "  1. Open ${DMG_NAME}.dmg"
echo "  2. Drag Bump.app → Applications"
echo "  3. Remove quarantine: xattr -dr com.apple.quarantine /Applications/Bump.app"
echo "  4. Launch Bump from Applications"
