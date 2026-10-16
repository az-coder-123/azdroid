# 🤖 DeskDroid MCP Server — AI Agent Integration Guide

> Connect **DeskDroid** to **Claude Desktop**, **Cursor**, and **Antigravity** via the **Model Context Protocol (MCP)** to allow AI assistants to see, control, test, and automate real Android devices over Wi-Fi and USB.

---

## ⚡️ Overview

DeskDroid provides a built-in **Model Context Protocol (MCP)** server over standard I/O (`stdio`). This bridges multimodal AI agents directly with your connected Android devices at hardware-accelerated speeds.

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

### 2. Cursor IDE Integration

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

---

## 🛠️ Published MCP Tools (20 Tools)

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

### 2. Application Lifecycle & Package Governance
| Tool Name | Parameters | Purpose |
| :--- | :--- | :--- |
| **`android_get_current_app`** | `deviceSerial` | Identifies currently focused foreground package and active Activity. |
| **`android_launch_app`** | `package`, `deviceSerial` | Launches an installed application via default launcher category. |
| **`android_stop_app`** | `package`, `deviceSerial` | Force terminates a running application by package name. |
| **`android_clear_app_data`** | `package`, `deviceSerial` | Clears app cache and user data (resets app to fresh install state). |
| **`android_list_packages`** | `thirdPartyOnly`, `query`, `deviceSerial` | Searches and lists installed applications on the device. |

### 3. Device Telemetry, Clipboard & File Transfers
| Tool Name | Parameters | Purpose |
| :--- | :--- | :--- |
| **`android_get_device_info`** | `deviceSerial` | Reports hardware model, manufacturer, Android OS, display resolution, and battery level. |
| **`android_get_clipboard`** | `deviceSerial` | Reads the current text stored in the Android system clipboard. |
| **`android_set_clipboard`** | `text`, `deviceSerial` | Copies text directly into the Android system clipboard. |
| **`android_push_file`** | `localPath`, `remotePath`, `deviceSerial` | Uploads a file from Mac host to the Android filesystem. |
| **`android_pull_file`** | `remotePath`, `localPath`, `deviceSerial` | Downloads a file or capture from Android device to Mac host. |

---

## 💡 Example AI Assistant Prompts

Once configured, your AI assistant can execute end-to-end mobile automation autonomously:

1. **Automated Regression & UI Verification:**
   > *"Launch `com.example.app`, take a screenshot, verify that the Login button is rendered, tap it at (0.5, 0.8), and check that no crash appears in logcat."*
2. **Two-Factor Authentication & Clipboard Helper:**
   > *"Check the Android clipboard for any 6-digit OTP code, and if found, paste it into the Mac browser."*
3. **App State Reset & Clean Installation:**
   > *"Clear the app data for `com.myapp.beta`, install the new build `/Users/long/builds/app-release.apk`, and verify the initial onboarding screen."*
4. **Device Diagnostics:**
   > *"Get the device telemetry: check if the battery is above 50% and confirm the Android OS version before running the stress test suite."*

---

## 🔒 Security & Privacy
- **100% Local & P2P:** All communication travels exclusively between your AI client and local ADB daemon over standard I/O.
- **Zero Cloud Proxies:** No telemetry, analytics, or third-party relays.
