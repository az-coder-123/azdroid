#!/bin/sh
# ==============================================================================
# Azdroid — Embed bundled adb into Azdroid.app (Xcode Run Script phase)
# ==============================================================================
# Copies vendor/platform-tools/macos (filled by `dart run
# tool/fetch_platform_tools.dart`) into the app:
#   adb               -> Contents/MacOS/adb   (found via HostPaths.executableDirectory)
#   NOTICE, version   -> Contents/Resources/platform-tools/
# adb keeps Google's own signature (Developer ID + hardened runtime); it is
# verified, never re-signed. Missing tools: warning in Debug, error in Release.
# See docs/bundled-platform-tools.md.
# ==============================================================================
set -eu

SRC_DIR="${SRCROOT}/../vendor/platform-tools/macos"
DEST_BIN="${TARGET_BUILD_DIR}/${EXECUTABLE_FOLDER_PATH}"
DEST_RES="${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/platform-tools"
FETCH_HINT="Run 'dart run tool/fetch_platform_tools.dart' from the project root."

if [ ! -x "${SRC_DIR}/adb" ]; then
  if [ "${CONFIGURATION}" = "Release" ]; then
    echo "error: Bundled adb is missing (${SRC_DIR}). ${FETCH_HINT}"
    exit 1
  fi
  echo "warning: Bundled adb is missing; the app will use an installed adb. ${FETCH_HINT}"
  exit 0
fi

mkdir -p "${DEST_BIN}" "${DEST_RES}"
cp -f "${SRC_DIR}/adb" "${DEST_BIN}/adb"
for file in "${SRC_DIR}"/*; do
  [ "$(basename "${file}")" = "adb" ] && continue
  cp -f "${file}" "${DEST_RES}/"
done

codesign --verify --strict "${DEST_BIN}/adb"
echo "Embedded adb $(cat "${SRC_DIR}/.version") into ${DEST_BIN}"
