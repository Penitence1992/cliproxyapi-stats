#!/bin/bash
set -euo pipefail

APP_NAME="CliproxyAPI Stats"
BUNDLE_ID="com.cliproxyapi.stats"
BINARY_NAME="CliproxyAPIStats"
VERSION="${1:-1.0.0}"

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

# Create .app bundle structure
echo "Creating app bundle..."
rm -rf "${APP_DIR}"
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# Copy binary
cp "${BUILD_DIR}/${BINARY_NAME}" "${MACOS_DIR}/${BINARY_NAME}"

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
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

# Ad-hoc code sign (prevents "damaged" error on download)
echo "Code signing (ad-hoc)..."
codesign --force --deep --sign - "${APP_DIR}"
codesign --verify "${APP_DIR}"

# Zip for distribution
echo "Creating zip archive..."
ZIP_NAME="CliproxyAPIStats-${VERSION}-macOS.zip"
ditto -c -k --keepParent "${APP_DIR}" "${ZIP_NAME}"

echo "Done! Output: ${ZIP_NAME}"
