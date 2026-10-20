# 🤖 Azdroid MCP Server — AI Agent Integration Guide

> Connect **Azdroid** to **Claude Desktop**, **Cursor**, and **Antigravity** via the **Model Context Protocol (MCP)** to allow AI assistants to see, control, inspect, test, profile, and automate real Android devices over Wi-Fi and USB.

---

## ⚡️ Overview

Azdroid provides a built-in **Model Context Protocol (MCP)** server over standard I/O (`stdio`). This bridges multimodal AI agents directly with your connected Android devices with zero UI overhead.

- **Headless & Standalone:** You **do not need to launch `Azdroid.app`** to use this MCP server. AI clients run the pure Dart CLI process independently in the background.
- **Optional Visual Mirroring:** You can optionally open `Azdroid.app` concurrently to visually observe the agent's taps, gestures, and inputs in real time at 60 FPS.

---

## 📋 Prerequisites & System Requirements

Before configuring and executing MCP tools with an AI assistant, ensure:

1. **Android Physical Device or Emulator:**
   - **Developer Options & USB Debugging:** Enabled on target device (`Settings` > `Developer options` > `USB debugging`).
   - **Host Authorization:** Accept the *"Always allow from this computer"* dialog when connecting via USB.
   - **Connection Verification:** Ensure device is online from a terminal (Terminal on macOS, PowerShell on Windows):
     ```bash
     adb devices
     # Expected output: <device_serial> device
     ```
2. **Host Machine (macOS or Windows):**
   - **No GUI Required:** the Azdroid app does not need to be running.
   - **Installed app (recommended):** release builds include a **precompiled server** (`deskdroid-mcp`) and a bundled `adb`. Nothing else is required: no Dart SDK, no separate ADB install.
   - **Source checkout (developers):** needs the Dart SDK (bundled with Flutter). ADB comes from your install or from `dart run tool/fetch_platform_tools.dart`.

---

## 🚀 Quick Setup & Configuration

### 0. Installed App — Precompiled Server (Recommended)

Point your client at the executable inside the installed app. It finds the bundled `adb` next to it and logs its choice to stderr (`[Azdroid MCP] Using installed|bundled adb at …`).

| Platform | `command` |
|:---|:---|
| macOS | `/Applications/Azdroid.app/Contents/MacOS/deskdroid-mcp` |
| Windows | `C:\path\to\Azdroid\deskdroid-mcp.exe` (next to `desk_droid.exe`; write `\\` in JSON) |

```json
{
  "mcpServers": {
    "deskdroid": {
      "command": "/Applications/Azdroid.app/Contents/MacOS/deskdroid-mcp"
    }
  }
}
```

Smoke test: `echo '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}' | /Applications/Azdroid.app/Contents/MacOS/deskdroid-mcp`

Or open Azdroid and click the **hub icon** in the device list toolbar: it checks the server, shows which AI clients are set up, counts connected sessions, and copies this JSON with the right path ([mcp-status-panel.md](features/mcp-status-panel.md)). While an AI works, the panel lists its tool calls and the mirroring page shows which device it controls; only tool names, devices, results, and durations are recorded, never arguments ([mcp-activity-log.md](features/mcp-activity-log.md)).

> [!NOTE]
> `dart compile exe` builds for the CPU of the build machine only; Dart cannot cross-compile to macOS arm64. A macOS release built on an Intel Mac ships an **x86_64** server, which runs on Apple Silicon through Rosetta 2 (macOS offers to install it). Release builds made on Apple Silicon ship **arm64**. Windows builds are x64.

The sections below configure the server **from a source checkout** instead.


### 1. Claude Desktop Integration

Add `deskdroid` to your `~/Library/Application Support/Claude/claude_desktop_config.json` (macOS; for Windows see [Windows Configuration](#5-windows-configuration)):

```json
{
  "mcpServers": {
    "deskdroid": {
      "command": "/absolute/path/to/azdroid/scripts/start_mcp_server.sh"
    }
  }
}
```

### 2. Cursor IDE & Windsurf Integration

Add to `.cursor/mcp.json` in your project root or user settings:

```json
{
  "mcpServers": {
    "deskdroid": {
      "command": "dart",
      "args": ["run", "/absolute/path/to/azdroid/bin/deskdroid_mcp.dart"]
    }
  }
}
```

### 3. Cline / Roo Code (VS Code Extension)

Add to `cline_mcp_settings.json`:

```json
{
  "mcpServers": {
    "deskdroid": {
      "command": "/absolute/path/to/azdroid/scripts/start_mcp_server.sh"
    }
  }
}
```

### 4. How to Verify if the Server is Working

Verify proper functioning using any of the following 3 methods:

- **Method 1: Terminal Pipe Test (CLI Smoke Test)**
  ```bash
  # 1. Verify all 58 tools are registered:
  echo '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}' | ./scripts/start_mcp_server.sh

  # 2. Test live device discovery:
  echo '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"android_list_devices","arguments":{}}}' | ./scripts/start_mcp_server.sh
  ```
  *(Note: Running `./start_mcp_server.sh` directly without piped input waits for stdin. This is standard stdio behavior, not a freeze. Press `Ctrl+C` to exit.)*

- **Method 2: Visual Indicator in Claude / Cursor**
  - **Claude Desktop:** Look for the 🔨 tool icon in the bottom-right corner of the chat input. Clicking it displays `deskdroid` with 58 tools enabled.
  - **Cursor IDE:** Open *Settings* > *Features* > *MCP Servers*. A green dot indicates `Connected (58 tools)`.

- **Method 3: Direct Natural Language Prompt**
  Ask your AI: *"List all connected Android devices with Azdroid"* — the assistant will autonomously invoke `android_list_devices` and report your device serial.

### 5. Windows Configuration

The server runs on Windows with `dart run` (verified: all 58 tools listed, `android_list_devices` sees a real device). `start_mcp_server.sh` is a bash script, so point clients at `dart` directly. Use the full path to `dart.exe` if the client does not inherit your `PATH`.

Claude Desktop reads `%APPDATA%\Claude\claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "deskdroid": {
      "command": "dart",
      "args": ["run", "C:\\path\\to\\desk-droid\\bin\\deskdroid_mcp.dart"]
    }
  }
}
```

Smoke test in PowerShell, from the repository folder:

```powershell
'{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}' | dart run bin/deskdroid_mcp.dart
```

---

## 🛠️ Published MCP Tools (58 Tools)

### 1. Touch & System Navigation
| Tool Name | Parameters | Purpose |
| :--- | :--- | :--- |
| **`android_list_devices`** | *none* | Lists all connected USB and Wi-Fi Android devices and their status. |
| **`android_take_screenshot`** | `deviceSerial` (optional) | Returns high-resolution screenshot as a base64 image artifact for visual inspection. |
| **`android_tap`** | `x`, `y` (normalized 0.0–1.0 or pixels), `deviceSerial` | Simulates a touch tap gesture on screen. |
| **`android_double_tap`** | `x`, `y`, `intervalMs` (default 120), `deviceSerial` | Executes rapid double-tap within native Android window to seek video, zoom, or like. |
| **`android_swipe`** | `startX`, `startY`, `endX`, `endY`, `durationMs` | Injects a swipe gesture across screen coordinates. |
| **`android_drag`** | `startX`, `startY`, `endX`, `endY`, `durationMs` (1000) | Smooth, controlled drag gesture for timeline seekbars, sliders, and list reordering. |
| **`android_type_text`** | `text`, `deviceSerial` | Types text into the focused Android input field (character-by-character). |
| **`android_set_text`** | `text`, `elementId` (optional), `clearFirst` (bool), `deviceSerial` | Sets exact text atomically, bypassing IME predictive autocorrect and Telex alteration. |
| **`android_clear_text`** | `elementId` (optional), `deviceSerial` | Clears all text in the focused field or target element by ID in a single shot. |
| **`android_press_key`** | `key` (`BACK`, `HOME`, `APP_SWITCH`, `ENTER`, `TAB`, `POWER`, etc.) | Presses Android hardware/navigation keys. |
| **`android_dispatch_intent`** | `action`, `dataUri`, `package`, `component`, `extras` | Dispatches Android Intents, deep link URLs, and custom app schemes. |
| **`android_get_logcat`** | `tag`, `limit` | Retrieves real-time or recent logcat records for crash diagnosis. |
| **`android_check_crash`** | `package` (optional), `limit` (default 50) | Targeted inspection of crash buffers, fatal runtime exceptions, and ANR traces. |
| **`android_scan_media_file`** | `filePath` | Triggers MediaStore indexing broadcast (`MEDIA_SCANNER_SCAN_FILE`) for immediate media visibility. |
| **`android_install_apk`** | `apkPath`, `reinstall`, `grantPermissions` | Sideloads an APK package onto the device. |
| **`android_shell_command`** | `command`, `deviceSerial` | Runs raw ADB shell commands for advanced diagnostics. |

### 2. UI Semantic Inspection & Accessibility
| Tool Name | Parameters | Purpose |
| :--- | :--- | :--- |
| **`android_get_semantic_tree`** | `deviceSerial` | Prunes invisible/empty layouts into a compact token-efficient digest (< 2KB / ~300 tokens) with sequential `[#ID]` tags. |
| **`android_click_element_by_id`** | `id`, `deviceSerial` | Taps an element directly by its sequential `[#ID]` from the semantic tree in < 50ms without image vision. |
| **`android_dump_hierarchy`** | `deviceSerial` | Dumps the complete active window UI accessibility XML (classes, IDs, text, bounds). |
| **`android_find_element`** | `text`, `resourceId`, `contentDesc`, `deviceSerial` | Queries the UI tree and returns exact bounds and center tap coordinates. |
| **`android_click_element`** | `text`, `resourceId`, `contentDesc`, `deviceSerial` | Locates an on-screen element by query and taps its center coordinates in one shot. |

### 3. Application Lifecycle & Package Governance
| Tool Name | Parameters | Purpose |
| :--- | :--- | :--- |
| **`android_get_current_app`** | `deviceSerial` | Identifies the foreground package and Activity. If the lock screen or notification shade is in front, it still names the app and adds a note naming that window. |
| **`android_launch_app`** | `package`, `deviceSerial` | Launches an installed application via default launcher category. |
| **`android_stop_app`** | `package`, `deviceSerial` | Force terminates a running application by package name. |
| **`android_clear_app_data`** | `package`, `deviceSerial` | Clears app cache and user data (resets app to fresh install state). |
| **`android_list_packages`** | `thirdPartyOnly`, `query`, `deviceSerial` | Searches and lists installed applications on the device. |

### 4. Device Telemetry, Clipboard & File Transfers
| Tool Name | Parameters | Purpose |
| :--- | :--- | :--- |
| **`android_get_device_info`** | `deviceSerial` | Reports hardware model, manufacturer, Android OS, display resolution, and battery level. |
| **`android_get_clipboard`** | `deviceSerial` | Reads the current text stored in the Android system clipboard. |
| **`android_set_clipboard`** | `text`, `deviceSerial` | Copies text directly into the Android system clipboard. |
| **`android_push_file`** | `localPath`, `remotePath`, `deviceSerial` | Uploads a file from Mac host to the Android filesystem. |
| **`android_pull_file`** | `remotePath`, `localPath`, `deviceSerial` | Downloads a file or capture from Android device to Mac host. |

### 5. Connectivity, Audio, Permissions & System Controls
| Tool Name | Parameters | Purpose |
| :--- | :--- | :--- |
| **`android_toggle_wifi`** | `enable`, `deviceSerial` | Enables or disables the device Wi-Fi radio. |
| **`android_toggle_airplane_mode`** | `enable`, `deviceSerial` | Enables or disables Airplane mode. |
| **`android_grant_permission`** | `package`, `permission`, `deviceSerial` | Grants a runtime permission to an application (e.g. notifications, camera). |
| **`android_revoke_permission`** | `package`, `permission`, `deviceSerial` | Revokes a runtime permission from an application. |
| **`android_set_volume`** | `stream`, `volumeIndex`, `deviceSerial` | Adjusts audio volume level (Media, Ring, Alarm, Notification). |
| **`android_wake_screen`** | `wake`, `deviceSerial` | Wakes the screen or puts the device to sleep. |
| **`android_open_settings`** | `action`, `package`, `deviceSerial` | Opens specific Android system settings or App Info details page. |

### 6. Performance Profiling, Media, Orientation & Processes
| Tool Name | Parameters | Purpose |
| :--- | :--- | :--- |
| **`android_get_cpu_usage`** | `package`, `deviceSerial` | Samples CPU consumption for a specific package or top system processes. |
| **`android_get_memory_info`** | `package`, `deviceSerial` | Dumps detailed memory allocation (PSS, Dalvik, Native heap) for an app. |
| **`android_get_battery_stats`** | `deviceSerial` | Retrieves battery health, temperature (°C), voltage, and charging source. |
| **`android_get_gfx_info`** | `package`, `deviceSerial` | Queries Choreographer frame timings and jank percentage for an app. |
| **`android_get_network_info`** | `deviceSerial` | Discovers local IP address, connected Wi-Fi SSID, and wireless link speed. |
| **`android_record_screen`** | `durationSec`, `localDestination`, `deviceSerial` | Records an MP4 video of the screen and saves it to the Mac host. |
| **`android_list_processes`** | `filter`, `deviceSerial` | Lists running Android processes with their PIDs and package names. |
| **`android_kill_process`** | `pid`, `package`, `deviceSerial` | Terminates an active process by PID or package name. |
| **`android_set_orientation`** | `orientation` (0..3), `deviceSerial` | Rotates screen: 0=Portrait, 1=Landscape, 2=Rev. Portrait, 3=Rev. Landscape. |
| **`android_simulate_biometric`** | `success` (bool), `deviceSerial` | Simulates biometric (fingerprint/face) authentication prompt. |
| **`android_wait_for_element`** | `text`, `resourceId`, `timeoutMs` | Polls UI until element appears to eliminate LLM polling round-trips. |
| **`android_batch_actions`** | `actions` (array of maps) | Executes compound sequence of actions locally in one shot. |
| **`android_get_notifications`** | `filter`, `deviceSerial` | Extracts active system notifications and status bar 2FA/OTP codes. |
| **`android_dismiss_notification`** | `key`, `clearAll`, `deviceSerial` | Dismisses a specific notification or clears all notifications. |
| **`android_set_location`** | `latitude`, `longitude`, `altitude` | Injects mock GPS coordinates for maps and geo-fencing QA. |
| **`android_set_network_condition`** | `mode`, `deviceSerial` | Simulates network conditions (`offline`, `wifi_only`, `data_only`, `normal`). |
| **`android_long_press`** | `x`, `y`, `durationMs` | Injects a long-press touch gesture with configurable duration. |
| **`android_open_notification_panel`** | `expand`, `quickSettings` | Expands or collapses notification shade or Quick Settings. |
| **`android_read_shared_prefs`** | `package`, `fileName` | Reads SharedPreferences XML data for deep state verification. |
| **`android_press_button`** | `button` (`volume_up`, `camera`, etc.) | Triggers physical hardware buttons on the device. |

---

## 💡 Example AI Assistant Prompts & Execution Scenarios

Once configured, your AI assistant can execute autonomous mobile QA and engineering workflows:

### 🎯 Scenario 1: Launch App & Tap by Text (No Coordinate Guessing)

> **User Prompt:** *"Check if any device is connected, launch YouTube, and tap the Search button."*
> 
> **AI Autonomous Execution:**
> 1. Invokes `android_list_devices()` ➔ Identifies online device serial.
> 2. Invokes `android_launch_app(package="com.google.android.youtube")` ➔ Brings app to foreground.
> 3. Invokes `android_click_element(text="Search", contentDesc="Search")` ➔ Inspects the accessibility tree and taps the center of the matching element.

### 📸 Scenario 2: Automated Visual Inspection & Layout QA

> **User Prompt:** *"Capture the current device display and evaluate whether the user profile header renders properly."*
> 
> **AI Autonomous Execution:**
> 1. Invokes `android_take_screenshot()` ➔ Captures display and returns base64 image artifact into AI context.
> 2. AI Multimodal Vision ➔ Inspects layout alignment, typography, and visual assets to report UI discrepancies.

### 📊 Scenario 3: Performance & Memory Leak Profiling

> **User Prompt:** *"Profile CPU utilization, memory allocations, and battery status for `com.example.app` during a 30-second run."*
> 
> **AI Autonomous Execution:**
> 1. Invokes `android_get_cpu_usage(package="com.example.app")` ➔ Measures user and kernel thread CPU load.
> 2. Invokes `android_get_memory_info(package="com.example.app")` ➔ Extracts PSS, Native Heap, and Dalvik Heap sizes.
> 3. Invokes `android_get_battery_stats()` ➔ Reads battery temperature (°C) and voltage to detect overheating.

### 🎬 Scenario 4: Bug Reproduction & MP4 Video Capture

> **User Prompt:** *"Rotate display to Landscape, record a 10-second video of the animation bug into `/tmp/bug.mp4`, and check recent error logs."*
> 
> **AI Autonomous Execution:**
> 1. Invokes `android_set_orientation(orientation=1)` ➔ Rotates display to landscape orientation.
> 2. Invokes `android_record_screen(durationSec=10, localDestination="/tmp/bug.mp4")` ➔ Hardware encodes MP4 on device GPU and pulls to Mac.
> 3. Invokes `android_get_logcat(limit=50)` ➔ Filters crash stack traces and exception logs.

### 🔐 Scenario 5: Biometric Authentication Simulation

> **User Prompt:** *"When on the bank login screen, simulate a successful biometric fingerprint verification."*
> 
> **AI Autonomous Execution:**
> 1. Invokes `android_simulate_biometric(success=true)` ➔ Injects virtual fingerprint sensor match signal.
> 2. Invokes `android_get_current_app()` ➔ Confirms successful transition from lock screen to account dashboard.

---

## 🔒 Security & Privacy
- **100% Local & P2P:** All communication travels exclusively between your AI client and local ADB daemon over standard I/O.
- **Zero Cloud Proxies:** No telemetry, analytics, or third-party relays.
