---
name: deploy-release
description: >-
  Automates the complete Azdroid release and deployment lifecycle when the user requests
  "thực hiện deploy", "deploy", "release", "build release", or "phát hành".
  Executes the canonical ./scripts/deploy.sh pipeline, enforcing version bumping,
  release notes drafting, README link updates (anti-404 rule), quality verification,
  packaging, and GitHub publishing.
---

# Azdroid Release & Deployment Runbook

This skill automates the complete 7-step release and deployment pipeline for Azdroid.

## ⚡️ Primary Command for AI Assistants

Whenever a user requests to deploy or publish a release (e.g., *"thực hiện deploy"*, *"deploy"*, *"release"*, *"phát hành"*):

1. **Inspect recent commits** to determine semantic version bump (`patch`, `minor`, or `major`):
   ```bash
   git log --oneline $(git describe --tags --abbrev=0 2>/dev/null || echo "")..HEAD
   ```
   - **patch**: Bug fixes, minor documentation updates.
   - **minor**: New features, new tools, performance enhancements.
   - **major**: Breaking architectural changes, protocol rewrites.

2. **Execute the Canonical Deployment Script**:
   ```bash
   ./scripts/deploy.sh <patch|minor|major>
   ```
   - *For preview/test runs without pushing to GitHub:*
     ```bash
     ./scripts/deploy.sh <patch|minor|major> --dry-run
     ```
   - *For building and committing locally without remote push:*
     ```bash
     ./scripts/deploy.sh <patch|minor|major> --no-push
     ```

---

## 🛡️ Mandatory Rules & Invariants (Enforced by Pipeline)

1. **Version Alignment Invariant:**
   - Both `pubspec.yaml` (`version: X.Y.Z+N`) and `lib/core/constants/app_constants.dart` (`static const String appVersion = 'X.Y.Z';`) must be updated in tandem.
   - Verified by `flutter test test/unit/app_version_test.dart`.

2. **Anti-404 Windows Badge Rule:**
   - On `README.md`, if the new release is macOS-only, the Windows download badge **must remain pinned** to the latest release tag that actually contains a Windows binary (`.../releases/download/v<pinned>/Azdroid-v<pinned>-Windows-x64.zip`).
   - **NEVER** link Windows to `/releases/latest/download/...` when the latest release lacks a Windows asset (GitHub will return HTTP 404).

3. **Zero Claims Without Code:**
   - Release notes in `docs/releases/v<version>.md` must only document verified features present in code. Never state unverified tool counts, latency numbers, or unreleased platforms.

4. **Zero-Warning Quality Gate:**
   - The pipeline strictly runs `dart format .`, `flutter analyze` (must return *"No issues found!"*), and `flutter test` (100% pass) before committing or packaging.

---

## 📋 The 7-Step Pipeline (Under the Hood)

The `./scripts/deploy.sh` script automates these stages sequentially:

| Step | Phase | Key Actions |
|:---|:---|:---|
| **1** | **Pre-flight Checks** | Verifies toolchain (`flutter`, `dart`, `git`, `gh`, `ditto`, `curl`), ensures branch `main` and clean git working tree. |
| **2** | **Version Synchronization** | Computes semantic version and build number (+1), updates `pubspec.yaml` and `app_constants.dart`, verifies with unit test. |
| **3** | **Release Notes** | Generates `docs/releases/v<version>.md` structured into New, Improved, Fixed, Known Limitations, and Checksum. |
| **4** | **README & Docs Sync** | Updates macOS download badge and install command to `v<version>`, updates `docs/platform-support.md` date. |
| **5** | **Quality Gate** | Formats Dart code, executes `flutter analyze` (zero issues), and runs all tests (`flutter test`). |
| **6** | **Source Commit** | Commits all prepared source files with `chore(release): prepare v<version>`. |
| **7** | **Packaging & GitHub Release** | Calls `scripts/build_release.sh`, smoke tests bundled `adb` and `azdroid-mcp`, packs ZIPs, commits `RELEASE/`, pushes to `main`, and creates GitHub Release via `gh release create`. |

---

## 🔍 Post-Deployment Verification

After the deployment script completes, AI assistants can verify the live release:

```bash
# 1. Verify GitHub Release asset availability
gh release view v<version> --json assets,url --jq '.url, .assets[].name'

# 2. Verify download URLs return HTTP 200 (no 404)
curl -sIL https://github.com/az-coder-123/azdroid/releases/latest/download/Azdroid-v<version>-macOS.zip | grep -i '^http'

# 3. Verify clean git state
git status
```
