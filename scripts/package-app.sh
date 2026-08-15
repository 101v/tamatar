#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_CONFIG="${1:-release}"
APP_DIR="${ROOT}/Tamatar.app"
BINARY="${ROOT}/.build/${BUILD_CONFIG}/Tamatar"

swift build -c "${BUILD_CONFIG}" --package-path "${ROOT}"

rm -rf "${APP_DIR}"
mkdir -p "${APP_DIR}/Contents/MacOS" "${APP_DIR}/Contents/Resources"
cp "${BINARY}" "${APP_DIR}/Contents/MacOS/Tamatar"
cp "${ROOT}/Packaging/Info.plist" "${APP_DIR}/Contents/Info.plist"
cp "${ROOT}/Packaging/AppIcon.icns" "${APP_DIR}/Contents/Resources/AppIcon.icns"

echo "Built ${APP_DIR}"
echo "Run with: open ${APP_DIR}"
