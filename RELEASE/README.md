# DeskDroid Release Packages

> Android screen mirroring and control for macOS and Windows, over Wi-Fi and USB. All releases and notes: [GitHub Releases](https://github.com/az-coder-123/desk-droid/releases).

## Packages

| Package | Platform | Version | Size | SHA-256 |
| :--- | :--- | :--- | :--- | :--- |
| **[`DeskDroid-v1.3.0-macOS.zip`](DeskDroid-v1.3.0-macOS.zip)** | macOS 12.0+ (Apple Silicon & Intel) | v1.3.0 | `31M` | `75b9c93328f4c6a72592ed8a2df74639df618a960ae816f6ec518f3f3fb98043` |
| **[`DeskDroid-v1.3.0-Windows-x64.zip`](DeskDroid-v1.3.0-Windows-x64.zip)** | Windows 10/11 x64 (Preview) | v1.3.0 | `21M` | `8bc7452f84af1419e2e290f7c8cedec904e50e4f48fd4b1504b189d56ea48a96` |

Each `*-latest.zip` file is a copy of the newest package for its platform.

ADB and scrcpy-server are bundled. An ADB you install yourself takes precedence over the bundled one.

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
