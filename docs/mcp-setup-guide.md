# 🤖 DeskDroid MCP Server — AI Agent Integration Guide

> Connect **DeskDroid** to **Claude Desktop**, **Cursor**, and **Antigravity** via the **Model Context Protocol (MCP)** to allow AI assistants to see, control, inspect, test, profile, and automate real Android devices over Wi-Fi and USB.

---

## ⚡️ Overview

DeskDroid provides a built-in **Model Context Protocol (MCP)** server over standard I/O (`stdio`). This bridges multimodal AI agents directly with your connected Android devices with zero UI overhead.

---

## 🚀 Quick Setup & Configuration

### 1. Claude Desktop Integration

Add `deskdroid` to your `claude_desktop_config.json`:
- **macOS:** `~/Library/Application Support/Claude/claude_desktop_config.json`

```json
{
  "mcpServers": {
    "deskdroid": {
      "command": "dart",
      "args": [
        "run",
        "/absolute/path/to/desk-droid/bin/deskdroid_mcp.dart"
      ]
    }
  }
}
```

Or using the launcher script:
```json
{
  "mcpServers": {
    "deskdroid": {
      "command": "/absolute/path/to/desk-droid/scripts/start_mcp_server.sh"
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
      "args": ["run", "/absolute/path/to/desk-droid/bin/deskdroid_mcp.dart"]
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
      "command": "/absolute/path/to/desk-droid/scripts/start_mcp_server.sh"
    }
  }
}
```

### 4. CLI Smoke Testing

Verify the server over `stdio` directly from macOS Terminal:

```bash
echo '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}' | ./scripts/start_mcp_server.sh
```

---

## 🛠️ Published MCP Tools (40 Tools)

### 1. Touch & System Navigation
| Tool Name | Parameters | Purpose |
| :--- | :--- | :--- |
| **`android_list_devices`** | *none* | Lists all connected USB and Wi-Fi Android devices and their status. |
| **`android_take_screenshot`** | `deviceSerial` (optional) | Returns high-resolution screenshot as a base64 image artifact for visual inspection. |
| **`android_tap`** | `x`, `y` (normalized 0.0–1.0 or pixels), `deviceSerial` | Simulates a touch tap gesture on screen. |
| **`android_swipe`** | `startX`, `startY`, `endX`, `endY`, `durationMs` | Injects a swipe or drag gesture. |
| **`android_type_text`** | `text`, `deviceSerial` | Types text into the focused Android input field (supports Unicode & spaces). |
| **`android_press_key`** | `key` (`BACK`, `HOME`, `APP_SWITCH`, `ENTER`, `TAB`, `POWER`, etc.) | Presses Android hardware/navigation keys. |
| **`android_dispatch_intent`** | `action`, `dataUri`, `package`, `component`, `extras` | Dispatches Android Intents, deep link URLs, and custom app schemes. |
| **`android_get_logcat`** | `tag`, `limit` | Retrieves real-time or recent logcat records for crash diagnosis. |
| **`android_install_apk`** | `apkPath`, `reinstall`, `grantPermissions` | Sideloads an APK package onto the device. |
| **`android_shell_command`** | `command`, `deviceSerial` | Runs raw ADB shell commands for advanced diagnostics. |

### 2. UI Semantic Inspection & Accessibility
| Tool Name | Parameters | Purpose |
| :--- | :--- | :--- |
| **`android_dump_hierarchy`** | `deviceSerial` | Dumps the complete active window UI accessibility XML (classes, IDs, text, bounds). |
| **`android_find_element`** | `text`, `resourceId`, `contentDesc`, `deviceSerial` | Queries the UI tree and returns exact bounds and center tap coordinates. |
| **`android_click_element`** | `text`, `resourceId`, `contentDesc`, `deviceSerial` | Locates an on-screen element by query and taps its center coordinates in one shot. |

### 3. Application Lifecycle & Package Governance
| Tool Name | Parameters | Purpose |
| :--- | :--- | :--- |
| **`android_get_current_app`** | `deviceSerial` | Identifies currently focused foreground package and active Activity. |
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

---

## 💡 Example AI Assistant Prompts

Once configured, your AI assistant can execute autonomous mobile QA and engineering workflows:

1. **Performance & Memory Leak Investigation:**
   > *"Run a 30-second stress test on `com.example.app`, then check `android_get_cpu_usage` and `android_get_memory_info` to detect memory leaks or runaway background threads."*
2. **Visual Animation Recording & Defect Capture:**
   > *"Rotate screen to Landscape with `android_set_orientation`, start a 10-second screen recording to `/tmp/bug_demo.mp4`, reproduce the glitch, and summarize the logcat errors."*
3. **Semantic UI Navigation (No Coordinate Guessing):**
   > *"Find the element with text 'Đăng nhập' or ID 'btn_login' and click it. Then dump the new hierarchy to confirm we reached the dashboard."*
4. **Resilience & Biometric Testing:**
   > *"Open the bank app login screen, trigger biometric prompt, simulate successful match with `android_simulate_biometric`, and verify that the account summary loads."*

---

## 🔒 Security & Privacy
- **100% Local & P2P:** All communication travels exclusively between your AI client and local ADB daemon over standard I/O.
- **Zero Cloud Proxies:** No telemetry, analytics, or third-party relays.
