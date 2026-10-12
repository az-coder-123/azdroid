# WifiDesk — User Guide & Setup Handbook

> Complete handbook for wireless screen mirroring, touch injection, keyboard navigation, and productivity features on macOS.

---

## 🚀 1. Connection Methods

WifiDesk provides 3 connection pathways adapted to your Android version and network configuration:

### Method 1: Scan QR Code (Android 11+ / 100% Wireless)
1. **On your phone:** Go to **Settings ➔ Developer Options ➔ Wireless Debugging**.
2. Tap **"Pair device with QR code"** (Ghép nối bằng mã QR).
3. **On WifiDesk:** Click **"Pair Device"** on the macOS top bar.
4. Scan the QR code displayed on your Mac with your phone camera.
5. The device pairs instantly and appears in the **Discovered Devices** list.

### Method 2: One-Time USB Activation (`adb tcpip 5555`)
*Recommended for Android 10 and older devices (e.g. Redmi 9 `M2004J19C`) lacking native Wireless Debugging:*
1. Connect your phone to your Mac via USB cable and allow USB Debugging.
2. Open Terminal on your Mac and execute:
   ```bash
   adb tcpip 5555
   ```
3. Disconnect the USB cable. Your phone ADB daemon is now listening wirelessly on port 5555.
4. On WifiDesk, click **"Direct IP"**, enter your phone IP (e.g., `192.168.1.3:5555`), and click Connect.

### Method 3: Direct IP Connection
Connect directly to any device already on your local Wi-Fi with an open ADB port:
1. Check your phone IP under **Settings ➔ Wi-Fi ➔ Current Network** (e.g., `192.168.1.3`).
2. Click **"Direct IP"** on WifiDesk, enter the IP address and port (default: 5555), and click Connect.

---

## 📱 2. Xiaomi / MIUI / HyperOS Specific Setup

Xiaomi devices enforce additional security checks that block mouse clicks and keystrokes unless explicitly authorized:

| Setting | Path in Settings | Why It's Required |
| :--- | :--- | :--- |
| **Developer Options** | About Phone ➔ Tap *MIUI version* 7 times | Unlocks developer menu |
| **USB Debugging** | Additional Settings ➔ Developer Options | Allows ADB connection |
| **USB Debugging (Security Settings)** | Additional Settings ➔ Developer Options | **Mandatory** for mouse clicks & keystroke injection |

> [!WARNING]
> Without enabling **USB debugging (Security settings)**, screen mirroring will work, but mouse clicks and keyboard typing will be ignored by MIUI.

---

## 🖱️ 3. Mouse & macOS Keyboard Gestures

### Mouse Controls
- **Left Click & Drag:** Tap, swipe, scroll, flick, and drag across the screen.
- **Right Click:** Triggers Android system **BACK** navigation.
- **Middle Click (Scroll Wheel Click):** Triggers Android system **HOME**.
- **Mouse Wheel / Trackpad 2 Fingers:** Smooth vertical and horizontal list scrolling.

### macOS Keyboard Shortcuts
- <kbd>Cmd</kbd> + <kbd>H</kbd>: Go to Home Screen.
- <kbd>Cmd</kbd> + <kbd>Backspace</kbd>: Back key.
- <kbd>Cmd</kbd> + <kbd>Tab</kbd>: App Switcher (Recent Apps).
- <kbd>Cmd</kbd> + <kbd>K</kbd>: Quick Text Injector (Direct Unicode & Vietnamese accents).
- <kbd>Cmd</kbd> + <kbd>R</kbd>: Rotate display 90 degrees.
- <kbd>Cmd</kbd> + <kbd>O</kbd>: Turn phone screen off/on (`--turn-screen-off`).

---

## 📁 4. Productivity Features

### Drag & Drop File Transfers
- Drag any photo, video, or document from **macOS Finder** and drop it onto the streaming window. Files are automatically transferred to `/sdcard/Download/`.
- Drag an `.apk` package to install and sideload the app directly with live transfer progress.

### Bidirectional Clipboard Sync
- Text copied on macOS (<kbd>Cmd</kbd> + <kbd>C</kbd>) is automatically synced to the Android clipboard.
- Text copied on Android is instantly available on macOS (<kbd>Cmd</kbd> + <kbd>V</kbd>).

### Low-Latency Audio Streaming
- Android device audio is forwarded directly to your Mac speakers over 48kHz stereo Opus/PCM.

---

## 🔧 5. Troubleshooting & FAQ

#### 1. "No route to host" or cannot connect
- Ensure both Mac and Android are connected to the **same Wi-Fi network**.
- Check for **AP Isolation** on cafe/university Wi-Fi networks (use your home Wi-Fi or create an iPhone/Mac hotspot).

#### 2. Mouse clicks do nothing on Xiaomi
- Verify that **USB debugging (Security settings)** is turned ON in Developer options.

#### 3. Device status says "Unauthorized"
- Check your phone screen and tap **"Always allow from this computer"** on the USB debugging authorization dialog.
