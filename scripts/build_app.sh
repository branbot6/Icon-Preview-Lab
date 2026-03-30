#!/bin/zsh
set -euo pipefail

NATIVE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="Icon Preview Lab"
EXEC_NAME="IconPreviewLabNative"
OUT_DIR="$NATIVE_DIR/dist"
APP_DIR="$OUT_DIR/$APP_NAME.app"
STAGE_DIR="$OUT_DIR/stage"
ROOT_ICON_SOURCE="$NATIVE_DIR/ip-icon.icns"

if [[ -n "${VERSION:-}" ]]; then
  VERSION="$VERSION"
elif command -v git >/dev/null 2>&1; then
  TAG_VERSION_RAW="$(git -C "$NATIVE_DIR" describe --tags --abbrev=0 2>/dev/null || true)"
  TAG_VERSION="$(echo "$TAG_VERSION_RAW" | sed 's/^v//')"
  VERSION="${TAG_VERSION:-1.1.0}"
else
  VERSION="1.1.0"
fi

DMG_PATH="$OUT_DIR/$APP_NAME-$VERSION-native-arm64.dmg"
ICON_SOURCE="$ROOT_ICON_SOURCE"

mkdir -p "$OUT_DIR"

swift build --configuration release --package-path "$NATIVE_DIR"

BIN_PATH="$NATIVE_DIR/.build/release/$EXEC_NAME"
if [[ ! -x "$BIN_PATH" ]]; then
  echo "Release binary not found: $BIN_PATH"
  exit 1
fi

rm -rf "$APP_DIR" "$STAGE_DIR" "$DMG_PATH"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources" "$STAGE_DIR"

ditto --noextattr --norsrc "$BIN_PATH" "$APP_DIR/Contents/MacOS/$EXEC_NAME"
chmod +x "$APP_DIR/Contents/MacOS/$EXEC_NAME"

ditto --noextattr --norsrc "$NATIVE_DIR/Sources/IconPreviewLabNative/Resources/index.html" "$APP_DIR/Contents/Resources/index.html"
ditto --noextattr --norsrc "$NATIVE_DIR/Sources/IconPreviewLabNative/Resources/branai-logo.svg" "$APP_DIR/Contents/Resources/branai-logo.svg"
ditto --noextattr --norsrc "$NATIVE_DIR/Sources/IconPreviewLabNative/Resources/branai-icon.svg" "$APP_DIR/Contents/Resources/branai-icon.svg"
ditto --noextattr --norsrc "$NATIVE_DIR/Sources/IconPreviewLabNative/Resources/ip-icon-1024.png" "$APP_DIR/Contents/Resources/ip-icon-1024.png"

ICON_FILE_KEY=""
if [[ -f "$ICON_SOURCE" ]]; then
  ditto --noextattr --norsrc "$ICON_SOURCE" "$APP_DIR/Contents/Resources/icon.icns"
  ICON_FILE_KEY='<key>CFBundleIconFile</key><string>icon.icns</string>'
fi

cat > "$APP_DIR/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key><string>en</string>
  <key>CFBundleExecutable</key><string>$EXEC_NAME</string>
  <key>CFBundleIdentifier</key><string>org.branai.iconpreviewlab.native</string>
  <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
  <key>CFBundleName</key><string>$APP_NAME</string>
  <key>CFBundleDisplayName</key><string>$APP_NAME</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>${VERSION%.0}</string>
  <key>CFBundleVersion</key><string>$VERSION</string>
  $ICON_FILE_KEY
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST

# Strip problematic Finder/FileProvider attrs before signing.
xattr -cr "$APP_DIR" || true
xattr -d com.apple.FinderInfo "$APP_DIR" || true
xattr -d com.apple.fileprovider.fpfs#P "$APP_DIR" || true
find "$APP_DIR" -exec xattr -d com.apple.FinderInfo {} + 2>/dev/null || true
find "$APP_DIR" -exec xattr -d com.apple.fileprovider.fpfs#P {} + 2>/dev/null || true

# Ensure the app bundle has a consistent signature envelope.
codesign --force --deep --sign - "$APP_DIR"
codesign --verify --deep --strict --verbose=2 "$APP_DIR"

# Preserve app structure without carrying local metadata detritus.
ditto --noextattr --norsrc "$APP_DIR" "$STAGE_DIR/$APP_NAME.app"
xattr -d com.apple.FinderInfo "$STAGE_DIR/$APP_NAME.app" || true
xattr -d com.apple.fileprovider.fpfs#P "$STAGE_DIR/$APP_NAME.app" || true
codesign --verify --deep --strict --verbose=2 "$STAGE_DIR/$APP_NAME.app"
ln -s /Applications "$STAGE_DIR/Applications"

hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$STAGE_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

hdiutil verify "$DMG_PATH"

rm -rf "$STAGE_DIR"

echo "Native app: $APP_DIR"
echo "Native DMG: $DMG_PATH"
