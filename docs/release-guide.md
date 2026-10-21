# Release Guide (Build, Package, Upload, README)

> Step-by-step procedure to publish a Azdroid release. Written so that a maintainer or an AI assistant can follow it as is. Install and packaging options per platform: [installation.md](installation.md#5-package-a-release).

---

## 1. Overview

| Step | What | Where |
|:---|:---|:---|
| 1 | Choose the version | `pubspec.yaml`, `AppConstants.appVersion` |
| 2 | Write the release notes | `docs/releases/v<version>.md` |
| 3 | Update README download links | `README.md` |
| 4 | Verify and commit the sources | `flutter analyze`, `flutter test` |
| 5 | Build, package, upload (macOS) | `./scripts/build_release.sh` |
| 6 | Build and upload Windows (optional) | `scripts\build_release.ps1 -Publish` on a Windows PC |
| 7 | Check the published release | GitHub Releases page, README links |

Outputs live in `RELEASE/` (committed): versioned ZIPs, `*-latest.zip` copies, `SHA256SUMS*.txt`, and `RELEASE/README.md`.

**Prerequisites (macOS):** Flutter SDK, Xcode, `gh` logged in (`gh auth status`) with push rights, network access (the script downloads Platform-Tools when missing).

---

## 2. Choose the Version

Use [Semantic Versioning](https://semver.org): `MAJOR.MINOR.PATCH`.

- **PATCH** (1.1.0 → 1.1.1): bug fixes only.
- **MINOR** (1.0.1 → 1.1.0): new features, nothing removed.
- **MAJOR**: a breaking change for users (removed features, new minimum OS).

Change both places to the same name, and increase the build number after `+` by one:

```yaml
# pubspec.yaml
version: 1.1.0+3
```
```dart
// lib/core/constants/app_constants.dart (the MCP server reports it too)
static const String appVersion = '1.1.0';
```

`test/unit/app_version_test.dart` fails if the two differ.

---

## 3. Write the Release Notes

Create `docs/releases/v<version>.md`. The script uploads it as the GitHub Release description and stops if it is missing. Collect the changes with:

```bash
git log --oneline v<previous-version>..HEAD | grep -E '^[0-9a-f]+ (feat|fix)'
```

Use these sections: **New**, **Improved**, **Known Limitations**, **Verify the Download**. Copy [v1.1.0.md](releases/v1.1.0.md) as a template.

Rules:
- State only what the code does and what was verified. Do not add latency numbers, tool counts, or platform claims without a check ([lesson](lessons-learned/docs-claims-without-code.md)).
- If a platform has no package in this release, say so and link the latest release that has one.

---

## 4. Update README.md

The download buttons are near the top of `README.md`, and the install lines are in the **Install** section.

| Item | Rule |
|:---|:---|
| macOS button | `https://github.com/az-coder-123/azdroid/releases/latest/download/Azdroid-v<version>-macOS.zip`, badge text `v<version>_(Universal)` |
| Windows button | Use `/releases/latest/download/…` **only** if the latest release has a Windows asset. Otherwise pin the release that has it: `/releases/download/v<old>/Azdroid-v<old>-Windows-x64.zip`. A `latest` link to a missing asset returns 404. |
| Size line under the buttons | The ZIP size from a dry run (`./scripts/build_release.sh --no-push --no-gh-release`, then `ls -lh RELEASE/*.zip`). The real run rebuilds the same sources, so the size matches. |
| Install section | File names `Azdroid-v<version>-macOS.zip` and the Windows name actually offered. |
| scrcpy badge | Only when the bundled server changes (guarded by `scrcpy_server_version_test.dart`). |

Find every old version string first:

```bash
grep -rn '<old-version>' README.md docs/installation.md docs/platform-support.md
```

---

## 5. Verify and Commit the Sources

```bash
dart format .
flutter analyze        # must print "No issues found!"
flutter test           # must pass
git add -A && git commit -m "chore(release): prepare v<version>"
```

The release script refuses to publish while anything outside `RELEASE/` is uncommitted, so that the tag matches reviewed sources.

---

## 6. Build, Package, and Upload (macOS)

```bash
./scripts/build_release.sh
```

| Stage | What the script does | Stops when |
|:---|:---|:---|
| Checks | `flutter analyze`, `flutter test` (skip with `--skip-tests`) | A warning or failing test |
| Build | Fetches Platform-Tools (checksum-verified), deletes the old `Azdroid.app` (so the app is always re-signed), `flutter build macos --release` | Build error |
| Bundle checks | Bundled `adb` runs, `codesign --verify --deep --strict`, `azdroid-mcp` answers `tools/list` | Any check fails |
| Package | `ditto` ZIP, `-latest` copy, `SHA256SUMS.txt`; deletes older **macOS** ZIPs only | — |
| Describe | `scripts/release/write_release_readme.sh` writes `RELEASE/README.md` for every platform with a checksum file | No checksum file |
| Commit and push | Commits `RELEASE/`, `git push origin HEAD:main` (fast-forward only), pushes the current branch | Push rejected: run `git fetch`, rebase, rerun. Never force-push. |
| Upload | `gh release create v<version>` with the ZIP, `--notes-file docs/releases/v<version>.md`, tag at the release commit. If the release exists, re-uploads the ZIP (`--clobber`). | `gh` error |

Options: `--no-push` (build and package only), `--no-gh-release` (no upload). A dry run is `--no-push --no-gh-release`; it changes only `RELEASE/`.

Upload extra files to an existing release by hand:

```bash
gh release upload v<version> RELEASE/SHA256SUMS.txt --clobber
```

---

## 7. Windows Package (Optional)

On a Windows PC with Visual Studio 2022, after pulling the release commit:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\build_release.ps1 -Publish
```

Network access is required: the script downloads the pinned Platform-Tools when `vendor/platform-tools/windows` is missing. It writes `RELEASE\Azdroid-v<version>-Windows-x64.zip` (with `adb.exe` and `azdroid-mcp.exe`, both smoke-tested) and `SHA256SUMS-windows.txt` and uploads the ZIP to the release `v<version>`. It never commits. Commit `RELEASE/` from there, then rerun `scripts/release/write_release_readme.sh RELEASE` on any machine (bash) to list both platforms, and switch the README Windows button to `latest` (section 4).

Before uploading, test the ZIP on a clean Windows with Windows Sandbox (Windows 10/11 Pro or Enterprise; enable once with `Enable-WindowsOptionalFeature -Online -FeatureName Containers-DisposableClientVM -All` and restart):

```powershell
powershell -ExecutionPolicy Bypass -File scripts\test_in_windows_sandbox.ps1
```

It opens the newest ZIP in the sandbox, which has no Visual C++ runtime, adb, or Dart. `build\sandbox-results\smoke.txt` must show the MCP server's tool count, `App running ... True`, the runtime DLLs loaded from the app folder, and the bundled adb server. Then connect the phone over Wi-Fi (Direct IP) in the sandbox and mirror; the copied `azdroid_dart.log` and `scrcpy_stream.log` in the same folder show the result.

---

## 8. Check the Published Release

```bash
gh release view v<version> --json assets,url --jq '.url, .assets[].name'
curl -sIL https://github.com/az-coder-123/azdroid/releases/latest/download/Azdroid-v<version>-macOS.zip | grep -i '^http'
```

- Every README download button returns `200` after redirects (repeat the `curl` for the Windows link).
- Download the ZIP, unzip it outside the repository, open the app, and see your device in the list.
- `shasum -a 256 -c RELEASE/SHA256SUMS.txt` passes in `RELEASE/`.

---

## 9. Checklist

- [ ] `pubspec.yaml` and `AppConstants.appVersion` show the new version.
- [ ] `docs/releases/v<version>.md` written; claims checked against code.
- [ ] README buttons, size line, and install names updated; no 404 link.
- [ ] `flutter analyze` clean, `flutter test` passes, sources committed.
- [ ] `./scripts/build_release.sh` finished with "Completed Successfully".
- [ ] Release page shows the ZIP and the notes; the downloaded app starts.
