# DeskDroid — Troubleshooting & Common Issues Guide

> Step-by-step solutions for network connectivity, ADB daemon authorization, Xiaomi permission bottlenecks, and Windows-specific setup issues.

---

## 🌐 1. Network & Connection Issues

### ❌ "No route to host" or Device Not Found When Switching Wi-Fi / Hotspot
- **Root Cause:** 
  1. Computer and phone are on different subnets, or the router has AP Isolation enabled.
  2. Switching from Home Wi-Fi (`192.168.1.x`) to Mobile Hotspot (`192.168.43.x`) leaves stale socket routes on the existing background ADB daemon on macOS (`EHOSTUNREACH`).
- **Solution:**
  1. DeskDroid now features automatic self-healing: attempting a connection automatically recycles the ADB daemon when a stale route is encountered.
  2. If connecting from CLI, run `adb kill-server && adb connect <phone-ip>:5555`.
  3. Ensure both devices share the subnet (e.g., `192.168.43.xxx`).

### ❌ Device Not Discovered Automatically on Mobile Hotspot (`192.168.43.x`)
- **Root Cause:** Android Mobile Hotspot tethering interfaces filter Multicast / mDNS packets (UDP 5353), preventing auto-discovery broadcast.
- **Solution:**
  1. Click **"Manual Connect"** in DeskDroid.
  2. Enter the phone's hotspot IP (e.g., `192.168.43.148` or `192.168.43.1`) and port `5555`.

### ❌ Connection Drops When USB Cable Is Unplugged or Network Changes
- **Root Cause:** Android 10 and older devices reset ADB TCP/IP port 5555 whenever network connectivity changes.
- **Solution:**
  1. Plug in USB cable with USB Debugging enabled.
  2. Run `adb tcpip 5555` (or click "Switch to Wi-Fi" on the USB card in DeskDroid) while the cable is attached.
  3. Unplug cable and connect via Direct IP (`<phone-ip>:5555`).

> 💡 **Deep Dive:** For technical root-cause analyses and self-healing daemon architecture, see [docs/lessons-learned/mobile-hotspot-adb-routing.md](lessons-learned/mobile-hotspot-adb-routing.md).

---

## 🔒 2. Authorization & ADB Errors

### ❌ Device Status Shows "Unauthorized"
- **Symptom:** The mirroring page shows *"USB debugging is not allowed on (device name) yet"*, or the device list marks the device as unauthorized. Logcat stays empty.
- **Root Cause:** This computer's ADB key has not been approved on the phone. Each computer has its own key in `~/.android/adbkey` (`%USERPROFILE%\.android\adbkey` on Windows), so a phone that trusts your Mac must still approve your Windows PC.
- **Solution:**
  1. Unlock your phone screen.
  2. Look for the prompt: *"Allow USB debugging from this computer?"*.
  3. Check **"Always allow from this computer"** and tap **OK**.
  4. If the prompt does not appear on a Wi-Fi connection, reconnect to show it again: `adb disconnect <ip>:5555` then `adb connect <ip>:5555`.
  5. If it still does not appear, restart ADB: `adb kill-server` then `adb start-server`.
  6. Tap **Retry Connection** on the mirroring page.

---

## 📱 3. Xiaomi / MIUI / HyperOS Specifics

### ❌ Mouse Clicks & Typing Are Ignored
- **Root Cause:** Xiaomi disables remote input injection by default.
- **Solution:**
  1. Open phone **Settings ➔ Additional settings ➔ Developer options**.
  2. Enable **USB debugging (Security settings)** / *Gỡ lỗi USB (Cài đặt bảo mật)*.
  3. Accept the three 5-second security warnings. (Requires SIM card inserted or Mi Account).

> 💡 **Deep Dive:** For technical root-cause analyses on MIUI security and IME fallback, see [docs/lessons-learned/xiaomi-miui-input-security-restrictions.md](lessons-learned/xiaomi-miui-input-security-restrictions.md).

---

## 🪟 4. Windows Specifics (Preview)

### ❌ "Windows protected your PC" When Starting DeskDroid

- **Root Cause:** Release builds are not code-signed, so SmartScreen does not recognize the publisher.
- **Solution:** Click **More info**, then **Run anyway**. Check the ZIP against `SHA256SUMS-windows.txt` first (see [installation.md](installation.md#5-package-a-release)).

### ❌ "VCRUNTIME140.dll" or "MSVCP140.dll" Was Not Found

- **Root Cause:** The Visual C++ runtime is missing. Release ZIPs normally include it, but a ZIP built on a machine without the redistributable files does not.
- **Solution:** Install the [Microsoft Visual C++ Redistributable (x64)](https://aka.ms/vs/17/release/vc_redist.x64.exe), then start DeskDroid again.

### ❌ "ADB executable not found" After Installing Platform Tools

- **Root Cause:** `winget` adds ADB to `PATH`, but programs that were already open keep the old `PATH`.
- **Solution:** Close and reopen DeskDroid (and the terminal, if you started it from one). Check with `where adb`. Alternatively set `ANDROID_HOME` to your SDK folder.

### ❌ Phone Connected by USB Does Not Appear

- **Root Cause:** Windows has no ADB driver for the phone.
- **Solution:** Install the [Google USB Driver](https://developer.android.com/studio/run/win-usb) (Pixel and many others) or the driver from your phone maker, then reconnect the cable. `adb devices` must list the phone. Wi-Fi connections need no driver.

### 🔍 Where Are the Logs?

- `%TEMP%\deskdroid_dart.log`: app log (connections, ADB commands, stream state).
- `%TEMP%\scrcpy_stream.log`: native video plugin log (socket, header, decoder, frames).

---

## 💡 Engineering Case Studies & Post-Mortems
For comprehensive low-level post-mortems covering video frame decoders, macOS sandbox entitlements, process signals, and device topology deduplication, refer to the [Engineering Lessons Learned Repository](lessons-learned/README.md).

