# ⚡️ DeskDroid — High-Performance Android Screen Mirroring & Workstation for macOS

<p align="center">
  <b>Silky-smooth, low-latency (<20ms) Android screen mirroring, remote control, and developer powerhouse for macOS over Wi-Fi & USB. Built with Flutter Desktop and scrcpy-server.</b>
</p>

<p align="center">
  <a href="https://github.com/az-coder-123/desk-droid/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT"></a>
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/built%20with-Flutter-02569B.svg?logo=flutter" alt="Built with Flutter"></a>
  <a href="https://github.com/az-coder-123/desk-droid/releases"><img src="https://img.shields.io/badge/platform-macOS%20%7C%20Apple%20Silicon%20%26%20Intel-black.svg?logo=apple" alt="macOS Platform"></a>
  <a href="https://github.com/az-coder-123/desk-droid/stargazers"><img src="https://img.shields.io/badge/scrcpy-v3.1-orange.svg" alt="scrcpy v3.1 Engine"></a>
  <a href="https://github.com/az-coder-123/desk-droid/pulls"><img src="https://img.shields.io/badge/PRs-welcome-brightgreen.svg" alt="PRs Welcome"></a>
</p>

<p align="center">
  <a href="https://github.com/az-coder-123/desk-droid/releases/latest/download/DeskDroid-v1.0.0-macOS.zip"><img src="https://img.shields.io/badge/Download_for_macOS-v1.0.0_(Universal)-007AFF?style=for-the-badge&logo=apple&logoColor=white" alt="Download DeskDroid for macOS"></a>
  &nbsp;
  <a href="https://github.com/az-coder-123/desk-droid/tree/main/RELEASE"><img src="https://img.shields.io/badge/All_Releases_%26_Checksums-gray?style=for-the-badge&logo=github&logoColor=white" alt="All Releases & Checksums"></a>
  <br>
  <sub>Universal Binary (18 MB) • Apple Silicon (M1/M2/M3/M4) & Intel Core • macOS 12.0+</sub>
</p>

<p align="center">
  <img src="docs/images/deskdroid_mirroring_workspace.png" alt="DeskDroid - Android screen mirroring workspace on macOS with low latency 60 FPS display and trackpad controls" width="580">
</p>

---

## 🚀 Why DeskDroid?

DeskDroid turns your Mac into the ultimate Android command center. Whether you are an Android developer debugging apps, a content creator recording mobile gameplay, or a power user seeking desktop control over your phone, DeskDroid delivers:

- ⚡️ **Sub-20ms Glass-to-Glass Latency:** Hardware-accelerated H.264/H.265 GPU encoding paired with Apple VideoToolbox native decoding up to 60–120 FPS.
- 📶 **Dual Connection (Wi-Fi & USB):** Subnet ARP auto-discovery, mDNS wireless debugging, 1-click USB-to-Wi-Fi switch, or instant plug-and-play USB cable mode.
- 🔋 **Screen-Off Streaming:** Keep the physical phone screen dark during mirroring to eliminate heat and save up to 70% battery.
- 🔒 **100% Private & P2P:** Zero cloud servers, zero analytics, and zero telemetry. All video, audio, and inputs remain strictly inside your local network.

---

## 📸 Visual Showcase

### 1. Subnet Discovery & Built-in Feature Catalog
<table>
  <tr>
    <td width="50%" align="center" valign="top">
      <img src="docs/images/deskdroid_device_discovery.png" alt="DeskDroid Multi-Device Subnet Discovery and Wireless Connection" width="100%">
      <br><b>Multi-Device Discovery</b>
      <br><sub>Subnet auto-scan, connection badges & 1-click wireless mirroring.</sub>
    </td>
    <td width="50%" align="center" valign="top">
      <img src="docs/images/deskdroid_features_showcase.png" alt="DeskDroid Built-in Feature Showcase and Interactive Catalog" width="100%">
      <br><b>Interactive Feature Showcase</b>
      <br><sub>Categorized catalog with performance badges, highlights & pro tips.</sub>
    </td>
  </tr>
</table>

### 2. Developer Inspection: Logcat & Intent Dispatcher
<table>
  <tr>
    <td width="50%" align="center" valign="top">
      <img src="docs/images/deskdroid_logcat_console.png" alt="DeskDroid Real-Time Logcat Console with Multi-Tier Filters" width="100%">
      <br><b>Device Logcat Console (<kbd>Cmd</kbd>+<kbd>Shift</kbd>+<kbd>L</kbd>)</b>
      <br><sub>Live 60 FPS stream, 5k ring buffer, regex/PID/tag filters, star bookmarks & export.</sub>
    </td>
    <td width="50%" align="center" valign="top">
      <img src="docs/images/deskdroid_intent_dispatcher.png" alt="DeskDroid Deep Link Tester and Android Intent Dispatcher" width="100%">
      <br><b>Deep Link & Intent Dispatcher (<kbd>Cmd</kbd>+<kbd>Shift</kbd>+<kbd>D</kbd>)</b>
      <br><sub>Fire custom URI schemes, system actions, targeted packages & typed extras.</sub>
    </td>
  </tr>
</table>

### 3. App Deployment & Two-Way File Management
<table>
  <tr>
    <td width="50%" align="center" valign="top">
      <img src="docs/images/deskdroid_apk_installer.png" alt="DeskDroid 1-Click APK Sideload and Package Manager" width="100%">
      <br><b>1-Click APK Manager (<kbd>Cmd</kbd>+<kbd>Shift</kbd>+<kbd>I</kbd>)</b>
      <br><sub>AAPT2 metadata inspection, permission grant flags, 1-click launch & clean uninstall.</sub>
    </td>
    <td width="50%" align="center" valign="top">
      <img src="docs/images/deskdroid_file_explorer.png" alt="DeskDroid Finder-Style Android File Explorer" width="100%">
      <br><b>Device File Explorer (<kbd>Cmd</kbd>+<kbd>Shift</kbd>+<kbd>F</kbd>)</b>
      <br><sub>Finder-style two-way file browser with quick folder shortcuts & batch download.</sub>
    </td>
  </tr>
</table>

### 4. Lossless Media Capture & Screen Recording
<table>
  <tr>
    <td width="50%" align="center" valign="top">
      <img src="docs/images/deskdroid_screen_recording.png" alt="DeskDroid Hardware Screen Recording HUD" width="100%">
      <br><b>Hardware Screen Recording (<kbd>Cmd</kbd>+<kbd>Shift</kbd>+<kbd>R</kbd>)</b>
      <br><sub>Cinema-grade MP4 video encoded directly on phone GPU with 3s countdown HUD.</sub>
    </td>
    <td width="50%" align="center" valign="top">
      <img src="docs/images/deskdroid_area_crop.png" alt="DeskDroid Interactive Area Screenshot Crop Marquee" width="100%">
      <br><b>Interactive Area Crop (<kbd>Cmd</kbd>+<kbd>Shift</kbd>+<kbd>S</kbd>)</b>
      <br><sub>Lossless marquee crop with live pixel badge & auto-copy to Mac pasteboard.</sub>
    </td>
  </tr>
</table>

---

## ⚡️ Complete Feature Catalog

DeskDroid includes **13 built-in modules** engineered for speed, reliability, and developer productivity:

| # | Feature | Highlights & Capabilities | Shortcut | Docs |
| :-: | :--- | :--- | :--- | :-: |
| **01** | **Wireless Display & Low-Latency Streaming** | 60–120 FPS, <20ms latency, Apple VideoToolbox H.264/H.265 hardware decoding | Auto | [Guide](docs/features/wireless-display-streaming.md) |
| **02** | **Device Discovery & Wireless Pairing** | Subnet ARP scan, 1-click USB-to-Wi-Fi, mDNS discovery for Android 11+ pairing | Auto / Toolbar | [Guide](docs/features/device-discovery-pairing.md) |
| **03** | **Remote Input & Gesture Control** | Mac trackpad gestures, smooth inertial scrolling, right-click back, multi-touch | Mouse / Trackpad | [Guide](docs/features/remote-input-control.md) |
| **04** | **Universal Keyboard & Text Injection** | Native Mac keyboard shortcuts, Unicode & IME international text input modal | <kbd>Cmd</kbd>+<kbd>K</kbd> | [Guide](docs/features/remote-input-control.md) |
| **05** | **Screen-Off Streaming** | Powers down phone screen while streaming to eliminate heat and save 70% battery | <kbd>Cmd</kbd>+<kbd>O</kbd> | [Guide](docs/features/screen-off-streaming.md) |
| **06** | **Device Logcat Console & Debugger** | 60 FPS live stream, 5k ring buffer, regex/PID/tag filters, star bookmarks, export | <kbd>Cmd</kbd>+<kbd>Shift</kbd>+<kbd>L</kbd> | [Guide](docs/features/device-logcat-console.md) |
| **07** | **Deep Link & Intent Dispatcher** | Test URI schemes, system actions (`VIEW`, `SEND`), packages & typed extras | <kbd>Cmd</kbd>+<kbd>Shift</kbd>+<kbd>D</kbd> | [Guide](docs/features/deep-link-intent-dispatcher.md) |
| **08** | **APK Sideload & Package Manager** | AAPT2 package inspection, install flags (`-r`, `-g`, `-t`), launch & uninstall | <kbd>Cmd</kbd>+<kbd>Shift</kbd>+<kbd>I</kbd> | [Guide](docs/features/apk-sideload-manager.md) |
| **09** | **Finder-Style File Explorer** | Two-way file manager, quick folders (Downloads, DCIM, Docs) & Mac download | <kbd>Cmd</kbd>+<kbd>Shift</kbd>+<kbd>F</kbd> | [Guide](docs/features/file-transfer-explorer.md) |
| **10** | **Viewport Drag & Drop Push** | Drag any file or APK onto the mirroring window for instant push or sideload | Drag-and-drop | [Guide](docs/features/file-transfer-explorer.md) |
| **11** | **Bidirectional Clipboard Sync** | Real-time Mac pasteboard (`⌘C`) ⇄ Android clipboard with loop prevention | <kbd>Cmd</kbd>+<kbd>C</kbd> / <kbd>V</kbd> | [Guide](docs/features/clipboard-sync.md) |
| **12** | **Hardware MP4 Screen Recording** | Lossless MP4 video encoded on phone GPU, 3s countdown HUD, live timer | <kbd>Cmd</kbd>+<kbd>Shift</kbd>+<kbd>R</kbd> | [Guide](docs/features/hardware-screen-recording.md) |
| **13** | **Lossless Screenshots & Area Crop** | Full display capture or interactive 8-handle marquee crop saved to `~/Downloads` | <kbd>Cmd</kbd>+<kbd>S</kbd> / <kbd>Shift</kbd>+<kbd>S</kbd> | [Guide](docs/features/screenshots-area-crop.md) |
| **+** | **macOS Menu Bar Companion** | Status bar popover for quick window toggle and live telemetry (FPS & latency) | Menu Bar | [Guide](docs/features/menu-bar-companion.md) |

---

## ⌨️ Essential Keyboard Shortcuts

| Shortcut | Action | Description |
| :--- | :--- | :--- |
| <kbd>Cmd</kbd> + <kbd>S</kbd> | Full Screenshot | Captures full phone screen to `~/Downloads` & macOS clipboard |
| <kbd>Cmd</kbd> + <kbd>Shift</kbd> + <kbd>S</kbd> | Area Screenshot | Drag interactive marquee to crop custom screen region |
| <kbd>Cmd</kbd> + <kbd>Shift</kbd> + <kbd>R</kbd> | Screen Recording | Lossless hardware MP4 recording with countdown HUD & timer |
| <kbd>Cmd</kbd> + <kbd>Shift</kbd> + <kbd>I</kbd> | APK Manager | Inspect package metadata, configure install flags & sideload |
| <kbd>Cmd</kbd> + <kbd>Shift</kbd> + <kbd>D</kbd> | Intent Dispatcher | Fire deep link URLs, system intents & typed extras |
| <kbd>Cmd</kbd> + <kbd>Shift</kbd> + <kbd>F</kbd> | Device Files | Browse phone directories & download files to Mac |
| <kbd>Cmd</kbd> + <kbd>Shift</kbd> + <kbd>L</kbd> | Device Logcat | Real-time log stream with level/tag/PID filtering & export |
| <kbd>Cmd</kbd> + <kbd>O</kbd> | Screen-Off Toggle | Power down physical phone screen to reduce heat and save battery |
| <kbd>Cmd</kbd> + <kbd>K</kbd> | Text Injection | Open Unicode & international IME text input modal |
| <kbd>Cmd</kbd> + <kbd>H</kbd> / <kbd>Backspace</kbd> | Home / Back | Standard Android navigation controls |

---

## 🏗️ Architecture

```mermaid
flowchart LR
    subgraph AndroidDevice ["📱 Android Device"]
        A1["SurfaceControl / Display Capture"] --> A2["MediaCodec (H.264 / H.265 GPU)"]
        A2 --> A3["scrcpy-server (Shell-level daemon)"]
        A4["InputManager (Touch / Key Injection)"] <--- A3
    end

    subgraph Transport ["📶 Local Wi-Fi (LAN) / 🔌 USB Cable"]
        V_STREAM["TCP Video Stream (Raw NAL Units)"]
        C_SOCKET["TCP / UDP Control Events (Input Packets)"]
    end

    subgraph MacApp ["💻 macOS (DeskDroid App - Flutter)"]
        M1["Flutter UI & Menu Bar"] --> M2["Mouse & Keyboard Event Listener"]
        M3["Hardware Video Decoder (Texture Registry)"] --> M1
    end

    A3 === V_STREAM ===> M3
    M2 === C_SOCKET ===> A3
```

---

## 🛠️ Quick Start & Installation

### Prerequisites
- macOS 12.0+ (Apple Silicon M1/M2/M3/M4 or Intel Core)
- Android 5.0+ (Lollipop or higher) with **USB Debugging** enabled
- ADB installed on Mac (`brew install android-platform-tools`)

```bash
# 1. Clone repository
git clone https://github.com/az-coder-123/desk-droid.git
cd desk-droid

# 2. Install dependencies & launch
flutter pub get
flutter run -d macos
```

---

## 📚 Documentation Hub

| Guide | Scope |
| :--- | :--- |
| [📖 User Guide](docs/user-guide.md) | Getting started, first-time setup, and device permissions |
| [📶 Pairing Guide](docs/pairing-guide.md) | Wireless pairing instructions for Android 11+ and USB fallback |
| [⌨️ Shortcuts & Gestures](docs/shortcuts.md) | Complete mouse gestures and macOS keyboard shortcuts cheat sheet |
| [⚡️ Features Catalog](docs/features/README.md) | Modular in-depth documentation across all 13 built-in features |
| [🏛️ Architecture](docs/architecture.md) | Clean Architecture blueprint, BLoC state model, and socket protocols |
| [🛠️ Troubleshooting](docs/troubleshooting.md) | Solutions for Xiaomi/MIUI input permissions, firewalls, and ADB errors |
| [💡 Lessons Learned](docs/lessons-learned/README.md) | Engineering post-mortems, root cause analyses, and edge-case solutions |

---

## 🏷️ Search Keywords & Tags

`android-screen-mirroring` · `scrcpy-macos-gui` · `wireless-adb` · `screen-mirror-mac` · `flutter-desktop` · `apple-silicon` · `android-logcat-gui` · `apk-installer-mac` · `deep-link-tester` · `android-file-transfer-mac` · `low-latency-streaming` · `open-source`

---

## 🤝 Community, Contributing & License

<table>
  <tr>
    <td width="50%" valign="top">
      <h3>🤝 Contributing</h3>
      <p>Contributions, feature requests, and bug reports are warmly welcome! DeskDroid thrives on community feedback.</p>
      <p>
        <a href="https://github.com/az-coder-123/desk-droid/issues"><img src="https://img.shields.io/badge/Issues-Report%20Bug-red?style=flat-square&logo=github" alt="Report Bug"></a>
        <a href="https://github.com/az-coder-123/desk-droid/pulls"><img src="https://img.shields.io/badge/PRs-Welcome-brightgreen?style=flat-square&logo=git" alt="PRs Welcome"></a>
        <a href="https://github.com/az-coder-123/desk-droid/stargazers"><img src="https://img.shields.io/badge/Star-DeskDroid-yellow?style=flat-square&logo=github" alt="Star DeskDroid"></a>
      </p>
      <ul>
        <li>Found a bug? Submit a detailed <a href="https://github.com/az-coder-123/desk-droid/issues/new">GitHub Issue</a>.</li>
        <li>Have a feature idea? Share it in <a href="https://github.com/az-coder-123/desk-droid/issues">Feature Requests</a>.</li>
        <li>Want to contribute code? Fork, branch, and open a Pull Request.</li>
      </ul>
    </td>
    <td width="50%" valign="top">
      <h3>📄 License & Freedom</h3>
      <p>DeskDroid is 100% free, open-source, and privacy-respecting software released under the <b>MIT License</b>.</p>
      <p>
        <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue?style=flat-square" alt="MIT License"></a>
        <img src="https://img.shields.io/badge/Privacy-100%25%20P2P-success?style=flat-square" alt="100% P2P">
        <img src="https://img.shields.io/badge/Telemetry-Zero-lightgrey?style=flat-square" alt="Zero Telemetry">
      </p>
      <p>You are free to use, modify, distribute, and integrate this software into personal or commercial workflows. See <a href="LICENSE">LICENSE</a> for full legal terms.</p>
    </td>
  </tr>
</table>

<p align="center">
  Developed and maintained by <b><a href="https://github.com/az-coder-123">az-coder-123</a></b>
</p>
