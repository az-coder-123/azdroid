---
name: deploy-release
description: >-
  Automates the complete Azdroid release and deployment lifecycle when the user requests
  "thực hiện deploy", "deploy", "release", "build release", or "phát hành".
  Enforces version bumping, release notes drafting, README link updates (anti-404 rule),
  quality verification (flutter analyze & flutter test), packaging, and GitHub publishing.
---

# Azdroid Release & Deployment Runbook

Follow this strict 7-step pipeline whenever the user requests "thực hiện deploy", "deploy", or publishing a new Azdroid release.

## Reference Documentation
- [docs/release-guide.md](file:///Users/<USER>/PROJECT/wifi-desk/docs/release-guide.md) (Standard release guide)
- [docs/installation.md](file:///Users/<USER>/PROJECT/wifi-desk/docs/installation.md#5-package-a-release) (Installation and packaging guide)
- [docs/lessons-learned/release-script-cross-platform-artifacts.md](file:///Users/<USER>/PROJECT/wifi-desk/docs/lessons-learned/release-script-cross-platform-artifacts.md) (Cross-platform artifacts & 404 link prevention)
- [docs/lessons-learned/docs-claims-without-code.md](file:///Users/<USER>/PROJECT/wifi-desk/docs/lessons-learned/docs-claims-without-code.md) (Accuracy in release notes)

---

## Step 1: Version Selection & Synchronization
1. Inspect commits since the previous release tag:
   ```bash
   git log --oneline $(git describe --tags --abbrev=0)..HEAD
   ```
2. Determine Semantic Versioning (`MAJOR.MINOR.PATCH`):
   - **MINOR**: If new features or tools were added (`feat:` commits).
   - **PATCH**: If only bug fixes or refactors were added (`fix:`, `refactor:`).
   - **MAJOR**: Breaking architectural changes.
3. Increment the build number after `+` by 1.
4. Synchronize the version in BOTH files:
   - `pubspec.yaml`: `version: X.Y.Z+N`
   - `lib/core/constants/app_constants.dart`: `static const String appVersion = 'X.Y.Z';`
5. Verify version equality via unit test:
   ```bash
   flutter test test/unit/app_version_test.dart
   ```

---

## Step 2: Release Notes Drafting
1. Create `docs/releases/v<version>.md`.
2. Structure strictly into:
   - `## Azdroid v<version> (macOS)`
   - `### New`: Verified new features and tools.
   - `### Improved`: Architectural cleanups and performance improvements.
   - `### Fixed`: Resolved bugs.
   - `### Known Limitations`: Unsigned app Gatekeeper bypass, Rosetta 2 requirement for MCP server on Apple Silicon, Windows Preview status.
   - `### Verify the Download`: `shasum -a 256 Azdroid-v<version>-macOS.zip`
3. Never include unmeasured claims or unimplemented features.

---

## Step 3: README & Platform Support Synchronization
1. In `README.md`:
   - Update macOS download badge link to:
     `https://github.com/az-coder-123/azdroid/releases/latest/download/Azdroid-v<version>-macOS.zip`
     with badge label `v<version>_(Universal)`.
   - **Anti-404 Rule for Windows:** If this release is macOS-only, keep the Windows button pinned to the latest release that actually holds a Windows asset (`.../releases/download/v<prev>/Azdroid-v<prev>-Windows-x64.zip`). NEVER link Windows to `latest/download/...` when the new release lacks a Windows zip.
   - Update macOS package size subtitle (e.g., `(31 MB)`).
   - Update install section command: `Azdroid-v<version>-macOS.zip`.
2. In `docs/platform-support.md`:
   - Update status date and version: `Status date: **YYYY-MM-DD** (Azdroid v<version> on macOS; ...)`.
3. Check for stale version occurrences:
   ```bash
   grep -rn '<old-version>' README.md docs/platform-support.md
   ```

---

## Step 4: Quality Gate & Source Commit
1. Run formatting and zero-warning static analysis:
   ```bash
   dart format .
   flutter analyze   # Must print "No issues found!"
   flutter test      # All tests must pass 100%
   ```
2. Commit source changes before packaging (the release script refuses to publish if files outside `RELEASE/` are uncommitted):
   ```bash
   git add -A
   git commit -m "chore(release): prepare v<version>"
   ```

---

## Step 5: Packaging & GitHub Publishing
1. Run the official packaging script:
   ```bash
   ./scripts/build_release.sh
   ```
   *Note: If testing without publishing first, use dry-run: `./scripts/build_release.sh --no-push --no-gh-release`.*
2. The script automatically:
   - Fetches bundled Platform-Tools (`dart run tool/fetch_platform_tools.dart --os=macos`).
   - Cleans the old `.app` bundle to preserve code signature integrity.
   - Builds release: `flutter build macos --release`.
   - Verifies bundled `adb` and executes codesign strict verification.
   - Performs JSON-RPC smoke test on bundled `azdroid-mcp` binary (`tools/list`).
   - Compresses via Apple `ditto` into `RELEASE/Azdroid-v<version>-macOS.zip` and `RELEASE/Azdroid-macOS-latest.zip`.
   - Preserves existing Windows packages and updates `RELEASE/README.md`.
   - Commits `RELEASE/` artifacts and pushes to GitHub `origin/main`.
   - Publishes GitHub Release via `gh release create v<version>` with `docs/releases/v<version>.md`.

---

## Step 6: Post-Release Verification
Run verification checks immediately after publishing:
1. Verify GitHub Release status:
   ```bash
   gh release view v<version>
   ```
2. Verify download URLs return HTTP 200 (no 404):
   ```bash
   curl -sIL https://github.com/az-coder-123/azdroid/releases/latest/download/Azdroid-v<version>-macOS.zip | grep -i '^http'
   curl -sIL https://github.com/az-coder-123/azdroid/releases/download/v<pinned-win>/Azdroid-v<pinned-win>-Windows-x64.zip | grep -i '^http'
   ```
3. Verify local SHA-256 checksums:
   ```bash
   cd RELEASE && shasum -a 256 -c SHA256SUMS.txt
   ```
4. Verify clean git status:
   ```bash
   git status
   ```
