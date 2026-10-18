#!/usr/bin/env bash
# ==============================================================================
# DeskDroid — macOS audio player check against a real device or emulator
# ==============================================================================
# Compiles the app's own Swift audio classes (macos/Runner) with scrcpy_core
# into a command-line tool and plays the device's audio on this Mac for a few
# seconds. Android 11+ plays; Android 10 or older reports DISABLED.
#   scripts/check_macos_audio.sh <adb serial> [seconds]
# ==============================================================================
set -euo pipefail

SERIAL="${1:?usage: scripts/check_macos_audio.sh <serial> [seconds]}"
SECONDS_TO_PLAY="${2:-6}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CORE_DIR="${ROOT_DIR}/native/scrcpy_core"
RUNNER_DIR="${ROOT_DIR}/macos/Runner"
OUT_DIR="${TMPDIR:-/tmp}/deskdroid_macos_audio_check"
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
  "${RUNNER_DIR}/ScrcpyAudioStats.swift" \
  "${RUNNER_DIR}/ScrcpyAudioOutput.swift" \
  "${RUNNER_DIR}/ScrcpyAudioSession.swift" \
  "${ROOT_DIR}/tool/macos_audio_check/main.swift" \
  "${OUT_DIR}"/*.o -lc++ \
  -o "${OUT_DIR}/macos_audio_check"

"${OUT_DIR}/macos_audio_check" "${ADB}" "${SERIAL}" \
  "${ROOT_DIR}/assets/scrcpy-server.jar" "${SECONDS_TO_PLAY}"
