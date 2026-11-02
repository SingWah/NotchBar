#!/usr/bin/env bash
# Packages the staged app into a drag-to-install disk image. This is the only
# file in dist/; the .app used to build it stays in .build/.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

VERSION="$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" Resources/Info.plist)"
APP="$ROOT/.build/NotchBar.app"
DMG="$ROOT/dist/NotchBar-$VERSION.dmg"

if [ ! -d "$APP" ]; then
    echo "先运行 scripts/build.sh" >&2
    exit 1
fi

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"

rm -f "$DMG"
hdiutil create -volname "NotchBar" -srcfolder "$STAGE" -ov -format UDZO "$DMG" >/dev/null

echo "packaged $DMG"
