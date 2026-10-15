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

## 🛠️ Published MCP Tools

| Tool Name | Parameters | Purpose |
| :--- | :--- | :--- |
| **`android_list_devices`** | *none* | Lists all connected USB and Wi-Fi Android devices and their status. |
| **`android_take_screenshot`** | `deviceSerial` (optional) | Returns high-resolution screenshot as a base64 image artifact for visual inspection. |
| **`android_tap`** | `x`, `y` (normalized 0.0–1.0 or pixels), `deviceSerial` | Simulates a touch tap gesture on screen. |
| **`android_swipe`** | `startX`, `startY`, `endX`, `endY`, `durationMs` | Injects a swipe or drag gesture. |
| **`android_type_text`** | `text`, `deviceSerial` | Types text into the focused Android input field (supports Unicode & spaces). |
| **`android_press_key`** | `key` (`BACK`, `HOME`, `APP_SWITCH`, `ENTER`, `TAB`, `POWER`) | Presses Android hardware/navigation keys. |
| **`android_dispatch_intent`** | `action`, `dataUri`, `package`, `component`, `extras` | Dispatches Android Intents, deep link URLs, and custom app schemes. |
| **`android_get_logcat`** | `tag`, `minLevel`, `limit` | Retrieves real-time or recent logcat records for crash diagnosis. |
| **`android_install_apk`** | `apkPath`, `reinstall`, `grantPermissions` | Sideloads an APK package onto the device. |
| **`android_shell_command`** | `command`, `deviceSerial` | Runs raw ADB shell commands for advanced diagnostics. |

---

## 💡 Example AI Assistant Prompts

Once configured, your AI assistant can execute complex mobile workflows autonomously:

1. **Visual App Inspection:**
   > *"Take a screenshot of the connected phone and verify that the checkout button is visible without layout overflow."*
2. **Automated Testing:**
   > *"Open my app via deep link `myapp://checkout/cart`, tap the promo code field at (0.5, 0.45), type 'DISCOUNT2026', and press Enter."*
3. **Crash Investigation:**
   > *"Run the app. If a crash occurs, pull the last 100 lines of Logcat filtered by tag 'FATAL' and explain the stack trace."*

---

## 🔒 Security & Privacy
- **100% Local & P2P:** All communication travels exclusively between your AI client and local ADB daemon over standard I/O.
- **Zero Cloud Proxies:** No telemetry, analytics, or third-party relays.
