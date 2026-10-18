# Installation & Building (macOS & Windows)

> Install a release build, set up ADB, run from source, and package a release on each platform. Feature status per platform: [platform-support.md](platform-support.md).

---

## 1. Requirements

| | macOS | Windows |
|:---|:---|:---|
| Host | macOS 12.0+, Apple Silicon or Intel | Windows 10/11 x64 |
| Android | 5.0+ with **USB debugging** enabled | Same |
| ADB | Required | Required |
| scrcpy / ffmpeg | Not needed (`scrcpy-server.jar` is bundled) | Not needed |

---

## 2. Install a Release Build

Download the ZIP for your platform from [GitHub Releases](https://github.com/az-coder-123/desk-droid/releases).

### macOS

1. Unzip `DeskDroid-v<version>-macOS.zip` and drag **DeskDroid.app** into `/Applications`.
2. The build is not signed with an Apple Developer ID. If Gatekeeper blocks it, run once:
   ```bash
   xattr -cr /Applications/DeskDroid.app
   ```
   Or right-click the app, choose **Open**, then **Open** again.

### Windows (Preview)

1. Unzip `DeskDroid-v<version>-Windows-x64.zip` to a folder you own, for example `%LOCALAPPDATA%\Programs\DeskDroid`. There is no installer; the folder is the app.
2. Run `DeskDroid\desk_droid.exe`. Keep all files in the folder together: the `.dll` files and the `data` folder are required. The folder also contains `adb.exe` and the MCP server `deskdroid-mcp.exe`, so nothing else has to be installed; an adb you install yourself takes precedence ([details](bundled-platform-tools.md#3-which-adb-is-used)).
3. The build is not code-signed. If SmartScreen shows *"Windows protected your PC"*, click **More info**, then **Run anyway**.
4. If Windows reports a missing `VCRUNTIME140.dll` or `MSVCP140.dll`, install the [Microsoft Visual C++ Redistributable (x64)](https://aka.ms/vs/17/release/vc_redist.x64.exe). Release ZIPs normally include these DLLs.

---

## 3. Install ADB

DeskDroid finds ADB automatically; details of the lookup order are in [platform-support.md](platform-support.md#3-platform-differences).

| Platform | Command | Notes |
|:---|:---|:---|
| macOS | `brew install android-platform-tools` | Or use the Android Studio SDK (`~/Library/Android/sdk`). |
| Windows | `winget install Google.PlatformTools` | Or use the Android Studio SDK (`%LOCALAPPDATA%\Android\Sdk`). Reopen DeskDroid after installing so it sees the new `PATH`. |

Check the installation with `adb version`. On Windows, a USB connection may also need the [Google USB Driver](https://developer.android.com/studio/run/win-usb) or your phone maker's driver.

Each computer has its own ADB key, so the phone asks to **Allow USB debugging** once per computer. See [troubleshooting.md](troubleshooting.md#-device-status-shows-unauthorized).

---

## 4. Run from Source

Requires the [Flutter SDK](https://docs.flutter.dev/get-started/install) with desktop support. Windows also needs **Visual Studio 2022** with the *Desktop development with C++* workload.

```bash
git clone https://github.com/az-coder-123/desk-droid.git
cd desk-droid
flutter pub get
flutter run -d macos     # on a Mac
flutter run -d windows   # on a Windows PC
```

---

## 5. Package a Release

To publish a release (version, notes, upload, README links), follow [release-guide.md](release-guide.md).

Both scripts read the version from `pubspec.yaml`, run `flutter analyze` and `flutter test`, build the release, and write a ZIP plus SHA-256 checksums to `RELEASE/`.

| | macOS | Windows |
|:---|:---|:---|
| Command | `./scripts/build_release.sh` | `powershell -ExecutionPolicy Bypass -File scripts\build_release.ps1` |
| Output | `RELEASE/DeskDroid-v<version>-macOS.zip`, `SHA256SUMS.txt`, `RELEASE/README.md` | `RELEASE\DeskDroid-v<version>-Windows-x64.zip`, `SHA256SUMS-windows.txt` |
| Skip checks | `--skip-tests` | `-SkipTests` |
| Publish | Commits `RELEASE/`, fast-forwards `origin/main`, and creates a GitHub Release with `docs/releases/v<version>.md` **by default** (`--no-push`, `--no-gh-release` to skip) | Never commits or pushes; `-Publish` uploads the ZIP to the GitHub Release `v<version>` with `gh` |

The Windows script fetches the bundled adb first (`dart run tool/fetch_platform_tools.dart --os=windows`, see [bundled-platform-tools.md](bundled-platform-tools.md)), and the release build compiles `deskdroid-mcp.exe`. Before zipping, it checks that the packaged `adb.exe` runs and that `deskdroid-mcp.exe` answers `tools/list`, so the ZIP works on a PC without adb, Flutter, or Dart.

The Windows script also copies the Visual C++ runtime DLLs into the package when Visual Studio has the redistributable files installed (`VC\Redist\MSVC\<version>\x64\Microsoft.VC143.CRT`). Without them it prints a warning, and users may need the redistributable from section 2.

Verify a download:

```bash
shasum -a 256 -c SHA256SUMS.txt                       # macOS
```

```powershell
Get-FileHash -Algorithm SHA256 DeskDroid-v<version>-Windows-x64.zip   # Windows; compare with SHA256SUMS-windows.txt
```
