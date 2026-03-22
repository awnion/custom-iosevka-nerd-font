#!/usr/bin/env bash
set -euo pipefail

REPO="awnion/custom-iosevka-nerd-font"
TAP_REPO="awnion/homebrew-tap"
FONT_NAME="afio"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VERSION=$(cat "$SCRIPT_DIR/../VERSION" | tr -d '[:space:]')
TAG="v${VERSION}"

echo "Updating tap for ${FONT_NAME} ${VERSION}..."

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# download release asset and compute sha256
gh release download "$TAG" \
  -R "$REPO" \
  --pattern "${FONT_NAME}-${VERSION}.zip" \
  --dir "$TMPDIR"

if command -v sha256sum &>/dev/null; then
  SHA256=$(sha256sum "$TMPDIR/${FONT_NAME}-${VERSION}.zip" | cut -d' ' -f1)
else
  SHA256=$(shasum -a 256 "$TMPDIR/${FONT_NAME}-${VERSION}.zip" | cut -d' ' -f1)
fi

echo "SHA256: ${SHA256}"

# clone fresh tap and generate cask from template
gh repo clone "$TAP_REPO" "$TMPDIR/homebrew-tap"

mkdir -p "$TMPDIR/homebrew-tap/Casks"
sed \
  -e "s/@@VERSION@@/${VERSION}/" \
  -e "s/@@SHA256@@/${SHA256}/" \
  "$SCRIPT_DIR/font-afio.template.rb" > "$TMPDIR/homebrew-tap/Casks/font-afio.rb"

cd "$TMPDIR/homebrew-tap"
git add Casks/font-afio.rb
git commit -m "${FONT_NAME} ${VERSION}"
git push origin main

echo "Done: ${FONT_NAME} ${VERSION} pushed to ${TAP_REPO}"
