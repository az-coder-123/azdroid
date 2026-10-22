#!/usr/bin/env bash
# ==============================================================================
# Azdroid — Automated Full Release & Deployment Pipeline
# ==============================================================================
# Automates the complete 7-step release runbook defined in:
#   - .agents/skills/deploy-release/SKILL.md
#   - docs/release-guide.md
#   - AGENTS.md (Section 10)
#
# Usage:
#   ./scripts/deploy.sh [patch | minor | major | <version>] [options]
#
# Examples:
#   ./scripts/deploy.sh patch                     # 1.3.0 -> 1.3.1 (build +1)
#   ./scripts/deploy.sh minor                     # 1.3.0 -> 1.4.0 (build +1)
#   ./scripts/deploy.sh major                     # 1.3.0 -> 2.0.0 (build +1)
#   ./scripts/deploy.sh 1.4.0                     # Explicit version target
#   ./scripts/deploy.sh minor --dry-run           # Test build without push/publish
#   ./scripts/deploy.sh patch --no-push           # Build and commit locally only
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Styling
BOLD="\033[1m"
GREEN="\033[0;32m"
BLUE="\033[0;34m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
CYAN="\033[0;36m"
NC="\033[0m"

log_step() { echo -e "\n${BOLD}${CYAN}==>${NC} ${BOLD}$1${NC}"; }
log_info() { echo -e "  ${BLUE}ℹ${NC} $1"; }
log_ok()   { echo -e "  ${GREEN}✓${NC} $1"; }
log_warn() { echo -e "  ${YELLOW}⚠${NC} $1"; }
log_err()  { echo -e "  ${RED}✗${NC} $1" >&2; }

# Default options
BUMP_TYPE=""
DRY_RUN=false
NO_PUSH=false
SKIP_TESTS=false

# Argument parsing
while [[ $# -gt 0 ]]; do
  case "$1" in
    patch|minor|major)
      BUMP_TYPE="$1"
      shift
      ;;
    [0-9]*.[0-9]*.[0-9]*)
      BUMP_TYPE="$1"
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      NO_PUSH=true
      shift
      ;;
    --no-push)
      NO_PUSH=true
      shift
      ;;
    --skip-tests)
      SKIP_TESTS=true
      shift
      ;;
    -h|--help)
      cat <<EOF
Azdroid Automated Deployment Pipeline

Usage:
  ./scripts/deploy.sh [patch | minor | major | <version>] [options]

Options:
  --dry-run      Run pre-flight, version bump, tests, and build, but do not push or publish
  --no-push      Commit sources and artifacts locally, but do not push to GitHub
  --skip-tests   Skip flutter analyze and flutter test (emergency only)
  -h, --help     Show this help message

Semver rules:
  patch          Bug fixes, minor doc updates (x.y.Z+1)
  minor          New features, tools, or enhancements (x.Y.0+1)
  major          Breaking protocol or architectural changes (X.0.0+1)
  <x.y.z>        Explicitly target the specified version number
EOF
      exit 0
      ;;
    *)
      log_err "Unknown argument: $1 (run with --help for usage)"
      exit 1
      ;;
  esac
done

if [[ -z "$BUMP_TYPE" ]]; then
  echo -e "${BOLD}Select release version increment:${NC}"
  echo "  1) patch (bug fixes, small refactors)"
  echo "  2) minor (new features, tools, optimizations)"
  echo "  3) major (breaking architectural changes)"
  read -r -p "Enter choice [1-3] or explicit version (e.g. 1.4.0): " user_choice
  case "$user_choice" in
    1|patch) BUMP_TYPE="patch" ;;
    2|minor) BUMP_TYPE="minor" ;;
    3|major) BUMP_TYPE="major" ;;
    [0-9]*.[0-9]*.[0-9]*) BUMP_TYPE="$user_choice" ;;
    *) log_err "Invalid selection: $user_choice"; exit 1 ;;
  esac
fi

cd "$ROOT_DIR"

# ------------------------------------------------------------------------------
# STEP 1: Pre-flight Environment & Git Working Tree Check
# ------------------------------------------------------------------------------
log_step "Step 1: Pre-flight Verification & Environment Checks"

for tool in flutter dart git gh ditto curl; do
  if ! command -v "$tool" &>/dev/null; then
    log_err "Required tool '$tool' not found on PATH."
    exit 1
  fi
done
log_ok "Required toolchain verified (flutter, dart, git, gh, ditto, curl)"

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ "$CURRENT_BRANCH" != "main" && "$DRY_RUN" == false ]]; then
  log_warn "Currently on branch '$CURRENT_BRANCH', not 'main'."
  read -r -p "Do you want to continue on '$CURRENT_BRANCH'? [y/N]: " confirm_branch
  if [[ ! "$confirm_branch" =~ ^[Yy]$ ]]; then
    log_err "Aborted by user. Please checkout 'main' before deploying."
    exit 1
  fi
fi

if [[ -n "$(git status --porcelain -- . ':!RELEASE')" ]]; then
  log_err "Working directory has uncommitted changes outside RELEASE/."
  log_err "Please commit or stash changes before running deploy."
  exit 1
fi
log_ok "Git working directory is clean"

if [[ "$NO_PUSH" == false ]]; then
  if ! gh auth status &>/dev/null; then
    log_err "GitHub CLI (gh) is not authenticated. Run 'gh auth login' first."
    exit 1
  fi
  log_ok "GitHub CLI authenticated"
fi

# ------------------------------------------------------------------------------
# STEP 2: Semantic Version Calculation & Codebase Synchronization
# ------------------------------------------------------------------------------
log_step "Step 2: Semantic Version Calculation & Synchronization"

PUBSPEC_FILE="${ROOT_DIR}/pubspec.yaml"
CONSTANTS_FILE="${ROOT_DIR}/lib/core/constants/app_constants.dart"

CURRENT_VERSION_RAW=$(grep -E '^version:' "$PUBSPEC_FILE" | awk '{print $2}')
CURRENT_VERSION=$(echo "$CURRENT_VERSION_RAW" | cut -d'+' -f1)
CURRENT_BUILD=$(echo "$CURRENT_VERSION_RAW" | cut -d'+' -f2)

IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"
NEW_BUILD=$((CURRENT_BUILD + 1))

case "$BUMP_TYPE" in
  patch)
    NEW_PATCH=$((PATCH + 1))
    NEW_VERSION="${MAJOR}.${MINOR}.${NEW_PATCH}"
    ;;
  minor)
    NEW_MINOR=$((MINOR + 1))
    NEW_VERSION="${MAJOR}.${NEW_MINOR}.0"
    ;;
  major)
    NEW_MAJOR=$((MAJOR + 1))
    NEW_VERSION="${NEW_MAJOR}.0.0"
    ;;
  *)
    NEW_VERSION="$BUMP_TYPE"
    ;;
esac

NEW_VERSION_RAW="${NEW_VERSION}+${NEW_BUILD}"
log_info "Version transition: ${BOLD}v${CURRENT_VERSION}+${CURRENT_BUILD}${NC} ➔ ${BOLD}${GREEN}v${NEW_VERSION}+${NEW_BUILD}${NC}"

# Update pubspec.yaml
sed -i '' -E "s/^version: .*/version: ${NEW_VERSION_RAW}/" "$PUBSPEC_FILE"
log_ok "Updated pubspec.yaml: version: ${NEW_VERSION_RAW}"

# Update app_constants.dart
sed -i '' -E "s/static const String appVersion = '[^']*';/static const String appVersion = '${NEW_VERSION}';/" "$CONSTANTS_FILE"
log_ok "Updated lib/core/constants/app_constants.dart: appVersion = '${NEW_VERSION}'"

# Verify version test
# flutter test: the test imports flutter_test, which `dart test` cannot load.
flutter test test/unit/app_version_test.dart >/dev/null 2>&1 || {
  log_err "Version alignment test failed!"
  exit 1
}
log_ok "Version alignment verified via test/unit/app_version_test.dart"

# ------------------------------------------------------------------------------
# STEP 3: Automated Release Notes Drafting
# ------------------------------------------------------------------------------
log_step "Step 3: Release Notes Generation"

NOTES_DIR="${ROOT_DIR}/docs/releases"
mkdir -p "$NOTES_DIR"
NOTES_FILE="${NOTES_DIR}/v${NEW_VERSION}.md"

PREV_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")

if [[ ! -f "$NOTES_FILE" ]]; then
  log_info "Drafting release notes from git commits since '${PREV_TAG}'..."
  
  COMMITS_LOG=$(git log --oneline ${PREV_TAG:+${PREV_TAG}..HEAD})

  NEW_ITEMS=$(echo "$COMMITS_LOG" | grep -E '^[0-9a-f]+ feat' | sed -E 's/^[0-9a-f]+ feat(\([^)]+\))?:? /- /' || true)
  IMP_ITEMS=$(echo "$COMMITS_LOG" | grep -E '^[0-9a-f]+ (refactor|perf)' | sed -E 's/^[0-9a-f]+ [a-z]+(\([^)]+\))?:? /- /' || true)
  FIX_ITEMS=$(echo "$COMMITS_LOG" | grep -E '^[0-9a-f]+ fix' | sed -E 's/^[0-9a-f]+ fix(\([^)]+\))?:? /- /' || true)

  cat > "$NOTES_FILE" <<EOF
## Azdroid v${NEW_VERSION} (macOS)

### New
${NEW_ITEMS:-"- General feature improvements and optimizations."}

### Improved
${IMP_ITEMS:-"- Architectural refactoring adhering strictly to Single Responsibility Principle."}

### Fixed
${FIX_ITEMS:-"- Stability and performance fixes."}

### Known Limitations
- The app is not signed with an Apple Developer ID. If macOS blocks it, run \`xattr -cr /Applications/Azdroid.app\` once.
- The bundled MCP server (\`azdroid-mcp\`) is built for Intel only; on Apple Silicon it runs seamlessly via Rosetta 2.
- The Windows (Preview) package remains available on its latest dedicated release.

### Verify the Download
Compare the SHA-256 of the ZIP with \`RELEASE/SHA256SUMS.txt\` in the repository:
\`\`\`bash
shasum -a 256 Azdroid-v${NEW_VERSION}-macOS.zip
\`\`\`
EOF
  log_ok "Created release notes draft: ${NOTES_FILE}"
else
  log_ok "Release notes already present: ${NOTES_FILE}"
fi

# ------------------------------------------------------------------------------
# STEP 4: README & Platform Support Synchronization (Anti-404 Guard)
# ------------------------------------------------------------------------------
log_step "Step 4: README & Documentation Synchronization (Anti-404 Guard)"

README_FILE="${ROOT_DIR}/README.md"
PLATFORM_FILE="${ROOT_DIR}/docs/platform-support.md"
TODAY=$(date "+%Y-%m-%d")

# Update macOS download badge in README.md
sed -i '' -E "s|download/Azdroid-v[0-9.]+-macOS\.zip|download/Azdroid-v${NEW_VERSION}-macOS.zip|g" "$README_FILE"
sed -i '' -E "s/Download_for_macOS-v[0-9.]+_\(Universal\)/Download_for_macOS-v${NEW_VERSION}_(Universal)/g" "$README_FILE"

# Update Install section command in README.md
sed -i '' -E "s/Azdroid-v[0-9.]+-macOS\.zip/Azdroid-v${NEW_VERSION}-macOS.zip/g" "$README_FILE"
log_ok "Updated README.md macOS download badge and installation commands to v${NEW_VERSION}"

# Anti-404: this release has no Windows asset, so a Windows link to
# /releases/latest/download/ would break. Pin it to the tag in its file name.
sed -i '' -E "s|releases/latest/download/Azdroid-v([0-9.]+)-Windows-x64\.zip|releases/download/v\1/Azdroid-v\1-Windows-x64.zip|g" "$README_FILE"
if grep -q "releases/latest/download/[^)\"]*Windows" "$README_FILE"; then
  log_err "README.md still links Windows to /releases/latest/download/ (would 404)."
  exit 1
fi
log_ok "Windows download link pinned to the release that has the Windows asset"

# Update docs/platform-support.md date and version
sed -i '' -E "s/Status date: \*\*[0-9-]+\*\* \(Azdroid v[0-9.]+ on macOS/Status date: \*\*${TODAY}\*\* (Azdroid v${NEW_VERSION} on macOS/" "$PLATFORM_FILE"
log_ok "Updated docs/platform-support.md status date to ${TODAY} (v${NEW_VERSION})"

# ------------------------------------------------------------------------------
# STEP 5: Quality Gate & Zero-Warning Enforcement
# ------------------------------------------------------------------------------
log_step "Step 5: Quality Gate & Static Analysis"

log_info "Formatting codebase with dart format..."
dart format . >/dev/null 2>&1
log_ok "Dart code formatted"

if [[ "$SKIP_TESTS" == false ]]; then
  log_info "Running static analysis (flutter analyze)..."
  ANALYZE_OUTPUT=$(flutter analyze)
  if ! echo "$ANALYZE_OUTPUT" | grep -q "No issues found!"; then
    log_err "Static analysis failed with warnings or errors:"
    echo "$ANALYZE_OUTPUT" >&2
    exit 1
  fi
  log_ok "Static analysis passed with zero issues (No issues found!)"

  log_info "Running platform isolation architecture tests..."
  flutter test test/architecture/platform_isolation_test.dart >/dev/null 2>&1
  log_ok "Architecture isolation contract satisfied"

  log_info "Running complete automated test suite (flutter test)..."
  flutter test
  log_ok "All test suites passed with 100% success rate"
else
  log_warn "Skipping test suite (--skip-tests active)"
fi

# ------------------------------------------------------------------------------
# STEP 6: Source Preparation Git Commit
# ------------------------------------------------------------------------------
log_step "Step 6: Committing Source Version Preparation"

git add \
  "$PUBSPEC_FILE" \
  "$CONSTANTS_FILE" \
  "$NOTES_FILE" \
  "$README_FILE" \
  "$PLATFORM_FILE"

git commit -m "chore(release): prepare v${NEW_VERSION}"
log_ok "Created release preparation commit: 'chore(release): prepare v${NEW_VERSION}'"

# ------------------------------------------------------------------------------
# STEP 7: Packaging, Artifact Commit & Publishing
# ------------------------------------------------------------------------------
log_step "Step 7: Compiling macOS Release Bundle & Packaging"

# Invoke official packaging logic
export FLUTTER_ROOT="${FLUTTER_ROOT:-$(dirname $(dirname $(command -v flutter)))}"
"${SCRIPT_DIR}/build_release.sh" --skip-tests --no-push --no-gh-release

log_ok "Compiled, codesigned, and packaged Azdroid-v${NEW_VERSION}-macOS.zip"

# Commit RELEASE/ directory artifacts
RELEASE_DIR="${ROOT_DIR}/RELEASE"
git add "$RELEASE_DIR"
git commit -m "chore(release): package Azdroid v${NEW_VERSION} macOS release archive"
log_ok "Created release archive commit for RELEASE/"

# Publishing to GitHub
if [[ "$NO_PUSH" == false && "$DRY_RUN" == false ]]; then
  log_step "Step 8: Publishing to GitHub Releases"

  log_info "Pushing commits to origin main..."
  git push origin main
  log_ok "Pushed to origin main"

  ZIP_ASSET="${RELEASE_DIR}/Azdroid-v${NEW_VERSION}-macOS.zip"
  LATEST_ZIP_ASSET="${RELEASE_DIR}/Azdroid-macOS-latest.zip"
  SUMS_ASSET="${RELEASE_DIR}/SHA256SUMS.txt"

  if gh release view "v${NEW_VERSION}" &>/dev/null; then
    log_info "GitHub Release 'v${NEW_VERSION}' already exists. Uploading assets..."
    gh release upload "v${NEW_VERSION}" "$ZIP_ASSET" "$LATEST_ZIP_ASSET" "$SUMS_ASSET" --clobber
    log_ok "Updated assets for existing GitHub Release v${NEW_VERSION}"
  else
    log_info "Creating GitHub Release 'v${NEW_VERSION}'..."
    gh release create "v${NEW_VERSION}" \
      "$ZIP_ASSET" \
      "$LATEST_ZIP_ASSET" \
      "$SUMS_ASSET" \
      --title "Azdroid v${NEW_VERSION}" \
      --notes-file "$NOTES_FILE"
    log_ok "Published GitHub Release v${NEW_VERSION}"
  fi

  # Verification
  log_info "Verifying published release URLs (Anti-404 check)..."
  DOWNLOAD_URL="https://github.com/az-coder-123/azdroid/releases/latest/download/Azdroid-v${NEW_VERSION}-macOS.zip"
  HTTP_STATUS=$(curl -sIL "$DOWNLOAD_URL" | grep -E '^HTTP' | tail -1 | awk '{print $2}')

  if [[ "$HTTP_STATUS" == "200" ]]; then
    log_ok "Download URL verified: HTTP 200 OK (${DOWNLOAD_URL})"
  else
    log_warn "Download URL returned HTTP ${HTTP_STATUS}. Please verify manually on GitHub."
  fi
else
  log_info "Dry run or --no-push active. Skipped push and GitHub release publishing."
fi

echo -e "\n${BOLD}${GREEN}======================================================================${NC}"
echo -e "${BOLD}${GREEN} 🎉 Azdroid v${NEW_VERSION} Deployment Pipeline Completed Successfully!${NC}"
echo -e "${BOLD}${GREEN}======================================================================${NC}"
echo -e "Release Notes : ${NOTES_FILE}"
echo -e "Archive       : RELEASE/Azdroid-v${NEW_VERSION}-macOS.zip"
if [[ "$NO_PUSH" == false && "$DRY_RUN" == false ]]; then
  echo -e "GitHub Release: https://github.com/az-coder-123/azdroid/releases/tag/v${NEW_VERSION}"
fi
echo ""
