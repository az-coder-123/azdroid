#!/usr/bin/env bash
# ==============================================================================
# DeskDroid — Writes RELEASE/README.md from the packages present in RELEASE/
# ==============================================================================
# Lists every platform whose checksum file exists (macOS: SHA256SUMS.txt,
# Windows: SHA256SUMS-windows.txt), each with its own version, size, and
# SHA-256, so a macOS-only release keeps the Windows entry and vice versa.
#
# Usage: scripts/release/write_release_readme.sh <release-dir>
# Steps it is part of: docs/release-guide.md
# ==============================================================================

set -euo pipefail

RELEASE_DIR="${1:?usage: write_release_readme.sh <release-dir>}"
REPO_URL="https://github.com/az-coder-123/desk-droid"
README="${RELEASE_DIR}/README.md"

# Prints "<zip>|<version>|<size>|<sha256>" for the versioned zip listed in a
# checksum file, or nothing when the file is missing.
package_row() {
  local sums="${RELEASE_DIR}/$1"
  [[ -f "$sums" ]] || return 0
  local line zip sha version size
  line=$(grep -E 'DeskDroid-v[0-9]' "$sums" | head -1)
  sha=$(awk '{print $1}' <<< "$line")
  zip=$(awk '{print $2}' <<< "$line")
  version=$(sed -E 's/^DeskDroid-v([0-9.]+)-.*/\1/' <<< "$zip")
  size=$(ls -lh "${RELEASE_DIR}/${zip}" | awk '{print $5}')
  echo "${zip}|${version}|${size}|${sha}"
}

MAC_ROW=$(package_row SHA256SUMS.txt)
WIN_ROW=$(package_row SHA256SUMS-windows.txt)
if [[ -z "$MAC_ROW" && -z "$WIN_ROW" ]]; then
  echo "No checksum file in ${RELEASE_DIR}; nothing to describe." >&2
  exit 1
fi

table_row() {
  local platform="$1" row="$2"
  IFS='|' read -r zip version size sha <<< "$row"
  echo "| **[\`${zip}\`](${zip})** | ${platform} | v${version} | \`${size}\` | \`${sha}\` |"
}

{
  cat <<EOF
# DeskDroid Release Packages

> Android screen mirroring and control for macOS and Windows, over Wi-Fi and USB. All releases and notes: [GitHub Releases](${REPO_URL}/releases).

## Packages

| Package | Platform | Version | Size | SHA-256 |
| :--- | :--- | :--- | :--- | :--- |
EOF
  [[ -n "$MAC_ROW" ]] && table_row "macOS 12.0+ (Apple Silicon & Intel)" "$MAC_ROW"
  [[ -n "$WIN_ROW" ]] && table_row "Windows 10/11 x64 (Preview)" "$WIN_ROW"
  cat <<'EOF'

Each `*-latest.zip` file is a copy of the newest package for its platform.

ADB and scrcpy-server are bundled. An ADB you install yourself takes precedence over the bundled one.

## Install on macOS

1. Unzip the macOS package and drag **DeskDroid.app** into `/Applications`.
2. The app is not signed with an Apple Developer ID. If macOS says the developer cannot be verified, run once:
   ```bash
   xattr -cr /Applications/DeskDroid.app
   ```
   Or right-click the app, choose **Open**, then **Open** again.

## Install on Windows (Preview)

1. Unzip the Windows package to a folder you own, for example `%LOCALAPPDATA%\Programs\DeskDroid`.
2. Run `desk_droid.exe`. Keep the `.dll` files and the `data` folder next to it.
3. The app is not code-signed. If SmartScreen appears, click **More info**, then **Run anyway**.

## Verify a Download

```bash
shasum -a 256 -c SHA256SUMS.txt          # macOS package
shasum -a 256 -c SHA256SUMS-windows.txt  # Windows package
```
EOF
} > "$README"

echo "Wrote ${README}"
