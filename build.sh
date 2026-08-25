#!/bin/bash
# Build Cadence and assemble a double-clickable .app bundle.
# Requires only the Swift command line tools (no full Xcode).
set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="Cadence"
BUNDLE_ID="com.cadence.app"
CONFIG="release"

echo "==> swift build ($CONFIG)"
swift build -c "$CONFIG"

BIN_DIR="$(swift build -c "$CONFIG" --show-bin-path)"
BIN="$BIN_DIR/$APP_NAME"

if [[ ! -f "$BIN" ]]; then
  echo "error: built binary not found at $BIN" >&2
  exit 1
fi

APP="$APP_NAME.app"
echo "==> assembling $APP"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp "$BIN" "$APP/Contents/MacOS/$APP_NAME"

# Copy the SPM-generated resource bundle (fonts) into Resources, where
# Bundle.module resolves it via Bundle.main.resourceURL. (Do NOT place it in
# MacOS — codesign --deep rejects a resource bundle sitting beside the binary.)
for b in "$BIN_DIR"/*.bundle; do
  [[ -e "$b" ]] || continue
  cp -R "$b" "$APP/Contents/Resources/"
done

# App icon (regenerate with: swift tools/make_icon.swift + sips/iconutil)
[[ -f AppIcon.icns ]] && cp AppIcon.icns "$APP/Contents/Resources/"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>            <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>     <string>$APP_NAME</string>
    <key>CFBundleExecutable</key>      <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>      <string>$BUNDLE_ID</string>
    <key>CFBundlePackageType</key>     <string>APPL</string>
    <key>CFBundleShortVersionString</key> <string>1.0</string>
    <key>CFBundleVersion</key>         <string>1</string>
    <key>CFBundleIconFile</key>        <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>  <string>14.0</string>
    <key>NSHighResolutionCapable</key> <true/>
    <key>LSApplicationCategoryType</key> <string>public.app-category.productivity</string>
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLName</key>    <string>Cadence</string>
            <key>CFBundleURLSchemes</key> <array><string>cadence</string></array>
        </dict>
    </array>
</dict>
</plist>
PLIST

echo "==> ad-hoc code signing"
codesign --force --deep --sign - "$APP" >/dev/null 2>&1 || echo "   (codesign skipped)"

echo "==> done: $(pwd)/$APP"
