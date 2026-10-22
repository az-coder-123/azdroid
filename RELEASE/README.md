# Azdroid Release Packages

> Android screen mirroring and control for macOS and Windows, over Wi-Fi and USB. All releases and notes: [GitHub Releases](https://github.com/az-coder-123/azdroid/releases).

## Packages

| Package | Platform | Version | Size | SHA-256 |
| :--- | :--- | :--- | :--- | :--- |
| **[\$(@{Zip=Azdroid-v1.4.0-macOS.zip; Version=v1.4.0; Size=31M; Sha=e74d5cb9dcbb58e5e5ce2515cda186d0b9da71b257ca9052812a8c1e7da99b51}.Zip)\](Azdroid-v1.4.0-macOS.zip)** | macOS 12.0+ (Apple Silicon & Intel) | v1.4.0 | \$(@{Zip=Azdroid-v1.4.0-macOS.zip; Version=v1.4.0; Size=31M; Sha=e74d5cb9dcbb58e5e5ce2515cda186d0b9da71b257ca9052812a8c1e7da99b51}.Size)\ | \$(@{Zip=Azdroid-v1.4.0-macOS.zip; Version=v1.4.0; Size=31M; Sha=e74d5cb9dcbb58e5e5ce2515cda186d0b9da71b257ca9052812a8c1e7da99b51}.Sha)\ |
| **[\$(@{Zip=Azdroid-v1.4.0-Windows-x64.zip; Version=v1.4.0; Size=25M; Sha=0d277110769c7c886fc70b40fac327b55e680eca6f82b112f92f76df5fe6d869}.Zip)\](Azdroid-v1.4.0-Windows-x64.zip)** | Windows 10/11 x64 (Preview) | v1.4.0 | \$(@{Zip=Azdroid-v1.4.0-Windows-x64.zip; Version=v1.4.0; Size=25M; Sha=0d277110769c7c886fc70b40fac327b55e680eca6f82b112f92f76df5fe6d869}.Size)\ | \$(@{Zip=Azdroid-v1.4.0-Windows-x64.zip; Version=v1.4.0; Size=25M; Sha=0d277110769c7c886fc70b40fac327b55e680eca6f82b112f92f76df5fe6d869}.Sha)\ |

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

