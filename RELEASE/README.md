# ⚡️ DeskDroid — Official Production Releases

> High-performance Android screen mirroring & developer workstation for macOS over Wi-Fi & USB.

---

## 📥 Current Release: v1.0.0 (Build 1)

| Asset | Platform | File Size | SHA-256 Checksum |
| :--- | :--- | :--- | :--- |
| **[`DeskDroid-v1.0.0-macOS.zip`](DeskDroid-v1.0.0-macOS.zip)** | macOS 12.0+ (Apple Silicon & Intel) | `18M` | `275852887a1a5d12aef8494e5a4e583009282e99aa3953779e220a1efeddcf6b` |
| **[`DeskDroid-macOS-latest.zip`](DeskDroid-macOS-latest.zip)** | macOS 12.0+ (Latest Snapshot) | `18M` | `275852887a1a5d12aef8494e5a4e583009282e99aa3953779e220a1efeddcf6b` |

---

## 🚀 Installation Guide (macOS)

1. Download **[`DeskDroid-v1.0.0-macOS.zip`](DeskDroid-v1.0.0-macOS.zip)** from this directory or the [GitHub Releases](https://github.com/az-coder-123/desk-droid/releases) page.
2. Unzip the archive by double-clicking it in macOS Finder or running:
   ```bash
   unzip DeskDroid-v1.0.0-macOS.zip
   ```
3. Drag **DeskDroid.app** into your `/Applications` folder.
4. Ensure **ADB (Android Debug Bridge)** is installed on your Mac:
   ```bash
   brew install android-platform-tools
   ```

### 🛡️ macOS Gatekeeper Security Note (Unsigned Builds)
Because DeskDroid is open-source and not signed with an Apple Developer Program ID, macOS Gatekeeper may prompt: *"DeskDroid cannot be opened because the developer cannot be verified"*.

To allow DeskDroid to run seamlessly, run this one-time command in macOS Terminal:
```bash
xattr -cr /Applications/DeskDroid.app
```
Or right-click **DeskDroid.app** in Finder, choose **Open**, and click **Open** on the confirmation dialog.

---

## 🔒 Verification
To verify the integrity of your downloaded release archive:
```bash
shasum -a 256 -c SHA256SUMS.txt
```
