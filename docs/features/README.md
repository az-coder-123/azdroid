# Azdroid — Feature Documentation Catalog

> Comprehensive, modular catalog of all capabilities, developer tools, and desktop productivity enhancements implemented in **Azdroid** for macOS and Windows.

Shortcuts use <kbd>Cmd</kbd> on macOS and <kbd>Ctrl</kbd> on Windows. Platform legend: ✅ works · 🧪 implemented, not yet verified · ❌ not available. Details: [platform-support.md](../platform-support.md).

---

## 🧭 Feature Matrix

| # | Feature | Subsystem | Trigger / Shortcut | macOS | Windows | Documentation |
| :-: | :--- | :--- | :--- | :-: | :-: | :--- |
| **01** | **Device Discovery & Wireless Pairing** | `lib/features/discovery/` | Auto / Toolbar buttons | ✅ | ✅ | [device-discovery-pairing.md](device-discovery-pairing.md) |
| **02** | **Wireless Display & Low-Latency Streaming** | `lib/features/streaming/` | Auto on device connect | ✅ | ✅ | [wireless-display-streaming.md](wireless-display-streaming.md) |
| **03** | **Remote Input & Gesture Control** | `lib/features/control/` | Pointer / Keyboard input | ✅ | 🧪 | [remote-input-control.md](remote-input-control.md) |
| **04** | **Device Logcat Console & Debugging** | `lib/features/logging/` | <kbd>Cmd</kbd> + <kbd>Shift</kbd> + <kbd>L</kbd> | ✅ | ✅ | [device-logcat-console.md](device-logcat-console.md) |
| **05** | **APK Sideload & Package Manager** | `lib/features/apk_installer/` | <kbd>Cmd</kbd> + <kbd>Shift</kbd> + <kbd>I</kbd> | ✅ | 🧪 | [apk-sideload-manager.md](apk-sideload-manager.md) |
| **06** | **File Transfer & Device File Explorer** | `lib/features/productivity/` | <kbd>Cmd</kbd> + <kbd>Shift</kbd> + <kbd>F</kbd> | ✅ | 🧪 | [file-transfer-explorer.md](file-transfer-explorer.md) |
| **07** | **Hardware Screen Recording** | `lib/features/productivity/` | <kbd>Cmd</kbd> + <kbd>Shift</kbd> + <kbd>R</kbd> | ✅ | 🧪 | [hardware-screen-recording.md](hardware-screen-recording.md) |
| **08** | **Lossless Screenshots & Area Crop** | `lib/features/productivity/` | <kbd>Cmd</kbd> + <kbd>S</kbd> / <kbd>Shift</kbd> | ✅ | 🧪 | [screenshots-area-crop.md](screenshots-area-crop.md) |
| **09** | **Audio Forwarding** | `lib/features/audio/` | Auto during stream | 🧪 | 🧪 | [audio-forwarding.md](audio-forwarding.md) |
| **10** | **Bidirectional Clipboard Sync** | `lib/features/productivity/` | Auto (2 s), <kbd>Cmd</kbd> + <kbd>Shift</kbd> + <kbd>C</kbd> / <kbd>V</kbd> | ✅ | 🧪 | [clipboard-sync.md](clipboard-sync.md) |
| **11** | **Screen-Off Streaming** | `lib/features/streaming/` | <kbd>Cmd</kbd> + <kbd>O</kbd> | ✅ | 🧪 | [screen-off-streaming.md](screen-off-streaming.md) |
| **12** | **Menu Bar Companion** | `lib/features/menubar/` | Status bar icon (not wired yet) | ❌ | ❌ | [menu-bar-companion.md](menu-bar-companion.md) |
| **13** | **Deep Link & Intent Dispatcher** | `lib/features/intent_dispatcher/` | <kbd>Cmd</kbd> + <kbd>Shift</kbd> + <kbd>D</kbd> | ✅ | 🧪 | [deep-link-intent-dispatcher.md](deep-link-intent-dispatcher.md) |
| **14** | **Model Context Protocol (MCP) AI Agent Server** | `lib/features/mcp/` | Stdio CLI: bundled `deskdroid-mcp` (release builds), or `./scripts/start_mcp_server.sh` / `dart run bin/deskdroid_mcp.dart` (source) | ✅ | ✅ | [mcp-ai-agent-server.md](mcp-ai-agent-server.md) |
| **15** | **MCP Server Status Panel** | `lib/features/mcp_status/` | Hub icon in the device list toolbar | ✅ | 🧪 | [mcp-status-panel.md](mcp-status-panel.md) |
| **16** | **MCP Live Activity** | `lib/features/mcp_status/`, `lib/features/mcp/` | Status panel and mirroring banner | ✅ | 🧪 | [mcp-activity-log.md](mcp-activity-log.md) |

---

## 🏛️ Architectural Cohesion

Each feature in this catalog strictly adheres to **Clean Architecture** and the **Single Responsibility Principle (SRP)**:
- **Presentation Layer:** Pure declarative widgets driven by reactive `Cubit` / `Bloc` state management (`lib/features/<feature>/presentation/`).
- **Domain Layer:** Pure business entities and abstract repository contracts with zero UI or framework dependencies (`lib/features/<feature>/domain/`).
- **Data Layer:** Concrete repositories, ADB bridges, native sockets, and platform channel bindings (`lib/features/<feature>/data/`).
