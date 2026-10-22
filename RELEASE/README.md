# Azdroid Release Packages

> Android screen mirroring and control for macOS and Windows, over Wi-Fi and USB. All releases and notes: [GitHub Releases](https://github.com/az-coder-123/azdroid/releases).

## Packages

| Package | Platform | Version | Size | SHA-256 |
| :--- | :--- | :--- | :--- | :--- |
| **[`Azdroid-v1.4.1-macOS.zip`](Azdroid-v1.4.1-macOS.zip)** | macOS 12.0+ (Apple Silicon & Intel) | v1.4.1 | `31M` | `d060a38cce01a299fd3299a77ac6331a3ee2d8deb232aaf48bed3eff8ee1b7e8` |
| **[`Azdroid-v1.4.0-Windows-x64.zip`](Azdroid-v1.4.0-Windows-x64.zip)** | Windows 10/11 x64 (Preview) | v1.4.0 | `25M` | `0d277110769c7c886fc70b40fac327b55e680eca6f82b112f92f76df5fe6d869` |

Each `*-latest.zip` file is a copy of the newest package for its platform.

ADB and scrcpy-server are bundled. An ADB you install yourself takes precedence over the bundled one.

## Install on macOS

1. Unzip the macOS package and drag **Azdroid.app** into `/Applications`.
2. The app is not signed with an Apple Developer ID. If macOS says the developer cannot be verified, run once:
   ```bash
   xattr -cr /Applications/Azdroid.app
   ```
   Or right-click the app, choose **Open**, then **Open** again.

## Install on Windows (Preview)

1. Unzip the Windows package to a folder you own, for example `%LOCALAPPDATA%\Programs\Azdroid`.
2. Run `desk_droid.exe`. Keep the `.dll` files and the `data` folder next to it.
3. The app is not code-signed. If SmartScreen appears, click **More info**, then **Run anyway**.

## Verify a Download

```bash
shasum -a 256 -c SHA256SUMS.txt          # macOS package
shasum -a 256 -c SHA256SUMS-windows.txt  # Windows package
```
