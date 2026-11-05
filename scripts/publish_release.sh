#!/usr/bin/env bash
set -e

export PATH="$PATH:$HOME/Development/flutter/bin:$HOME/development/flutter/bin:$HOME/.cargo/bin"

# Change directory to project root
cd "$(dirname "$0")/.."

# Extract version from pubspec.yaml
VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //' | cut -d'+' -f1 | tr -d ' ')
TAG="v$VERSION"
ARTIFACTS_DIR="release-artifacts/$TAG"

echo "========================================="
echo "  Vyreon Studio Release Automator: $TAG"
echo "========================================="

mkdir -p "$ARTIFACTS_DIR"

NEED_BUILD=false
if [ ! -f "$ARTIFACTS_DIR/vyreon-studio-arm64-v8a-$TAG.apk" ] || \
   [ ! -f "$ARTIFACTS_DIR/vyreon-studio-armeabi-v7a-$TAG.apk" ] || \
   [ ! -f "$ARTIFACTS_DIR/vyreon-studio-x86_64-$TAG.apk" ] || \
   [ ! -f "$ARTIFACTS_DIR/vyreon-studio-universal-$TAG.apk" ] || \
   [ "$1" == "--rebuild" ]; then
    NEED_BUILD=true
fi

if [ "$NEED_BUILD" = true ]; then
    echo "[1/4] Building native Rust engine..."
    (cd native/rust_engine && cargo build --release)

    echo "[2/4] Building Split per-ABI APKs..."
    flutter build apk --release --split-per-abi

    echo "[3/4] Building Universal APK..."
    flutter build apk --release

    echo "[4/4] Packaging release APKs..."
    cp build/app/outputs/flutter-apk/app-arm64-v8a-release.apk "$ARTIFACTS_DIR/vyreon-studio-arm64-v8a-$TAG.apk"
    cp build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk "$ARTIFACTS_DIR/vyreon-studio-armeabi-v7a-$TAG.apk"
    cp build/app/outputs/flutter-apk/app-x86_64-release.apk "$ARTIFACTS_DIR/vyreon-studio-x86_64-$TAG.apk"
    cp build/app/outputs/flutter-apk/app-release.apk "$ARTIFACTS_DIR/vyreon-studio-universal-$TAG.apk"
else
    echo "Using existing built release APKs in $ARTIFACTS_DIR:"
fi

ls -lh "$ARTIFACTS_DIR"/vyreon-studio-*.apk

# Check GitHub CLI Authentication and Publish
echo ""
echo "Checking GitHub authentication status..."
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    echo "Publishing release $TAG to GitHub..."
    gh release create "$TAG" "$ARTIFACTS_DIR"/vyreon-studio-*.apk \
        --title "Vyreon Studio $TAG" \
        --generate-notes
    echo "Successfully published $TAG to GitHub Releases!"
else
    echo "------------------------------------------------------------"
    echo "GitHub CLI not logged in yet."
    echo "To log in, run: gh auth login"
    echo "After logging in, rerun: ./scripts/publish_release.sh"
    echo "------------------------------------------------------------"
fi
