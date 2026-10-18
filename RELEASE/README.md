# DeskDroid Release Packages

> Android screen mirroring and control for macOS and Windows, over Wi-Fi and USB. All releases and notes: [GitHub Releases](https://github.com/az-coder-123/desk-droid/releases).

## Packages

| Package | Platform | Version | Size | SHA-256 |
| :--- | :--- | :--- | :--- | :--- |
| **[`DeskDroid-v1.1.0-macOS.zip`](DeskDroid-v1.1.0-macOS.zip)** | macOS 12.0+ (Apple Silicon & Intel) | v1.1.0 | `30M` | `631e16b8253e88c598553afee69adec2aa15a29c28962135456a5410018ce75c` |
| **[`DeskDroid-v1.0.1-Windows-x64.zip`](DeskDroid-v1.0.1-Windows-x64.zip)** | Windows 10/11 x64 (Preview) | v1.0.1 | `13M` | `e36d0596a0294723f87653bc58e4835c9fabbb601817311e667686fd9502607d` |

Each `*-latest.zip` file is a copy of the newest package for its platform.

ADB and scrcpy-server are bundled. Exception: the Windows v1.0.1 package has no ADB; install it first (`winget install Google.PlatformTools`).

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
