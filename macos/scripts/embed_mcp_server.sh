#!/bin/sh
# ==============================================================================
# DeskDroid — Embed the precompiled MCP server (Xcode Run Script phase)
# ==============================================================================
# Release builds compile bin/deskdroid_mcp.dart with `dart compile exe` into
# DeskDroid.app/Contents/MacOS/deskdroid-mcp, next to the bundled adb (which the
# server finds through HostPaths.executableDirectory). Debug builds skip this:
# use scripts/start_mcp_server.sh from a source checkout instead.
#
# Signed with the app identity, hardened runtime, and McpServer.entitlements.
# `dart compile exe` targets the build machine's CPU only (no macOS
# cross-compilation). See docs/mcp-setup-guide.md.
# ==============================================================================
set -eu

if [ "${CONFIGURATION}" != "Release" ]; then
  echo "note: Skipping MCP server compilation in ${CONFIGURATION} builds."
  exit 0
fi

PROJECT_ROOT="${SRCROOT}/.."
DEST="${TARGET_BUILD_DIR}/${EXECUTABLE_FOLDER_PATH}/deskdroid-mcp"
ENTITLEMENTS="${SRCROOT}/Runner/McpServer.entitlements"
SIGN_IDENTITY="${EXPANDED_CODE_SIGN_IDENTITY:--}"

"${FLUTTER_ROOT}/bin/dart" compile exe \
  "${PROJECT_ROOT}/bin/deskdroid_mcp.dart" -o "${DEST}"

codesign --force --sign "${SIGN_IDENTITY}" --options runtime \
  --entitlements "${ENTITLEMENTS}" "${DEST}"
codesign --verify --strict "${DEST}"
echo "Embedded MCP server ($(lipo -archs "${DEST}")) into ${DEST}"
