#!/usr/bin/env bash
set -euo pipefail

APP_NAME="IG Tools"
BUNDLE_DIR="build/${APP_NAME}.app"
CONTENTS_DIR="${BUNDLE_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "Building IGTools..."
swift build -c release

echo "Assembling ${APP_NAME}.app..."
rm -rf "${BUNDLE_DIR}"
mkdir -p "${MACOS_DIR}" "${RESOURCES_DIR}"

cp .build/release/IGTools "${MACOS_DIR}/IGTools"
cp Resources/Info.plist "${CONTENTS_DIR}/Info.plist"

# Copy resource files if they exist
if [ -d "Resources" ]; then
    # Copy all files except Info.plist and Assets.xcassets
    find Resources -mindepth 1 -maxdepth 1 ! -name "Info.plist" ! -name "Assets.xcassets" -exec cp -r {} "${RESOURCES_DIR}/" \; 2>/dev/null || true

    # Handle Assets.xcassets separately - try to compile them
    if [ -d "Resources/Assets.xcassets" ]; then
        # Try to compile the asset catalog with actool
        if command -v actool &> /dev/null; then
            echo "Compiling asset catalog..."
            actool --compile "${RESOURCES_DIR}" \
                   --platform macosx \
                   --minimum-deployment-target 14.0 \
                   --output-format human-readable-text \
                   --app-icon AppIcon \
                   --output-partial-info-plist "${RESOURCES_DIR}/assetcatalog_generated_info.plist" \
                   Resources/Assets.xcassets 2>/dev/null || {
                # If compilation fails, fall back to copying the assets
                echo "Failed to compile assets, copying instead..."
                cp -r Resources/Assets.xcassets "${RESOURCES_DIR}/"
            }
        else
            # actool not available, just copy the assets
            cp -r Resources/Assets.xcassets "${RESOURCES_DIR}/"
        fi
    fi
fi

# Install to /Applications if --install flag is passed
if [[ "${1:-}" == "--install" ]]; then
    echo "Installing to /Applications..."
    rm -rf "/Applications/${APP_NAME}.app"
    cp -R "${BUNDLE_DIR}" "/Applications/${APP_NAME}.app"
    echo "Done → /Applications/${APP_NAME}.app"
else
    echo "Done → ${BUNDLE_DIR}"
    echo "Run './build.sh --install' to copy to /Applications"
fi
