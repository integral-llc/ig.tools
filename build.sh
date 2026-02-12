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

echo "Done → ${BUNDLE_DIR}"
