# Platform Support (macOS & Windows)

> What runs on each desktop platform, how it was verified, and where the platforms differ. This is the single source of truth for platform status; other documents link here instead of repeating it.

Status date: **2026-10-20** (DeskDroid v1.3.0 on macOS and Windows).

---

## 1. Supported Hosts

| | macOS | Windows |
|:---|:---|:---|
| OS version | macOS 12.0+ | Windows 10/11 |
| CPU | Apple Silicon & Intel | x64 |
| Release package | `DeskDroid-v<version>-macOS.zip` (`.app`) | `DeskDroid-v<version>-Windows-x64.zip` (portable folder) |
| Build script | `scripts/build_release.sh` | `scripts/build_release.ps1` |
| Video decoder | Apple VideoToolbox (hardware) | Media Foundation H.264 decoder + CPU NV12→RGBA copy |
| Maturity | Stable | **Preview**: core mirroring verified, most tools not yet tested |
| Clean-install check | | Release ZIP verified in Windows Sandbox (no VC++ runtime, adb, or Dart): app, bundled adb, MCP server, and mirroring over Wi-Fi |
| OS components needed | none beyond macOS | Media Foundation, missing on Windows N/KN editions until the Media Feature Pack is installed (the app starts and explains it) |

Both release packages bundle **ADB** (an installed ADB takes precedence, see [bundled-platform-tools.md](bundled-platform-tools.md)). The phone needs Android 5.0+ with USB debugging enabled. See [installation.md](installation.md).

---

## 2. Feature Status

Legend: ✅ works · 🧪 implemented, not yet verified on this platform · ❌ not available

| Feature | macOS | Windows | Notes |
|:---|:-:|:-:|:---|
| Device discovery & Wi-Fi connection | ✅ | ✅ | Windows verified over Wi-Fi with a Redmi (Android 10). |
| USB connection & USB-to-Wi-Fi switch | ✅ | 🧪 | Windows may need the Google USB driver or an OEM driver. |
| Screen mirroring (video) | ✅ | ✅ | Windows: H.264 via Media Foundation; zero-copy GPU path is planned (Phase 1b). |
| Stream health & measured telemetry (`getStats`) | 🧪 | ✅ | macOS Swift code is written but not yet compiled on a Mac. |
| Bitrate presets (pipeline restart) | ✅ | ✅ | Verified on Windows: 16 Mbps applied in about 1 second. |
| Unauthorized-device guidance | ✅ | ✅ | Dart only; same behavior on both. |
| Remote input (mouse, keyboard) | ✅ | 🧪 | |
| Text injection | ✅ | 🧪 | |
| Screen-off streaming | ✅ | 🧪 | |
| Logcat console | ✅ | ✅ | |
| Deep link & intent dispatcher | ✅ | 🧪 | |
| APK sideload & package manager | ✅ | 🧪 | `aapt2.exe` is looked up in the SDK `build-tools` and on `PATH`. |
| File explorer & drag-and-drop push | ✅ | 🧪 | Windows uses File Explorer (`explorer.exe`) to reveal files. |
| Clipboard sync (text) | ✅ | 🧪 | |
| Screenshot to clipboard (image) | ✅ | 🧪 | Windows copies images through PowerShell (`-STA`). |
| Screen recording (MP4) | ✅ | 🧪 | Stopped with a remote `kill -2`, so the MP4 is finalized on both. |
| MCP AI agent server | ✅ | ✅ | Release builds ship a precompiled `deskdroid-mcp` (no Dart SDK needed); macOS verified end to end (58 tools, real device). Windows verified with `dart run bin/deskdroid_mcp.dart`; the precompiled `.exe` is not yet built on Windows. |
| MCP status panel | ✅ | 🧪 | macOS checked against a release build (executable answers, client files read, sessions counted). Windows uses `tasklist` and `%APPDATA%`; not run yet. [Details](features/mcp-status-panel.md). |
| MCP live activity | ✅ | 🧪 | macOS verified with a release server session on a real device (file written, read, removed). [Details](features/mcp-activity-log.md). |
| Audio forwarding | 🧪 | 🧪 | Raw PCM, Android 11+ ([details](features/audio-forwarding.md)). macOS: the app's player classes verified with `scripts/check_macos_native.sh` on an Android 16 emulator; not yet in the app with a real Android 11+ phone. Windows: WASAPI player written, not yet compiled. |
| Menu bar companion / system tray | ❌ | ❌ | The popover widget exists but is not wired into the app; a Windows tray is planned (Phase 3). |

"Verified" means exercised by hand against a real device on that platform, in addition to the automated test suite, which runs on both.

---

## 3. Platform Differences

| Topic | macOS | Windows |
|:---|:---|:---|
| Shortcut modifier | <kbd>Cmd</kbd> (tooltips show `⌘⇧S`) | <kbd>Ctrl</kbd> (tooltips show `Ctrl+Shift+S`) |
| Downloads folder (screenshots, recordings, pulled files) | `~/Downloads` | `%USERPROFILE%\Downloads` |
| ADB lookup | Android SDK, then Homebrew (`/opt/homebrew/bin`, `/usr/local/bin`), then `PATH` | `ANDROID_HOME`, `%LOCALAPPDATA%\Android\Sdk`, then `PATH` (`where adb`) |
| ADB key (authorize once per computer) | `~/.android/adbkey` | `%USERPROFILE%\.android\adbkey` |
| Diagnostic logs | `/tmp/deskdroid_dart.log`, `/tmp/scrcpy_stream.log` | `%TEMP%\deskdroid_dart.log`, `%TEMP%\scrcpy_stream.log` |
| Texture pixel order | BGRA | RGBA |
| Unsigned build warning | Gatekeeper ("cannot be verified") | SmartScreen ("Windows protected your PC") |

How these differences are implemented: [platform-abstraction.md](platform-abstraction.md). Native video details: [native-video-contract.md](native-video-contract.md). Remaining Windows work: [windows-port-plan.md](windows-port-plan.md).
