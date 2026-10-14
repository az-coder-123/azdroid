# WifiDesk — Troubleshooting & Common Issues Guide

> Step-by-step solutions for network connectivity, ADB daemon authorization, and Xiaomi permission bottlenecks.

---

## 🌐 1. Network & Connection Issues

### ❌ "No route to host" or Device Not Found When Switching Wi-Fi / Hotspot
- **Root Cause:** 
  1. Mac and phone are on different subnets, or the router has AP Isolation enabled.
  2. Switching from Home Wi-Fi (`192.168.1.x`) to Mobile Hotspot (`192.168.43.x`) leaves stale socket routes on the existing background ADB daemon on macOS (`EHOSTUNREACH`).
- **Solution:**
  1. WifiDesk now features automatic self-healing: attempting a connection automatically recycles the ADB daemon when a stale route is encountered.
  2. If connecting from CLI, run `adb kill-server && adb connect <phone-ip>:5555`.
  3. Ensure both devices share the subnet (e.g., `192.168.43.xxx`).

### ❌ Device Not Discovered Automatically on Mobile Hotspot (`192.168.43.x`)
- **Root Cause:** Android Mobile Hotspot tethering interfaces filter Multicast / mDNS packets (UDP 5353), preventing auto-discovery broadcast.
- **Solution:**
  1. Click **"Manual Connect"** in WifiDesk.
  2. Enter the phone's hotspot IP (e.g., `192.168.43.148` or `192.168.43.1`) and port `5555`.

### ❌ Connection Drops When USB Cable Is Unplugged or Network Changes
- **Root Cause:** Android 10 and older devices reset ADB TCP/IP port 5555 whenever network connectivity changes.
- **Solution:**
  1. Plug in USB cable with USB Debugging enabled.
  2. Run `adb tcpip 5555` (or click "Switch to Wi-Fi" on the USB card in WifiDesk) while the cable is attached.
  3. Unplug cable and connect via Direct IP (`<phone-ip>:5555`).

---

## 🔒 2. Authorization & ADB Errors

### ❌ Device Status Shows "Unauthorized"
- **Root Cause:** The Mac's RSA cryptographic key has not been approved on the phone.
- **Solution:**
  1. Unlock your phone screen.
  2. Look for the prompt: *"Allow USB debugging from this computer?"*.
  3. Check **"Always allow from this computer"** and tap **OK**.
  4. If the prompt does not appear, run `adb kill-server && adb start-server` in Terminal.

---

## 📱 3. Xiaomi / MIUI / HyperOS Specifics

### ❌ Mouse Clicks & Typing Are Ignored
- **Root Cause:** Xiaomi disables remote input injection by default.
- **Solution:**
  1. Open phone **Settings ➔ Additional settings ➔ Developer options**.
  2. Enable **USB debugging (Security settings)** / *Gỡ lỗi USB (Cài đặt bảo mật)*.
  3. Accept the three 5-second security warnings. (Requires SIM card inserted or Mi Account).
