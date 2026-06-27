#!/bin/bash
# Build Bump and wrap the executable into a proper Bump.app bundle.
#
#   ./Scripts/bundle.sh           # debug build → build/Bump.app
#   ./Scripts/bundle.sh release   # optimized release build
#
# The app is self-signed with an ad-hoc signature so it launches locally. For a
# *stable* TCC identity (so Accessibility/Input-Monitoring grants survive
# rebuilds), set BUMP_SIGN_IDENTITY to a self-signed cert name — see CONTRIBUTING.md.
set -euo pipefail
cd "$(dirname "$0")/.."

CONFIG="${1:-debug}"
APP="build/Bump.app"
CONTENTS="$APP/Contents"

echo "▸ swift build ($CONFIG)…"
swift build -c "$CONFIG"
BIN="$(swift build -c "$CONFIG" --show-bin-path)/Bump"

echo "▸ assembling $APP…"
rm -rf "$APP"
mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources"
cp "$BIN" "$CONTENTS/MacOS/Bump"
cp Resources/Info.plist "$CONTENTS/Info.plist"
[ -f Resources/AppIcon.icns ] && cp Resources/AppIcon.icns "$CONTENTS/Resources/"
# Bundle combo sound clips (any audio files dropped in Resources/Sounds).
if compgen -G "Resources/Sounds/*.wav" >/dev/null 2>&1 || compgen -G "Resources/Sounds/*.mp3" >/dev/null 2>&1 \
   || compgen -G "Resources/Sounds/*.m4a" >/dev/null 2>&1 || compgen -G "Resources/Sounds/*.aif*" >/dev/null 2>&1 \
   || compgen -G "Resources/Sounds/*.caf" >/dev/null 2>&1; then
  mkdir -p "$CONTENTS/Resources/Sounds"
  cp Resources/Sounds/*.{wav,mp3,m4a,aiff,aif,caf} "$CONTENTS/Resources/Sounds/" 2>/dev/null || true
  echo "▸ bundled $(ls "$CONTENTS/Resources/Sounds" | wc -l | tr -d ' ') sound clip(s)"
fi

# Prefer the stable self-signed "Bump Dev" cert (so TCC grants survive rebuilds);
# fall back to ad-hoc. Override with BUMP_SIGN_IDENTITY.
if [ -n "${BUMP_SIGN_IDENTITY:-}" ]; then
  IDENTITY="$BUMP_SIGN_IDENTITY"
elif security find-identity -v -p codesigning 2>/dev/null | grep -q "Bump Dev"; then
  IDENTITY="Bump Dev"
else
  IDENTITY="-"   # ad-hoc — grants WILL reset each build; run Scripts/dev-cert.sh to fix
fi
echo "▸ codesign (identity: $IDENTITY)…"
codesign --force --deep --identifier com.bumposs.Bump --sign "$IDENTITY" "$APP"

echo "✓ built $APP"
