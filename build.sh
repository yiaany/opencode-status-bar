#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
APP="build/OpenCode Status Bar.app"
BIN="$APP/Contents/MacOS/OpenCodeStatusBar"
rm -rf build
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
mkdir -p "$APP/Contents/Resources/plugin/src"
cp plugin/package.json plugin/gui-experimental.cjs "$APP/Contents/Resources/plugin/"
cp plugin/src/*.ts "$APP/Contents/Resources/plugin/src/"
swiftc -O -target arm64-apple-macos12.0 Sources/main.swift -o "$BIN.arm64" -framework Cocoa
swiftc -O -target x86_64-apple-macos12.0 Sources/main.swift -o "$BIN.x86_64" -framework Cocoa
lipo -create "$BIN.arm64" "$BIN.x86_64" -output "$BIN"
rm -f "$BIN.arm64" "$BIN.x86_64"
cp LICENSE THIRD-PARTY-LICENSES.md "$APP/Contents/Resources/"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><dict>
<key>CFBundleName</key><string>OpenCodeStatusBar</string><key>CFBundleDisplayName</key><string>OpenCode Status Bar</string>
<key>CFBundleIdentifier</key><string>dev.opencode.statusbar</string><key>CFBundleExecutable</key><string>OpenCodeStatusBar</string>
<key>CFBundleVersion</key><string>0.1.0</string><key>CFBundleShortVersionString</key><string>0.1.0</string>
<key>CFBundlePackageType</key><string>APPL</string><key>LSMinimumSystemVersion</key><string>12.0</string><key>LSUIElement</key><true/>
</dict></plist>
PLIST
xattr -cr "$APP"
codesign --force --sign - "$APP"
if [[ "${1:-}" == "--dmg" ]]; then
  mkdir -p build/dmg-stage; cp -R "$APP" build/dmg-stage/; ln -s /Applications build/dmg-stage/Applications
  hdiutil create -volname "OpenCode Status Bar" -srcfolder build/dmg-stage -ov -format UDZO build/OpenCodeStatusBar.dmg >/dev/null
  rm -rf build/dmg-stage
fi
echo "Built $APP"
