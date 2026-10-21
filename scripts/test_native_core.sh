#!/usr/bin/env bash
# ==============================================================================
# Azdroid — Native scrcpy_core Test Runner (macOS / Linux)
# ==============================================================================
# Builds native/scrcpy_core with strict warnings (matching MSVC /W4 /WX used by
# the Windows runner) and runs its tests three times:
#   1. plain build
#   2. AddressSanitizer + UndefinedBehaviorSanitizer
#   3. ThreadSanitizer (frame buffer concurrency)
# On Windows, build the same sources with CMake: native/scrcpy_core/CMakeLists.txt
# ==============================================================================

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CORE_DIR="${ROOT_DIR}/native/scrcpy_core"
OUT_DIR="${TMPDIR:-/tmp}/azdroid_scrcpy_core_tests"
CXX="${CXX:-c++}"

mkdir -p "${OUT_DIR}"

SOURCES=("${CORE_DIR}"/src/*.cpp "${CORE_DIR}"/test/*.cpp)
FLAGS=(
  -std=c++17 -O1 -g
  -Wall -Wextra -Wpedantic -Wconversion -Wsign-conversion -Wshadow -Werror
  -fno-exceptions
  -I"${CORE_DIR}/include"
)

run_variant() {
  local name="$1"; shift
  local binary="${OUT_DIR}/scrcpy_core_tests_${name}"
  echo "==> ${name}"
  "${CXX}" "${FLAGS[@]}" "$@" "${SOURCES[@]}" -o "${binary}" -lpthread
  "${binary}"
}

run_variant plain
run_variant asan_ubsan -fsanitize=address,undefined -fno-sanitize-recover=all
run_variant tsan -fsanitize=thread

echo "All scrcpy_core test variants passed."
