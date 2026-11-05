#!/usr/bin/env bash
set -e

# Change directory to project root
cd "$(dirname "$0")/.."

# Extract version from pubspec.yaml
VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //' | cut -d'+' -f1 | tr -d ' ')
TAG="v$VERSION"
ARTIFACTS_DIR="release-artifacts/$TAG"

echo "========================================="
echo "  Vyreon Studio Release Automator: $TAG"
echo "========================================="

# 1. Build Rust Native Engine
echo "[1/5] Building native Rust engine..."
(cd native/rust_engine && cargo build --release)

# 2. Build Split per-ABI APKs
echo "[2/5] Building Split per-ABI APKs..."
flutter build apk --release --split-per-abi

# 3. Build Universal APK
echo "[3/5] Building Universal APK..."
flutter build apk --release

# 4. Copy and Rename Artifacts
echo "[4/5] Packaging release APKs with architecture naming..."
mkdir -p "$ARTIFACTS_DIR"
cp build/app/outputs/flutter-apk/app-arm64-v8a-release.apk "$ARTIFACTS_DIR/vyreon-studio-arm64-v8a-$TAG.apk"
cp build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk "$ARTIFACTS_DIR/vyreon-studio-armeabi-v7a-$TAG.apk"
cp build/app/outputs/flutter-apk/app-x86_64-release.apk "$ARTIFACTS_DIR/vyreon-studio-x86_64-$TAG.apk"
cp build/app/outputs/flutter-apk/app-release.apk "$ARTIFACTS_DIR/vyreon-studio-universal-$TAG.apk"

ls -lh "$ARTIFACTS_DIR"/vyreon-studio-*.apk

# 5. Check GitHub CLI Authentication and Publish
echo "[5/5] Checking GitHub CLI auth..."
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    echo "Publishing release $TAG to GitHub..."
    gh release create "$TAG" "$ARTIFACTS_DIR"/vyreon-studio-*.apk \
        --title "Vyreon Studio $TAG" \
        --generate-notes
    echo "Successfully published $TAG to GitHub Releases!"
else
    echo "------------------------------------------------------------"
    echo "GitHub CLI not authenticated yet."
    echo "To upload automatically, run: gh auth login"
    echo "Then re-run this script, or upload manually from:"
    echo "  $ARTIFACTS_DIR/"
    echo "------------------------------------------------------------"
fi
