#!/usr/bin/env bash
# ==============================================================================
# DeskDroid — MCP Server Launcher
# ==============================================================================
# Launches the DeskDroid Model Context Protocol (MCP) server over stdio.
# Compatible with Claude Desktop, Cursor, and Antigravity IDE.
# ==============================================================================

set -euo pipefail

# Ensure standard package manager and developer tool paths are available
# (GUI apps on macOS like Antigravity IDE/Claude do not inherit shell profile PATH)
export PATH="$PATH:/opt/homebrew/bin:/usr/local/bin"
for p in \
  "${FLUTTER_ROOT:-}/bin" \
  "${HOME}/DevTools/flutter/bin" \
  "${HOME}/flutter/bin" \
  "${HOME}/development/flutter/bin" \
  "${HOME}/sdk/flutter/bin" \
  "${ANDROID_HOME:-}/platform-tools" \
  "${ANDROID_SDK_ROOT:-}/platform-tools" \
  "${HOME}/Library/Android/sdk/platform-tools"
do
  [[ -n "$p" && -d "$p" ]] && export PATH="$PATH:$p"
done

# Verify dart is available
if ! command -v dart &> /dev/null; then
  echo "[DeskDroid MCP Error] 'dart' command not found in PATH." >&2
  echo "Please ensure Flutter or Dart SDK is installed." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "$ROOT_DIR"
exec dart run "${ROOT_DIR}/bin/deskdroid_mcp.dart" "$@"
