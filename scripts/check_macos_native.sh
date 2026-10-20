#!/usr/bin/env bash
# ==============================================================================
# Azdroid — macOS native player check against a real device or emulator
# ==============================================================================
# Compiles the app's own Swift stream classes (macos/Runner) with scrcpy_core
# into a command-line tool and runs them against the device:
#   video  decodes the screen with ScrcpyVideoSession + ScrcpyH264Decoder
#   audio  plays the device audio with ScrcpyAudioSession (Android 11+;
#          Android 10 or older reports DISABLED)
#   scripts/check_macos_native.sh <adb serial> <video|audio> [seconds]
# ==============================================================================
set -euo pipefail

SERIAL="${1:?usage: scripts/check_macos_native.sh <serial> <video|audio> [seconds]}"
MODE="${2:?usage: scripts/check_macos_native.sh <serial> <video|audio> [seconds]}"
SECONDS_TO_RUN="${3:-6}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CORE_DIR="${ROOT_DIR}/native/scrcpy_core"
RUNNER_DIR="${ROOT_DIR}/macos/Runner"
OUT_DIR="${TMPDIR:-/tmp}/deskdroid_macos_native_check"
ADB="${ADB:-$(command -v adb)}"
mkdir -p "${OUT_DIR}"

for source in audio_c_api audio_header pcm_jitter_buffer; do
  c++ -std=c++17 -O2 -Wall -Wextra -Werror -I"${CORE_DIR}/include" \
    -c "${CORE_DIR}/src/${source}.cpp" -o "${OUT_DIR}/${source}.o"
done

swiftc -O \
  -import-objc-header "${RUNNER_DIR}/Runner-Bridging-Header.h" \
  -Xcc -I"${CORE_DIR}/include" \
  "${RUNNER_DIR}/ScrcpyLog.swift" \
  "${RUNNER_DIR}/ScrcpySocket.swift" \
  "${RUNNER_DIR}/ScrcpyStreamStats.swift" \
  "${RUNNER_DIR}/ScrcpyAnnexB.swift" \
  "${RUNNER_DIR}/ScrcpyH264Decoder.swift" \
  "${RUNNER_DIR}/ScrcpyVideoSession.swift" \
  "${RUNNER_DIR}/ScrcpyAudioStats.swift" \
  "${RUNNER_DIR}/ScrcpyAudioOutput.swift" \
  "${RUNNER_DIR}/ScrcpyAudioSession.swift" \
  "${ROOT_DIR}"/tool/macos_native_check/*.swift \
  "${OUT_DIR}"/*.o -lc++ \
  -o "${OUT_DIR}/macos_native_check"

"${OUT_DIR}/macos_native_check" "${ADB}" "${SERIAL}" \
  "${ROOT_DIR}/assets/scrcpy-server.jar" "${MODE}" "${SECONDS_TO_RUN}"
