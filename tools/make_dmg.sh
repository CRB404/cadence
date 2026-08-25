#!/bin/bash
# Package Cadence.app into a shareable Cadence.dmg with the classic
# "drag to Applications" layout. Rebuilds the app first.
set -euo pipefail
cd "$(dirname "$0")/.."

./build.sh

STAGE=$(mktemp -d)
RW=$(mktemp -u).dmg
trap 'rm -rf "$STAGE" "$RW"' EXIT
cp -R Cadence.app "$STAGE/"
ln -s /Applications "$STAGE/Applications"

HAVE_ICON=0
if command -v SetFile >/dev/null 2>&1 && [[ -f AppIcon.icns ]]; then
  cp AppIcon.icns "$STAGE/.VolumeIcon.icns"
  HAVE_ICON=1
fi

# Writable image first (so the volume-icon attribute can be stamped),
# then compress to the final read-only DMG.
hdiutil create -volname Cadence -srcfolder "$STAGE" -ov -format UDRW -quiet "$RW"

if [[ $HAVE_ICON -eq 1 ]]; then
  MOUNT=$(hdiutil attach "$RW" -noverify -nobrowse | awk '/\/Volumes\//{print substr($0, index($0,"/Volumes/"))}')
  if [[ -n "$MOUNT" ]]; then
    SetFile -a C "$MOUNT" 2>/dev/null || true
    hdiutil detach "$MOUNT" -quiet
  fi
fi

rm -f Cadence.dmg
hdiutil convert "$RW" -format UDZO -o Cadence.dmg -quiet

echo "==> $(pwd)/Cadence.dmg ($(du -h Cadence.dmg | cut -f1 | tr -d ' '))"
