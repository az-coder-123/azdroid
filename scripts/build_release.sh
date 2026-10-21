#!/usr/bin/env bash
# ==============================================================================
# Azdroid — macOS Release Build & Packaging Automation Script
# ==============================================================================
# Automates the entire release lifecycle:
#   1. Runs static analysis and automated test suites
#   2. Compiles hardware-optimized macOS release bundle
#   3. Packages .app bundle into high-compression zip archive using Apple ditto
#   4. Computes cryptographic SHA-256 verification checksums
#   5. Writes RELEASE/README.md (scripts/release/write_release_readme.sh)
#   6. Commits RELEASE/ and fast-forwards origin/main to it (never forces)
#   7. Creates the GitHub Release v<version> with docs/releases/v<version>.md
#
# Full procedure (what to do before and after): docs/release-guide.md
# ==============================================================================

set -euo pipefail
export PATH="$PATH:/opt/homebrew/bin:/usr/local/bin"
for p in "${FLUTTER_ROOT:-}/bin" "${HOME}/DevTools/flutter/bin" "${HOME}/flutter/bin" "${ANDROID_HOME:-}/platform-tools" "${HOME}/Library/Android/sdk/platform-tools"; do
  [[ -n "$p" && -d "$p" ]] && export PATH="$PATH:$p"
done

# ANSI color codes for readable output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Workspace paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
RELEASE_DIR="${ROOT_DIR}/RELEASE"
PUBSPEC_PATH="${ROOT_DIR}/pubspec.yaml"
BUILD_APP_PATH="${ROOT_DIR}/build/macos/Build/Products/Release/Azdroid.app"

# Parse CLI options
SKIP_TESTS=false
PUSH_GIT=true
CREATE_GH_RELEASE=true

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-tests)
      SKIP_TESTS=true
      shift
      ;;
    --no-push)
      PUSH_GIT=false
      shift
      ;;
    --no-gh-release)
      CREATE_GH_RELEASE=false
      shift
      ;;
    --help|-h)
      echo "Usage: ./scripts/build_release.sh [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --skip-tests       Skip flutter test and flutter analyze checks"
      echo "  --no-push          Do not push git commits to remote repository"
      echo "  --no-gh-release    Do not create GitHub Release via gh CLI"
      echo "  -h, --help         Show this help message"
      exit 0
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      exit 1
      ;;
  esac
done

echo -e "${BOLD}${CYAN}======================================================================${NC}"
echo -e "${BOLD}${CYAN}⚡️  Azdroid — Production Release Packaging Pipeline${NC}"
echo -e "${BOLD}${CYAN}======================================================================${NC}"

# 1. Extract application version from pubspec.yaml
if [[ ! -f "$PUBSPEC_PATH" ]]; then
  echo -e "${RED}Error: pubspec.yaml not found at ${PUBSPEC_PATH}${NC}"
  exit 1
fi

VERSION_RAW=$(grep -E '^version:' "$PUBSPEC_PATH" | awk '{print $2}')
VERSION_NAME=$(echo "$VERSION_RAW" | cut -d'+' -f1)
BUILD_NUMBER=$(echo "$VERSION_RAW" | cut -d'+' -f2)

ZIP_NAME="Azdroid-v${VERSION_NAME}-macOS.zip"
LATEST_ZIP_NAME="Azdroid-macOS-latest.zip"

echo -e "${BLUE}ℹ️  Application Version:${NC} ${BOLD}v${VERSION_NAME} (Build ${BUILD_NUMBER})${NC}"
echo -e "${BLUE}ℹ️  Target Architecture:${NC} Apple Silicon & Intel Universal (macOS 12.0+)"
echo ""

# Publishing needs the release notes and a committed tree, so the release
# commit holds only RELEASE/ and the tag points at reviewed sources.
NOTES_PATH="${ROOT_DIR}/docs/releases/v${VERSION_NAME}.md"
if [ "$CREATE_GH_RELEASE" = true ] && [[ ! -f "$NOTES_PATH" ]]; then
  echo -e "${RED}Error: Release notes missing:${NC} ${NOTES_PATH} (see docs/release-guide.md)"
  exit 1
fi
if [ "$PUSH_GIT" = true ] && [[ -n "$(git -C "$ROOT_DIR" status --porcelain -- . ':!RELEASE')" ]]; then
  echo -e "${RED}Error: Commit or stash your changes first (only RELEASE/ may change).${NC}"
  exit 1
fi

# 2. Pre-flight Quality Verification
if [ "$SKIP_TESTS" = false ]; then
  echo -e "${YELLOW}🔍 [Step 1/5] Running static analysis (flutter analyze)...${NC}"
  cd "$ROOT_DIR"
  flutter analyze

  echo -e "${YELLOW}🧪 [Step 2/5] Running automated test suite (flutter test)...${NC}"
  flutter test
else
  echo -e "${YELLOW}⚠️  [Step 1-2/5] Skipping static analysis and test suite (--skip-tests active)${NC}"
fi

# 3. Compile Production Release
echo -e "${YELLOW}🏗️  [Step 3/5] Compiling macOS desktop release bundle...${NC}"
cd "$ROOT_DIR"
echo -e "${BLUE}Fetching bundled adb (Android Platform-Tools, checksum-verified)...${NC}"
dart run tool/fetch_platform_tools.dart --os=macos
# Start from no app bundle: on an incremental build Xcode re-signs the app
# only when its own binary changes, while the embed phases always rewrite
# azdroid-mcp, which then no longer matches the app's seal.
rm -rf "$BUILD_APP_PATH"
flutter build macos --release

if [[ ! -d "$BUILD_APP_PATH" ]]; then
  echo -e "${RED}Error: Build failed. Application bundle not found at:${NC} $BUILD_APP_PATH"
  exit 1
fi

# The app must be self-contained: adb is bundled and every signature is valid.
BUNDLED_ADB="$BUILD_APP_PATH/Contents/MacOS/adb"
if [[ ! -x "$BUNDLED_ADB" ]]; then
  echo -e "${RED}Error: Bundled adb missing at:${NC} $BUNDLED_ADB"
  exit 1
fi
codesign --verify --deep --strict "$BUILD_APP_PATH"
echo -e "${GREEN}✓ Bundled adb verified:${NC} $("$BUNDLED_ADB" version | head -1)"

# The precompiled MCP server must answer a real JSON-RPC handshake.
BUNDLED_MCP="$BUILD_APP_PATH/Contents/MacOS/azdroid-mcp"
if [[ ! -x "$BUNDLED_MCP" ]]; then
  echo -e "${RED}Error: Precompiled MCP server missing at:${NC} $BUNDLED_MCP"
  exit 1
fi
MCP_SMOKE_REQUEST='{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}'
MCP_SMOKE_REPLY=$(echo "$MCP_SMOKE_REQUEST" | perl -e 'alarm 20; exec @ARGV' "$BUNDLED_MCP")
if ! grep -q '"tools"' <<< "$MCP_SMOKE_REPLY"; then
  echo -e "${RED}Error: MCP server did not answer tools/list.${NC}"
  exit 1
fi
echo -e "${GREEN}✓ MCP server verified:${NC} $(lipo -archs "$BUNDLED_MCP"), answers tools/list"

APP_SIZE=$(du -sh "$BUILD_APP_PATH" | awk '{print $1}')
echo -e "${GREEN}✓ Application bundle compiled:${NC} Azdroid.app (${APP_SIZE})"

# 4. Packaging with Apple ditto tool
echo -e "${YELLOW}📦 [Step 4/5] Packaging release archive into RELEASE/...${NC}"
mkdir -p "$RELEASE_DIR"
cd "$RELEASE_DIR"

# Remove older macOS archives only; the Windows packages are built on Windows
# (scripts/build_release.ps1) and must survive a macOS release.
find "${RELEASE_DIR}" -maxdepth 1 -name "Azdroid-v*-macOS.zip" ! -name "$ZIP_NAME" -delete
rm -f "$ZIP_NAME" "$LATEST_ZIP_NAME" SHA256SUMS.txt

# Use Apple ditto to preserve macOS resource forks, symlinks, and code signature
echo -e "${BLUE}Compressing with Apple ditto...${NC}"
ditto -c -k --sequesterRsrc --keepParent "$BUILD_APP_PATH" "${RELEASE_DIR}/${ZIP_NAME}"
cp "${RELEASE_DIR}/${ZIP_NAME}" "${RELEASE_DIR}/${LATEST_ZIP_NAME}"

# Compute SHA-256 verification hash
echo -e "${BLUE}Generating SHA-256 verification hash...${NC}"
shasum -a 256 "$ZIP_NAME" > "${RELEASE_DIR}/SHA256SUMS.txt"
shasum -a 256 "$LATEST_ZIP_NAME" >> "${RELEASE_DIR}/SHA256SUMS.txt"

ZIP_SIZE=$(ls -lh "$ZIP_NAME" | awk '{print $5}')
SHA256_HASH=$(shasum -a 256 "$ZIP_NAME" | awk '{print $1}')

echo -e "${GREEN}✓ Package created:${NC} ${RELEASE_DIR}/${ZIP_NAME} (${ZIP_SIZE})"
echo -e "${GREEN}✓ SHA-256 Hash:${NC}   ${SHA256_HASH}"

# 5. Describe every package present in RELEASE/ (macOS and Windows)
"${SCRIPT_DIR}/release/write_release_readme.sh" "$RELEASE_DIR"

# 6. Commit RELEASE/ and fast-forward origin/main (a rejected push stops here)
if [ "$PUSH_GIT" = true ]; then
  echo -e "${YELLOW}🚀 [Step 5/5] Committing release artifacts and pushing to GitHub...${NC}"
  cd "$ROOT_DIR"
  git add RELEASE/
  git commit -m "chore(release): package Azdroid v${VERSION_NAME} macOS release archive" || echo "No changes to commit"
  git fetch origin
  git push origin "HEAD:main"
  CURRENT_BRANCH=$(git branch --show-current)
  if [[ -n "$CURRENT_BRANCH" && "$CURRENT_BRANCH" != "main" ]]; then
    git push origin "$CURRENT_BRANCH"
    git branch -f main HEAD
  fi
  echo -e "${GREEN}✓ Release artifacts successfully pushed to GitHub!${NC}"
else
  echo -e "${BLUE}ℹ️  Skipping git push (--no-push active)${NC}"
fi

# 7. Optionally publish via GitHub CLI (gh)
if [ "$CREATE_GH_RELEASE" = true ] && command -v gh &> /dev/null; then
  echo -e "${YELLOW}🏷️  Publishing release to GitHub Releases via gh CLI...${NC}"
  TAG_NAME="v${VERSION_NAME}"
  
  # Check if release tag already exists
  if gh release view "$TAG_NAME" &> /dev/null; then
    echo -e "${BLUE}Release ${TAG_NAME} already exists. Uploading/overwriting asset...${NC}"
    gh release upload "$TAG_NAME" "${RELEASE_DIR}/${ZIP_NAME}" --clobber
  else
    echo -e "${BLUE}Creating new GitHub release ${TAG_NAME}...${NC}"
    gh release create "$TAG_NAME" "${RELEASE_DIR}/${ZIP_NAME}" \
      --target "$(git -C "$ROOT_DIR" rev-parse HEAD)" \
      --title "Azdroid v${VERSION_NAME}" \
      --notes-file "$NOTES_PATH"
  fi
  echo -e "${GREEN}✓ GitHub Release published:${NC} https://github.com/az-coder-123/azdroid/releases/tag/${TAG_NAME}"
fi

echo ""
echo -e "${BOLD}${GREEN}======================================================================${NC}"
echo -e "${BOLD}${GREEN}🎉  Release Build & Publishing Completed Successfully!${NC}"
echo -e "${BOLD}${GREEN}======================================================================${NC}"
echo -e "Archive:    ${BOLD}${RELEASE_DIR}/${ZIP_NAME}${NC}"
echo -e "Checksum:   ${BOLD}${SHA256_HASH}${NC}"
echo -e "Repository: ${BOLD}https://github.com/az-coder-123/azdroid${NC}"
echo ""
