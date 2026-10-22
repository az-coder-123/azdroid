# 🤖 Azdroid MCP Server — AI Agent Integration Guide

> Connect **Azdroid** to **Claude Desktop**, **Cursor**, and **Antigravity** via the **Model Context Protocol (MCP)** to allow AI assistants to see, control, inspect, test, profile, and automate real Android devices over Wi-Fi and USB.

---

## ⚡️ Overview

Azdroid provides a built-in **Model Context Protocol (MCP)** server over standard I/O (`stdio`). This bridges multimodal AI agents directly with your connected Android devices with zero UI overhead.

- **Headless & Standalone:** You **do not need to launch `Azdroid.app`** to use this MCP server. AI clients run the pure Dart CLI process independently in the background.
- **Optional Visual Mirroring:** You can optionally open `Azdroid.app` concurrently to visually observe the agent's taps, gestures, and inputs in real time at 60 FPS.
- **End-to-End Workflow:** For a practical real-world scenario (request, planning, interaction, triage, code fix, verification), see [mcp-agent-workflow.md](mcp-agent-workflow.md).
- **Agent Guidance at Handshake:** On `initialize`, the server returns workflow `instructions` (`lib/features/mcp/domain/services/mcp_server_instructions.dart`) so clients like Claude Desktop and Cursor learn the recommended tool-usage patterns (semantic-tree-first targeting, host-side waiting, tool selection rules) before the first tool call.

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
   - **Installed app (recommended):** release builds include a **precompiled server** (`azdroid-mcp`) and a bundled `adb`. Nothing else is required: no Dart SDK, no separate ADB install.
   - **Source checkout (developers):** needs the Dart SDK (bundled with Flutter). ADB comes from your install or from `dart run tool/fetch_platform_tools.dart`.

---

## 🚀 Quick Setup & Configuration

### 0. Installed App — Precompiled Server (Recommended)

Point your client at the executable inside the installed app. It finds the bundled `adb` next to it and logs its choice to stderr (`[Azdroid MCP] Using installed|bundled adb at …`).

| Platform | `command` |
|:---|:---|
| macOS | `/Applications/Azdroid.app/Contents/MacOS/azdroid-mcp` |
| Windows | `C:\path\to\Azdroid\azdroid-mcp.exe` (next to `desk_droid.exe`; write `\\` in JSON) |

```json
{
  "mcpServers": {
    "azdroid": {
      "command": "/Applications/Azdroid.app/Contents/MacOS/azdroid-mcp"
    }
  }
}
```

Smoke test: `echo '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}' | /Applications/Azdroid.app/Contents/MacOS/azdroid-mcp`

Or open Azdroid and click the **hub icon** in the device list toolbar: it checks the server, shows which AI clients are set up, counts connected sessions, and copies this JSON with the right path ([mcp-status-panel.md](features/mcp-status-panel.md)). While an AI works, the panel lists its tool calls and the mirroring page shows which device it controls; only tool names, devices, results, and durations are recorded, never arguments ([mcp-activity-log.md](features/mcp-activity-log.md)).

> [!NOTE]
> `dart compile exe` builds for the CPU of the build machine only; Dart cannot cross-compile to macOS arm64. A macOS release built on an Intel Mac ships an **x86_64** server, which runs on Apple Silicon through Rosetta 2 (macOS offers to install it). Release builds made on Apple Silicon ship **arm64**. Windows builds are x64.

The sections below configure the server **from a source checkout** instead.


### 1. Claude Desktop Integration

Add `azdroid` to your `~/Library/Application Support/Claude/claude_desktop_config.json` (macOS; for Windows see [Windows Configuration](#5-windows-configuration)):

```json
{
  "mcpServers": {
    "azdroid": {
      "command": "/absolute/path/to/azdroid/scripts/start_mcp_server.sh"
    }
  }
}
```

### 2. Cursor IDE & Windsurf Integration

> [!WARNING]
> Cursor has long sent at most about **40 MCP tools** across all servers to the model and dropped the rest (forum reports from 2025; not confirmed for current versions). Azdroid publishes 35, which leaves room for a few tools from other servers. If Cursor warns about the tool count, disable the tools you do not need under *Settings → MCP*.

Add to `.cursor/mcp.json` in your project root or user settings:

```json
{
  "mcpServers": {
    "azdroid": {
      "command": "dart",
      "args": ["run", "/absolute/path/to/azdroid/bin/azdroid_mcp.dart"]
    }
  }
}
```

### 3. Cline / Roo Code (VS Code Extension)

Add to `cline_mcp_settings.json`:

```json
{
  "mcpServers": {
    "azdroid": {
      "command": "/absolute/path/to/azdroid/scripts/start_mcp_server.sh"
    }
  }
}
```

### 4. How to Verify if the Server is Working

Verify proper functioning using any of the following 3 methods:

- **Method 1: Terminal Pipe Test (CLI Smoke Test)**
  ```bash
  # 1. Verify all 35 tools are registered:
  echo '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}' | ./scripts/start_mcp_server.sh

  # 2. Test live device discovery:
  echo '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"android_list_devices","arguments":{}}}' | ./scripts/start_mcp_server.sh
  ```
  *(Note: Running `./start_mcp_server.sh` directly without piped input waits for stdin. This is standard stdio behavior, not a freeze. Press `Ctrl+C` to exit.)*

- **Method 2: Visual Indicator in Claude / Cursor**
  - **Claude Desktop:** Look for the 🔨 tool icon in the bottom-right corner of the chat input. Clicking it displays `azdroid` with 35 tools enabled.
  - **Cursor IDE:** Open *Settings* > *Features* > *MCP Servers*. A green dot indicates `Connected (35 tools)`.

- **Method 3: Direct Natural Language Prompt**
  Ask your AI: *"List all connected Android devices with Azdroid"* — the assistant will autonomously invoke `android_list_devices` and report your device serial.

### 5. Windows Configuration

The server runs on Windows with `dart run` (verified with the 58-tool catalog of that time: all tools listed, `android_list_devices` sees a real device). `start_mcp_server.sh` is a bash script, so point clients at `dart` directly. Use the full path to `dart.exe` if the client does not inherit your `PATH`.

Claude Desktop reads `%APPDATA%\Claude\claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "azdroid": {
      "command": "dart",
      "args": ["run", "C:\\path\\to\\desk-droid\\bin\\azdroid_mcp.dart"]
    }
  }
}
```

Smoke test in PowerShell, from the repository folder:

```powershell
'{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}' | dart run bin/azdroid_mcp.dart
```

---

## 🛠️ Published MCP Tools (35 Tools)

> **Single source of truth:** tool names, descriptions, input schemas, and
> safety annotations are defined in `lib/features/mcp/domain/services/mcp_*_tools.dart`
> (`McpToolRegistry`). After changing the registry, regenerate the client
> manifests with `dart run tool/generate_mcp_manifests.dart` (writes
> `.agents/mcp/azdroid/`). `test/architecture/mcp_tool_catalog_guard_test.dart`
> fails the build on any drift (missing executor, stale manifest, orphan
> manifest, duplicate name, or missing/invalid annotations). Destructive tools
> (`destructiveHint: true`) are gated by a reviewed allowlist in the same
> guard test, and the guard also requires the `initialize` instructions to
> name each of them; read-only tools carry `readOnlyHint: true`.

**Safety, coordinates, protocol revision:** which tools need confirmation, how points and text are read, and how the revision is negotiated — [mcp-tool-safety.md](mcp-tool-safety.md).

Every tool also takes `deviceSerial` (required when several devices are connected). Points accept `x`/`y` (fractions when both are within 0.0–1.0, else pixels), `xRatio`/`yRatio`, or `xPixel`/`yPixel`.

### 1. Touch, Keys & Text
| Tool Name | Parameters | Purpose |
| :--- | :--- | :--- |
| **`android_tap`** | point, `taps` (1 or 2), `intervalMs`, `holdMs`, `verifyChange` | Tap, double tap (`taps: 2`), or long press (`holdMs`). |
| **`android_swipe`** | `startX`…`endY` (or `*Ratio`/`*Pixel`), `style` (`fling`/`drag`), `direction`, `distance`, `speed`, `durationMs` | Swipe between two points; `style: "drag"` moves slowly (sliders, reordering); `direction` scrolls from the screen center without coordinates. |
| **`android_multitouch_gesture`** | `gesture` (`pinch`/`rotate`), `scale`, `angleDegrees`, `centerX`, `centerY`, `radius`, `durationMs` | Two-finger pinch zoom or rotation. |
| **`android_input_text`** | `text`, `method` (`paste`/`type`), `elementId`, `clearFirst` | `paste` (default) enters exact text, any language, through the clipboard; `type` sends ASCII key events and leaves the clipboard alone; empty `text` clears the field. |
| **`android_press_key`** | `key` (`BACK`, `HOME`, `APP_SWITCH`, `ENTER`, `TAB`, `POWER`, `VOLUME_*`, `MUTE`, `CAMERA`, `WAKEUP`, `SLEEP`, `MEDIA_*`, `NOTIFICATIONS`, `QUICK_SETTINGS`, `CLOSE_PANELS`) | Navigation and hardware keys, and opening or closing the status bar panels. |
| **`android_batch_actions`** | `actions` (array of maps) | Runs a sequence of steps (tap, double_tap, type, key, swipe, scroll, fling, pinch, rotate, sleep) locally in one call. |

### 2. Screen & UI
| Tool Name | Parameters | Purpose |
| :--- | :--- | :--- |
| **`android_take_screenshot`** | `x`/`y`/`width`/`height` or `*Ratio`, `format`, `quality` | Screenshot as PNG or JPEG, optionally cropped. |
| **`android_get_ui_tree`** | `format` (`semantic`/`xml`), `compressed` | `semantic` (default): a compact list of visible elements with `[#ID]` tags; `xml`: the full accessibility XML. |
| **`android_find_element`** | `text`, `resourceId`, `contentDesc` | Bounds and center of a matching element. |
| **`android_click_element`** | `id`, or `text`/`resourceId`/`contentDesc` | Taps an element by its `[#ID]` from `android_get_ui_tree`, or by query. |
| **`android_wait_for_condition`** | `condition`, `target`, `text`, `resourceId`, `contentDesc`, `timeoutMs`, `pollIntervalMs` | Waits until an element appears or goes, an activity resumes, or a log line matches. |
| **`android_record_screen`** | `durationSec`, `localDestination` | Records an MP4 to the computer. |
| **`android_set_orientation`** | `orientation` (0–3) | 0 portrait, 1 landscape, 2 reverse portrait, 3 reverse landscape. |

### 3. Apps & Processes
| Tool Name | Parameters | Purpose |
| :--- | :--- | :--- |
| **`android_list_devices`** | *none* | Devices adb can reach (`adb devices -l`). |
| **`android_get_current_app`** | *none* | Foreground package and activity; notes a lock screen or notification shade in front. |
| **`android_list_apps`** | `running`, `thirdPartyOnly`, `query` | Installed packages, or running processes with PIDs (`running: true`). |
| **`android_launch_app`** | `package` | Starts an app from its launcher entry. |
| **`android_stop_app`** | `package` or `pid` | Force-stops an app; `pid` kills one process (adb-shell-owned unless rooted). |
| **`android_clear_app_data`** | `package` | Resets the app to a fresh install state. |
| **`android_install_apk`** | `apkPath`, `reinstall`, `grantPermissions` | Installs an APK from the computer. |
| **`android_set_permission`** | `package`, `permission`, `grant` | Grants (`true`) or revokes (`false`) a runtime permission; revoking kills the app. |
| **`android_dispatch_intent`** | `action`, `dataUri`, `package`, `component`, `extras` | Sends an intent or deep link. |
| **`android_read_shared_prefs`** | `package`, `fileName` | SharedPreferences XML of a **debuggable** app (`run-as`) or on a rooted device. |

### 4. Diagnostics
| Tool Name | Parameters | Purpose |
| :--- | :--- | :--- |
| **`android_get_logcat`** | `tag`, `level` (V–F), `crashesOnly`, `package`, `limit` | Newest log lines filtered by tag and level, or only crashes and ANRs (`crashesOnly: true`). |
| **`android_get_device_stats`** | `kind` (`device`/`battery`/`network`/`cpu`/`memory`/`gfx`), `package` | Device info, battery, network, CPU, memory, or frame timings (`cpu`, `memory`, `gfx` take `package`). |
| **`android_shell_command`** | `command` | Runs a raw `adb shell` command. |

### 5. System, Network & Files
| Tool Name | Parameters | Purpose |
| :--- | :--- | :--- |
| **`android_set_network`** | `mode` (`normal`, `offline`, `wifi_only`, `data_only`, `wifi_on`, `wifi_off`, `airplane_on`, `airplane_off`) | Network conditions and radio toggles; modes that drop Wi-Fi cut a Wi-Fi ADB connection. |
| **`android_set_volume`** | `stream`, `volumeIndex` | Media, ring, alarm, or notification volume. |
| **`android_open_settings`** | `action`, `package` | Opens a settings screen or an app's info page. |
| **`android_clipboard`** | `text` (to set) | Reads the clipboard, or sets it when `text` is given; needs `cmd clipboard` (missing on the Android 10 and 13 devices tested). |
| **`android_transfer_file`** | `direction` (`push`/`pull`/`scan`), `localPath`, `remotePath` | Copies a file to or from the device, or makes a device file visible to the media library (`scan`). |
| **`android_get_notifications`** | `filter` | Notifications (package, title, text, key), including OTP previews. |
| **`android_dismiss_notification`** | `key`, `hideMinutes` | Hides one notification by snoozing it (Android 11+); it returns afterwards. |
| **`android_set_location`** | `latitude`, `longitude`, or `reset` | Mock location until `reset: true` (Android 12+ with location on, or emulators). |
| **`android_simulate_biometric`** | `success` | Fingerprint touch on **emulators only**; physical devices return an error. |

### Older Tool Names

Before 2026-10-22 the server published 62 tools. The old names, such as `android_double_tap`, `android_set_text`, `android_get_semantic_tree`, `android_toggle_wifi`, or `android_check_crash`, are no longer listed but still work when called, with their old parameters, so saved prompts and scripts keep running. `McpToolRouter` (`lib/features/mcp/data/handlers/mcp_tool_router.dart`) maps each published tool to them.

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
> 1. Invokes `android_get_device_stats(kind="cpu", package="com.example.app")` ➔ Measures user and kernel thread CPU load.
> 2. Invokes `android_get_device_stats(kind="memory", package="com.example.app")` ➔ Extracts PSS, Native Heap, and Dalvik Heap sizes.
> 3. Invokes `android_get_device_stats(kind="battery")` ➔ Reads battery temperature (°C) and voltage to detect overheating.

### 🎬 Scenario 4: Bug Reproduction & MP4 Video Capture

> **User Prompt:** *"Rotate display to Landscape, record a 10-second video of the animation bug into `/tmp/bug.mp4`, and check recent error logs."*
> 
> **AI Autonomous Execution:**
> 1. Invokes `android_set_orientation(orientation=1)` ➔ Rotates display to landscape orientation.
> 2. Invokes `android_record_screen(durationSec=10, localDestination="/tmp/bug.mp4")` ➔ Hardware encodes MP4 on device GPU and pulls to Mac.
> 3. Invokes `android_get_logcat(limit=50)` ➔ Filters crash stack traces and exception logs.

### 🔐 Scenario 5: Biometric Authentication Simulation

> **User Prompt (emulator):** *"When on the bank login screen, simulate a successful biometric fingerprint verification."*
> 
> **AI Autonomous Execution:**
> 1. Invokes `android_simulate_biometric(success=true)` ➔ Touches the emulator's fingerprint sensor with an enrolled finger (physical devices return an error).
> 2. Invokes `android_get_current_app()` ➔ Confirms successful transition from lock screen to account dashboard.

---

## 🔒 Security & Privacy
- **100% Local & P2P:** All communication travels exclusively between your AI client and local ADB daemon over standard I/O.
- **Zero Cloud Proxies:** No telemetry, analytics, or third-party relays.
