#!/usr/bin/env bash
# ==============================================================================
# DeskDroid — MCP Server Launcher
# ==============================================================================
# Launches the DeskDroid Model Context Protocol (MCP) server over stdio.
# Compatible with Claude Desktop, Cursor, and Antigravity IDE.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "$ROOT_DIR"
exec dart run "${ROOT_DIR}/bin/deskdroid_mcp.dart" "$@"
