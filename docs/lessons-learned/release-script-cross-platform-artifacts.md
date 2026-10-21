# Release Script: Cross-Platform Artifacts, Stale Pushes, and 404 Links

## 1. Context & Symptoms

Preparing Azdroid v1.1.0 (macOS only; the Windows package stays at v1.0.1) through `scripts/build_release.sh`. Read before running, the script would have:

- deleted the committed Windows package,
- pushed an old `main` while the release commit sat on the feature branch,
- regenerated `RELEASE/README.md` without the Windows package and with "install ADB with brew", although ADB is bundled,
- and the README Windows button would have returned 404 once v1.1.0 became "latest".

Two version constants (`AppConstants.appVersion = '1.0.1'`, MCP `serverVersion = '1.0.0'`) had also drifted from `pubspec.yaml`, with nothing checking them.

## 2. Diagnostic Traces & Evidence

- Cleanup: `find RELEASE -name "Azdroid-v*.zip" ! -name "$ZIP_NAME" -delete` also matches `Azdroid-v1.0.1-Windows-x64.zip`.
- Push: `git commit` on the current branch, then `git push origin main`, which pushes the local `main` ref, not `HEAD`.
- README links: `releases/latest/download/Azdroid-v1.0.1-Windows-x64.zip`. GitHub resolves `latest` to the newest release, and v1.1.0 has no Windows asset.
- `gh release view v1.0.1` lists the Windows ZIP, so a link pinned to `releases/download/v1.0.1/…` stays valid.
- `grep -rn appVersion lib test`: the constant had no reader and no test.

## 3. Root Cause Analysis

The script was written when only macOS released. Windows packaging was added later in a separate script (`build_release.ps1`) that writes into the same folder, but the macOS script still assumed it owned `RELEASE/`. Release steps were run rarely and from memory, so nothing exercised these paths before a real release. The version lived in three places with no guard.

## 4. Architectural Solution

- Cleanup removes only `Azdroid-v*-macOS.zip`.
- `scripts/release/write_release_readme.sh` builds `RELEASE/README.md` from every checksum file present, so each platform keeps its own version, size, and hash.
- Publishing pushes `HEAD:main` (fast-forward only), then the current branch. The release is tagged at `HEAD`, with notes from `docs/releases/v<version>.md`. The script refuses to publish with uncommitted sources or missing notes.
- `McpProtocolHandler.serverVersion` uses `AppConstants.appVersion`, and `test/unit/app_version_test.dart` compares it with `pubspec.yaml`.
- [release-guide.md](../release-guide.md) documents the full procedure, including the README link rule and a dry run (`--no-push --no-gh-release`).

## 5. Prevention & Reusability Checklist

- [ ] A script that deletes files in a shared output folder matches only the files it created.
- [ ] Push `HEAD:<branch>` explicitly; never push a local ref the script did not just update.
- [ ] A `releases/latest/download/<asset>` link is valid only if every release has that asset; otherwise pin the tag.
- [ ] Keep one version source, or a test that compares every copy with it.
- [ ] Read a rarely run publishing script fully, and dry-run it, before the real run.

## Recurrence: Stale App Seal on an Incremental Release Build (2026-10-18)

- **Symptom:** the first real run stopped at `codesign --verify --deep --strict`: *"nested code is modified or invalid"*, `file modified: …/Contents/MacOS/azdroid-mcp`. The two runs before it had passed.
- **Evidence:** `_CodeSignature/CodeResources` and the main binary were from the previous build (17:54); `azdroid-mcp` was from this one (18:01).
- **Cause:** the "Embed MCP Server" phase is always out of date and recompiles `azdroid-mcp` on every build, but Xcode re-signs the app only when its own binary changes. Earlier runs passed because the Dart code had changed each time.
- **Fix:** `build_release.sh` deletes `Azdroid.app` before `flutter build macos --release`; two back-to-back dry runs now pass.
- [ ] A build phase that rewrites files inside a signed bundle must run before the bundle is sealed, or the release must start from no bundle.

