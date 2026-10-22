# Azdroid Release Packages

> Android screen mirroring and control for macOS and Windows, over Wi-Fi and USB. All releases and notes: [GitHub Releases](https://github.com/az-coder-123/azdroid/releases).

## Packages

| Package | Platform | Version | Size | SHA-256 |
| :--- | :--- | :--- | :--- | :--- |
| **[`Azdroid-v1.4.0-macOS.zip`](Azdroid-v1.4.0-macOS.zip)** | macOS 12.0+ (Apple Silicon & Intel) | v1.4.0 | `31M` | `e74d5cb9dcbb58e5e5ce2515cda186d0b9da71b257ca9052812a8c1e7da99b51` |
| **[`Azdroid-v1.3.0-Windows-x64.zip`](Azdroid-v1.3.0-Windows-x64.zip)** | Windows 10/11 x64 (Preview) | v1.3.0 | `24M` | `868b7faa99c53c35e35610a87048abfdc793f20865706646fe7fa8b99d22f1ba` |

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
