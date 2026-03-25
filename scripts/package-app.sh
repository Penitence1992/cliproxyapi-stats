#!/bin/bash
set -euo pipefail

APP_NAME="CliproxyAPI Stats"
BUNDLE_ID="com.cliproxyapi.stats"
BINARY_NAME="CliproxyAPIStats"
VERSION="${1:-1.0.0}"

ICON_SOURCE="CliproxyAPIStats/icon.png"
BUILD_DIR="CliproxyAPIStats/.build/release"
APP_DIR="${APP_NAME}.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

# Build release binary
echo "Building release binary..."
cd CliproxyAPIStats
swift build -c release
cd ..

# Generate .icns from icon.png
echo "Generating app icon..."
ICONSET_DIR="AppIcon.iconset"
rm -rf "${ICONSET_DIR}"
mkdir -p "${ICONSET_DIR}"

for SIZE in 16 32 64 128 256 512; do
    sips -z ${SIZE} ${SIZE} "${ICON_SOURCE}" --out "${ICONSET_DIR}/icon_${SIZE}x${SIZE}.png" >/dev/null
    DOUBLE=$((SIZE * 2))
    sips -z ${DOUBLE} ${DOUBLE} "${ICON_SOURCE}" --out "${ICONSET_DIR}/icon_${SIZE}x${SIZE}@2x.png" >/dev/null
done

iconutil -c icns "${ICONSET_DIR}" -o AppIcon.icns
rm -rf "${ICONSET_DIR}"

# Create .app bundle structure
echo "Creating app bundle..."
rm -rf "${APP_DIR}"
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# Copy binary and icon
cp "${BUILD_DIR}/${BINARY_NAME}" "${MACOS_DIR}/${BINARY_NAME}"
cp AppIcon.icns "${RESOURCES_DIR}/AppIcon.icns"
rm -f AppIcon.icns

# Copy SVG icons to Contents/Resources (Bundle.main looks here at runtime)
find "CliproxyAPIStats/Sources/Resources" -name "*.svg" -exec cp {} "${RESOURCES_DIR}/" \; 2>/dev/null || true

# Create Info.plist
cat > "${CONTENTS_DIR}/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleExecutable</key>
    <string>${BINARY_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

# Ad-hoc code sign (prevents "damaged" error on download)
echo "Code signing (ad-hoc)..."
codesign --force --deep --sign - "${APP_DIR}"
codesign --verify "${APP_DIR}"

# Create staging dir for zip
STAGE_DIR="CliproxyAPIStats-${VERSION}"
rm -rf "${STAGE_DIR}"
mkdir "${STAGE_DIR}"
cp -r "${APP_DIR}" "${STAGE_DIR}/"
cat > "${STAGE_DIR}/安装说明.txt" << 'README'
如果 macOS 提示"无法打开"或"已损坏"，请在终端执行：

    xattr -cr "/Applications/CliproxyAPI Stats.app"

然后双击 app 即可正常打开。

原因：macOS Gatekeeper 会隔离从互联网下载的未经 Apple 公证的 app。
README

# Zip for distribution
echo "Creating zip archive..."
ZIP_NAME="CliproxyAPIStats-${VERSION}-macOS.zip"
ditto -c -k --keepParent "${STAGE_DIR}" "${ZIP_NAME}"
rm -rf "${STAGE_DIR}"

echo "Done! Output: ${ZIP_NAME}"
