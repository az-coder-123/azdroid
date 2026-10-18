#!/usr/bin/env bash
# ==============================================================================
# DeskDroid — macOS Release Build & Packaging Automation Script
# ==============================================================================
# Automates the entire release lifecycle:
#   1. Runs static analysis and automated test suites
#   2. Compiles hardware-optimized macOS release bundle
#   3. Packages .app bundle into high-compression zip archive using Apple ditto
#   4. Computes cryptographic SHA-256 verification checksums
#   5. Generates RELEASE/ documentation and installation guide
#   6. Commits & pushes release artifacts to GitHub
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
BUILD_APP_PATH="${ROOT_DIR}/build/macos/Build/Products/Release/DeskDroid.app"

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
echo -e "${BOLD}${CYAN}⚡️  DeskDroid — Production Release Packaging Pipeline${NC}"
echo -e "${BOLD}${CYAN}======================================================================${NC}"

# 1. Extract application version from pubspec.yaml
if [[ ! -f "$PUBSPEC_PATH" ]]; then
  echo -e "${RED}Error: pubspec.yaml not found at ${PUBSPEC_PATH}${NC}"
  exit 1
fi

VERSION_RAW=$(grep -E '^version:' "$PUBSPEC_PATH" | awk '{print $2}')
VERSION_NAME=$(echo "$VERSION_RAW" | cut -d'+' -f1)
BUILD_NUMBER=$(echo "$VERSION_RAW" | cut -d'+' -f2)

ZIP_NAME="DeskDroid-v${VERSION_NAME}-macOS.zip"
LATEST_ZIP_NAME="DeskDroid-macOS-latest.zip"

echo -e "${BLUE}ℹ️  Application Version:${NC} ${BOLD}v${VERSION_NAME} (Build ${BUILD_NUMBER})${NC}"
echo -e "${BLUE}ℹ️  Target Architecture:${NC} Apple Silicon & Intel Universal (macOS 12.0+)"
echo ""

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

APP_SIZE=$(du -sh "$BUILD_APP_PATH" | awk '{print $1}')
echo -e "${GREEN}✓ Application bundle compiled:${NC} DeskDroid.app (${APP_SIZE})"

# 4. Packaging with Apple ditto tool
echo -e "${YELLOW}📦 [Step 4/5] Packaging release archive into RELEASE/...${NC}"
mkdir -p "$RELEASE_DIR"
cd "$RELEASE_DIR"

# Clean old zip archives to keep only the latest release archive
find "${RELEASE_DIR}" -maxdepth 1 -name "DeskDroid-v*.zip" ! -name "$ZIP_NAME" -delete 2>/dev/null || true
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

# 5. Generate RELEASE/README.md Documentation
cat <<EOF > "${RELEASE_DIR}/README.md"
# ⚡️ DeskDroid — Official Production Releases

> High-performance Android screen mirroring & developer workstation for macOS over Wi-Fi & USB.

---

## 📥 Current Release: v${VERSION_NAME} (Build ${BUILD_NUMBER})

| Asset | Platform | File Size | SHA-256 Checksum |
| :--- | :--- | :--- | :--- |
| **[\`${ZIP_NAME}\`](${ZIP_NAME})** | macOS 12.0+ (Apple Silicon & Intel) | \`${ZIP_SIZE}\` | \`${SHA256_HASH}\` |
| **[\`${LATEST_ZIP_NAME}\`](${LATEST_ZIP_NAME})** | macOS 12.0+ (Latest Snapshot) | \`${ZIP_SIZE}\` | \`${SHA256_HASH}\` |

---

## 🚀 Installation Guide (macOS)

1. Download **[\`${ZIP_NAME}\`](${ZIP_NAME})** from this directory or the [GitHub Releases](https://github.com/az-coder-123/desk-droid/releases) page.
2. Unzip the archive by double-clicking it in macOS Finder or running:
   \`\`\`bash
   unzip ${ZIP_NAME}
   \`\`\`
3. Drag **DeskDroid.app** into your \`/Applications\` folder.
4. Ensure **ADB (Android Debug Bridge)** is installed on your Mac:
   \`\`\`bash
   brew install android-platform-tools
   \`\`\`

### 🛡️ macOS Gatekeeper Security Note (Unsigned Builds)
Because DeskDroid is open-source and not signed with an Apple Developer Program ID, macOS Gatekeeper may prompt: *"DeskDroid cannot be opened because the developer cannot be verified"*.

To allow DeskDroid to run seamlessly, run this one-time command in macOS Terminal:
\`\`\`bash
xattr -cr /Applications/DeskDroid.app
\`\`\`
Or right-click **DeskDroid.app** in Finder, choose **Open**, and click **Open** on the confirmation dialog.

---

## 🔒 Verification
To verify the integrity of your downloaded release archive:
\`\`\`bash
shasum -a 256 -c SHA256SUMS.txt
\`\`\`
EOF

echo -e "${GREEN}✓ Release documentation generated:${NC} ${RELEASE_DIR}/README.md"

# 6. Push to GitHub
if [ "$PUSH_GIT" = true ]; then
  echo -e "${YELLOW}🚀 [Step 5/5] Committing release artifacts and pushing to GitHub...${NC}"
  cd "$ROOT_DIR"
  git add pubspec.yaml scripts/build_release.sh RELEASE/ docs/
  git commit -m "chore(release): package DeskDroid v${VERSION_NAME} macOS release archive" || echo "No changes to commit"
  git push origin main
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
      --title "DeskDroid v${VERSION_NAME}" \
      --notes "## ⚡️ DeskDroid v${VERSION_NAME} Production Release for macOS

- 🚀 **Performance:** Glass-to-glass latency under 20ms with 60–120 FPS hardware video decoding.
- 📶 **Dual Connection:** Subnet auto-discovery, mDNS wireless debugging, and plug-and-play USB cable mode.
- 🛠️ **Developer Workstation:** Built-in Logcat Console, Intent & Deep Link Dispatcher, 1-Click APK Manager, Finder-style File Explorer, Screen Recording, and Area Crop.
- 🤖 **MCP AI Server:** 58 headless automation & inspection tools for AI agents (Claude Desktop, Cursor, Antigravity).

### 📥 Download & Verification
- **File:** \`${ZIP_NAME}\` (\`${ZIP_SIZE}\`)
- **SHA-256:** \`${SHA256_HASH}\`

### 🛡️ macOS Gatekeeper Note
For community builds, run: \`xattr -cr /Applications/DeskDroid.app\`"
  fi
  echo -e "${GREEN}✓ GitHub Release published:${NC} https://github.com/az-coder-123/desk-droid/releases/tag/${TAG_NAME}"
fi

echo ""
echo -e "${BOLD}${GREEN}======================================================================${NC}"
echo -e "${BOLD}${GREEN}🎉  Release Build & Publishing Completed Successfully!${NC}"
echo -e "${BOLD}${GREEN}======================================================================${NC}"
echo -e "Archive:    ${BOLD}${RELEASE_DIR}/${ZIP_NAME}${NC}"
echo -e "Checksum:   ${BOLD}${SHA256_HASH}${NC}"
echo -e "Repository: ${BOLD}https://github.com/az-coder-123/desk-droid${NC}"
echo ""
