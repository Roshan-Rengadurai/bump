#!/bin/bash
# Create a STABLE, trusted self-signed code-signing certificate for local dev.
#
# Why: macOS TCC (Accessibility, Input Monitoring) keys a permission grant to the
# app's *code signature identity*. An ad-hoc signature ("-") has no stable
# identity, so every rebuild looks like a new app and your grants reset. Signing
# every build with the SAME self-signed cert keeps the identity constant, so you
# grant permissions once.
#
#   ./Scripts/dev-cert.sh        # create + trust the cert (idempotent)
#
# Run once. macOS will pop a dialog to authorize the trust change — approve it
# with Touch ID / your login password. Afterwards bundle.sh auto-uses the cert.
# To start over: delete the "Bump Dev" cert in Keychain Access and re-run.
set -euo pipefail

CERT_NAME="Bump Dev"
KEYCHAIN="$HOME/Library/Keychains/login.keychain-db"

if security find-identity -v -p codesigning | grep -q "$CERT_NAME"; then
  echo "✓ trusted code-signing identity \"$CERT_NAME\" already exists — nothing to do."
  exit 0
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Reuse an existing (untrusted) cert if present; otherwise generate a fresh one.
if security find-certificate -c "$CERT_NAME" >/dev/null 2>&1; then
  echo "▸ found existing \"$CERT_NAME\" cert — (re)applying code-signing trust…"
  security find-certificate -c "$CERT_NAME" -p > "$TMP/cert.pem"
else
  echo "▸ creating self-signed code-signing certificate \"$CERT_NAME\"…"
  # keyUsage=digitalSignature is REQUIRED by codesign ("Invalid Key Usage" without it).
  openssl req -x509 -newkey rsa:2048 -nodes \
    -keyout "$TMP/key.pem" -out "$TMP/cert.pem" -days 3650 \
    -subj "/CN=$CERT_NAME" \
    -addext "keyUsage=critical,digitalSignature" \
    -addext "extendedKeyUsage=critical,codeSigning" \
    -addext "basicConstraints=critical,CA:false" >/dev/null 2>&1

  # -legacy + non-empty passphrase: macOS can't verify openssl 3.x's default
  # PKCS12 MAC, so emit the legacy format.
  P12_PASS="bump-dev"
  openssl pkcs12 -export -legacy -inkey "$TMP/key.pem" -in "$TMP/cert.pem" \
    -out "$TMP/bumpdev.p12" -passout "pass:$P12_PASS" >/dev/null 2>&1

  security import "$TMP/bumpdev.p12" -k "$KEYCHAIN" -P "$P12_PASS" \
    -T /usr/bin/codesign -T /usr/bin/security >/dev/null

  # Let codesign use the private key without prompting on every build.
  security set-key-partition-list -S apple-tool:,apple: -s -k "" "$KEYCHAIN" >/dev/null 2>&1 || true
fi

# Trust the cert for the Code Signing policy (user domain — no sudo). This pops a
# one-time auth dialog.
echo "▸ marking \"$CERT_NAME\" as trusted for code signing (approve the dialog)…"
security add-trusted-cert -r trustRoot -p codeSign -k "$KEYCHAIN" "$TMP/cert.pem"

echo
if security find-identity -v -p codesigning | grep -q "$CERT_NAME"; then
  echo "✓ \"$CERT_NAME\" is ready. bundle.sh will use it automatically."
  echo "  The next build still asks for permissions once — that grant now sticks."
else
  echo "✗ cert created but still not showing as valid. Open Keychain Access,"
  echo "  find \"$CERT_NAME\", Get Info → Trust → Code Signing: Always Trust."
fi
