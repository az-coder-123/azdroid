# ⚡️ DeskDroid

<p align="center">
  <b>Silky-smooth, low-latency Android screen mirroring and developer workstation for macOS over Wi-Fi & USB.</b>
</p>

<p align="center">
  <a href="https://github.com/az-coder-123/desk-droid/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT"></a>
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/built%20with-Flutter-02569B.svg?logo=flutter" alt="Built with Flutter"></a>
  <a href="https://github.com/az-coder-123/desk-droid/releases"><img src="https://img.shields.io/badge/platform-macOS%20%7C%20Android-black.svg?logo=apple" alt="Platforms"></a>
  <a href="https://github.com/az-coder-123/desk-droid/pulls"><img src="https://img.shields.io/badge/PRs-welcome-brightgreen.svg" alt="PRs Welcome"></a>
</p>

<p align="center">
  <img src="docs/images/deskdroid_mirroring_workspace.png" alt="DeskDroid Live Mirroring Workspace on macOS" width="560">
</p>

---

## 📖 Overview

**DeskDroid** is an open-source desktop application crafted with **Flutter Desktop** for **macOS**. 

It enables users to **mirror an Android device screen onto a Mac and seamlessly interact with it using mouse and keyboard over local Wi-Fi or USB**—delivering glass-to-glass latency under 20ms and fluid refresh rates up to 60–120 FPS.

DeskDroid bridges two core principles:
1. **Unrivaled Performance:** Powered by the hardware-accelerated `scrcpy-server` engine (H.264/H.265 GPU encoding with Apple VideoToolbox hardware decoding).
2. **Native macOS Polish:** Packaged inside a modern Apple-native workstation crafted with Flutter and Clean Architecture.

---

## 📸 Visual Feature Tour

### 📱 1. Zero-Config Discovery & Feature Catalog

<table>
  <tr>
    <td width="50%" align="center" valign="top">
      <img src="docs/images/deskdroid_device_discovery.png" alt="Device Discovery Dashboard" width="100%">
      <br><b>Multi-Device Discovery</b>
      <br><sub>Subnet auto-scan, connection badges & 1-click wireless mirroring.</sub>
    </td>
    <td width="50%" align="center" valign="top">
      <img src="docs/images/deskdroid_features_showcase.png" alt="Built-in Feature Showcase" width="100%">
      <br><b>Interactive Feature Showcase</b>
      <br><sub>Categorized catalog with performance badges, highlights & pro tips.</sub>
    </td>
  </tr>
</table>

### 🛠️ 2. Developer Inspection & Deep Link Tools

<table>
  <tr>
    <td width="50%" align="center" valign="top">
      <img src="docs/images/deskdroid_logcat_console.png" alt="Device Logcat Console" width="100%">
      <br><b>Device Logcat Console (<kbd>Cmd</kbd>+<kbd>Shift</kbd>+<kbd>L</kbd>)</b>
      <br><sub>Live 60 FPS streaming, tag filters with module counts, bookmarks & export.</sub>
    </td>
    <td width="50%" align="center" valign="top">
      <img src="docs/images/deskdroid_intent_dispatcher.png" alt="Deep Link & Intent Dispatcher" width="100%">
      <br><b>Deep Link & Intent Dispatcher (<kbd>Cmd</kbd>+<kbd>Shift</kbd>+<kbd>D</kbd>)</b>
      <br><sub>Fire URI schemes, system actions, target packages & typed extras.</sub>
    </td>
  </tr>
</table>

### 📦 3. Sideloading & Two-Way File Management

<table>
  <tr>
    <td width="50%" align="center" valign="top">
      <img src="docs/images/deskdroid_apk_installer.png" alt="1-Click APK Sideload & Manager" width="100%">
      <br><b>1-Click APK Manager (<kbd>Cmd</kbd>+<kbd>Shift</kbd>+<kbd>I</kbd>)</b>
      <br><sub>Drag-and-drop installer, permission grant flags & error diagnosis.</sub>
    </td>
    <td width="50%" align="center" valign="top">
      <img src="docs/images/deskdroid_file_explorer.png" alt="Android File Explorer" width="100%">
      <br><b>Device File Explorer (<kbd>Cmd</kbd>+<kbd>Shift</kbd>+<kbd>F</kbd>)</b>
      <br><sub>Finder-style two-way browser with quick folder chips & batch download.</sub>
    </td>
  </tr>
</table>

### 🎬 4. Lossless Media Capture & Screen Recording

<table>
  <tr>
    <td width="50%" align="center" valign="top">
      <img src="docs/images/deskdroid_screen_recording.png" alt="Hardware Screen Recording HUD" width="100%">
      <br><b>Hardware Screen Recording (<kbd>Cmd</kbd>+<kbd>Shift</kbd>+<kbd>R</kbd>)</b>
      <br><sub>Cinema-grade MP4 encoding on phone GPU with 3s countdown HUD.</sub>
    </td>
    <td width="50%" align="center" valign="top">
      <img src="docs/images/deskdroid_area_crop.png" alt="Interactive Area Screenshot Crop" width="100%">
      <br><b>Interactive Area Crop (<kbd>Cmd</kbd>+<kbd>Shift</kbd>+<kbd>S</kbd>)</b>
      <br><sub>Lossless marquee crop with live pixel badge & auto-copy to Mac pasteboard.</sub>
    </td>
  </tr>
</table>

---

## ✨ Key Highlights

- 🚀 **Sub-20ms Glass-to-Glass Latency:** Hardware-accelerated GPU capture and encoding; streaming raw NAL units over a local TCP socket.
- 📶 **Zero-Config Wi-Fi Auto-Discovery & Dual-Mode Connectivity:** Automatically scans local Wi-Fi subnet via ARP cache and fast non-blocking TCP probing. Plug-and-play USB cable mode with 1-click wireless switching, automated mDNS discovery for Android 11+ Wireless Debugging, and manual Direct IP fallback.
- 🖱️ **Fluid Remote Input:** Precise mouse gestures, natural trackpad inertial scrolling, and direct international keyboard input (full Unicode and IME support).
- 🍎 **Mac-First Productivity & Developer Tools:**
  - **Bidirectional File Transfers & Explorer:** Send files/APKs via Finder sheet (<kbd>Cmd</kbd> + <kbd>U</kbd>) or drag-and-drop; browse phone storage and download files to Mac (<kbd>Cmd</kbd> + <kbd>Shift</kbd> + <kbd>F</kbd>).
  - **Professional APK Sideload & Manager:** Inspect metadata (App name, icon, package ID, version, SDKs), configure install flags (`-r`, `-g`, `-t`, `-d`), and 1-click launch or clean uninstall (<kbd>Cmd</kbd> + <kbd>Shift</kbd> + <kbd>I</kbd>).
  - **Deep Link & Intent Dispatcher:** Fire Android Intents, custom URL schemes, and deep links with 1-click presets (HTTPS Web, Play Store, Geo Maps, Tel dialer) and typed Intent Extras (`--es`, `--ei`, `--ez`) via <kbd>Cmd</kbd> + <kbd>Shift</kbd> + <kbd>D</kbd>.
  - **Real-Time Device Logcat Console:** Live logcat inspection with multi-tier filtering (Level `V/D/I/W/E/F`, Search, Regex, Tag, PID, and Tag Exclusions), preset profiles, line bookmarking, stack trace colorization, and snapshot export (<kbd>Cmd</kbd> + <kbd>Shift</kbd> + <kbd>L</kbd>).
  - **Lossless Screenshots (Full & Area Crop):** Capture full-screen (<kbd>Cmd</kbd> + <kbd>S</kbd>) or draggable area crop (<kbd>Cmd</kbd> + <kbd>Shift</kbd> + <kbd>S</kbd>), auto-saved to `~/Downloads` and copied to macOS clipboard (`⌘V`).
  - **Hardware Screen Recording:** Lossless MP4 video with countdown HUD & live timer (`REC 00:15`) via sidebar or <kbd>Cmd</kbd> + <kbd>Shift</kbd> + <kbd>R</kbd>.
  - **Two-Way Background Clipboard Synchronization:** Continuous background daemon synchronizes copied text between macOS pasteboard (`Cmd + C`) and Android clipboard without infinite feedback loops.
  - **Screen-Off Streaming:** Powers down the physical phone display during mirroring to reduce device heat by up to 70% and conserve battery.
  - **Menu Bar Companion:** Quick-access status bar popover for toggling device windows and monitoring latency, FPS, and connection health.
- 🔒 **100% Private & P2P:** Audio, video, and control streams are routed strictly across your local Wi-Fi subnet or direct USB link without external servers or cloud proxies.
- 💸 **Truly Free & Open Source:** Zero advertising, zero analytics trackers, and no subscriptions.

---

## ⌨️ Essential Shortcuts

| Shortcut | Action | Description |
| :--- | :--- | :--- |
| <kbd>Cmd</kbd> + <kbd>S</kbd> | Full Screenshot | Captures phone screen to `~/Downloads` & macOS clipboard |
| <kbd>Cmd</kbd> + <kbd>Shift</kbd> + <kbd>S</kbd> | Area Screenshot | Drag marquee to crop region on phone screen |
| <kbd>Cmd</kbd> + <kbd>Shift</kbd> + <kbd>R</kbd> | Screen Recording | Lossless hardware MP4 video recording with countdown HUD |
| <kbd>Cmd</kbd> + <kbd>Shift</kbd> + <kbd>I</kbd> | Install APK | Inspect, configure options & sideload Android APK packages |
| <kbd>Cmd</kbd> + <kbd>Shift</kbd> + <kbd>D</kbd> | Intent Dispatcher | Fire deep link URLs and Android intents with typed extras |
| <kbd>Cmd</kbd> + <kbd>U</kbd> | Send Files | Opens macOS Finder dialog to push files or install APKs |
| <kbd>Cmd</kbd> + <kbd>Shift</kbd> + <kbd>F</kbd> | Device Files | Opens Android File Explorer to browse and pull files to Mac |
| <kbd>Cmd</kbd> + <kbd>Shift</kbd> + <kbd>L</kbd> | Device Logcat | Opens real-time logcat inspection, filtering & recording console |
| <kbd>Cmd</kbd> + <kbd>K</kbd> | Text Injection | Opens Unicode / international text input modal |
| <kbd>Cmd</kbd> + <kbd>H</kbd> / <kbd>Backspace</kbd> | Home / Back | Android system navigation |

---

## 📚 Documentation Hub

| Guide | Description |
| :--- | :--- |
| [📖 User Guide](docs/user-guide.md) | Getting started, first-time setup, and device permissions |
| [📶 Pairing Guide](docs/pairing-guide.md) | Wireless pairing instructions for Android 11+ and USB fallback |
| [⌨️ Shortcuts & Gestures](docs/shortcuts.md) | Complete mouse gestures and macOS keyboard shortcuts cheat sheet |
| [⚡️ Features Catalog](docs/features/README.md) | Comprehensive modular documentation across all 13 built-in features |
| [🏛️ Architecture](docs/architecture.md) | Clean Architecture blueprint, BLoC state model, and socket protocols |
| [🛠️ Troubleshooting](docs/troubleshooting.md) | Solutions for Xiaomi/MIUI input permissions, firewalls, and ADB errors |
| [💡 Lessons Learned](docs/lessons-learned/README.md) | Engineering post-mortems, root cause analyses, and reusable edge-case solutions |

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

## 🛠️ Technology Stack & Quick Start

- **UI & State:** [Flutter Desktop](https://flutter.dev) (Dart) with [flutter_bloc](https://pub.dev/packages/flutter_bloc) and [get_it](https://pub.dev/packages/get_it).
- **Core Engine:** `scrcpy-server` with native TCP sockets, mDNS discovery, and Apple VideoToolbox decoding.

```bash
# 1. Install ADB (macOS)
brew install android-platform-tools

# 2. Clone repository & run
git clone https://github.com/az-coder-123/desk-droid.git
cd desk-droid
flutter pub get
flutter run -d macos
```

---

## 🤝 Contributing & License

Contributions are welcome! Open a PR or submit an issue on [GitHub](https://github.com/az-coder-123/desk-droid). Distributed under the **MIT License**. See [LICENSE](LICENSE) for details.

<p align="center">
  Maintained with ❤️ by <b><a href="https://github.com/az-coder-123">az-coder-123</a></b>
</p>
