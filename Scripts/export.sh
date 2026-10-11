#!/bin/zsh
# Builds a Release copy of Custom Resolution and packages it as a .zip and .dmg in dist/.
#
# Usage:
#   Scripts/export.sh
#
# Optional environment variables:
#   SIGN_IDENTITY   Signing identity, e.g. "Developer ID Application: Your Name (TEAMID)".
#                   Defaults to "-" (ad-hoc): recipients must approve the app in
#                   System Settings > Privacy & Security the first time they open it.
#   NOTARY_PROFILE  A `xcrun notarytool store-credentials` profile name. With a Developer ID
#                   identity, the .dmg is notarized and stapled so it opens without warnings.
set -euo pipefail

ROOT=${0:A:h:h}
cd "$ROOT"

IDENTITY=${SIGN_IDENTITY:--}
APP_NAME="Custom Resolution"
DERIVED="$ROOT/build/DerivedData"
DIST="$ROOT/dist"

sign_flags=(CODE_SIGN_IDENTITY="$IDENTITY")
if [[ "$IDENTITY" != "-" ]]; then
  team=${IDENTITY##*\(}
  sign_flags+=(DEVELOPMENT_TEAM="${team%\)}" OTHER_CODE_SIGN_FLAGS="--timestamp")
fi

echo "› Generating project"
xcodegen generate --quiet

echo "› Building Release (signing: $IDENTITY)"
rm -rf "$DERIVED/Build/Products/Release"
xcodebuild -project CustomResolution.xcodeproj -scheme CustomResolution -configuration Release \
  -destination 'generic/platform=macOS' -derivedDataPath "$DERIVED" -quiet "${sign_flags[@]}" build

APP="$DERIVED/Build/Products/Release/$APP_NAME.app"
codesign --verify --deep --strict "$APP"
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$APP/Contents/Info.plist")
ZIP="$DIST/Custom-Resolution-$VERSION.zip"
DMG="$DIST/Custom-Resolution-$VERSION.dmg"
mkdir -p "$DIST"
rm -f "$ZIP" "$DMG"

echo "› Creating disk image"
STAGE=$(mktemp -d)
trap 'rm -rf "$STAGE"' EXIT
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
hdiutil create -volname "$APP_NAME" -srcfolder "$STAGE" -ov -format UDZO "$DMG" -quiet

if [[ "$IDENTITY" != "-" && -n "${NOTARY_PROFILE:-}" ]]; then
  echo "› Notarizing (this can take a few minutes)"
  codesign --sign "$IDENTITY" --timestamp "$DMG"
  xcrun notarytool submit "$DMG" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$DMG"
  xcrun stapler staple "$APP"
fi

echo "› Creating zip"
ditto -c -k --keepParent "$APP" "$ZIP"

echo
echo "Done:"
echo "  $DMG"
echo "  $ZIP"
