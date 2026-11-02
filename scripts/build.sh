#!/usr/bin/env bash
# Builds .build/NotchBar.app from source. Requires the Swift toolchain from
# Command Line Tools (swiftc), no Xcode project needed.
#
# The bundle is a staging step only: dist/ holds the shippable NotchBar-x.y.z.dmg.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

ARCH="$(uname -m)"
APP="$ROOT/.build/NotchBar.app"
BIN="$APP/Contents/MacOS/NotchBar"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

swiftc -O -wmo \
    -target "$ARCH-apple-macos13.0" \
    -o "$BIN" \
    Sources/NotchBar/*.swift

cp Resources/Info.plist "$APP/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

# Ad-hoc signature; the login item API refuses unsigned bundles.
codesign --force --sign - "$APP" >/dev/null 2>&1 || true

echo "built $APP"
