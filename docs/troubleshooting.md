# WifiDesk — Troubleshooting & Common Issues Guide

> Step-by-step solutions for network connectivity, ADB daemon authorization, and Xiaomi permission bottlenecks.

---

## 🌐 1. Network & Connection Issues

### ❌ "No route to host" or Device Not Found
- **Root Cause:** Mac and phone are on different subnets, or the router has AP Isolation enabled.
- **Solution:**
  1. Ensure both your Mac and Android phone are connected to the exact same Wi-Fi SSID.
  2. Verify your Mac Wi-Fi IP and phone IP share the same prefix (e.g., `192.168.1.xxx`).
  3. On public or university networks where peer-to-peer traffic is blocked, enable a **Personal Hotspot** from your phone or Mac.

### ❌ Connection Drops When USB Cable Is Unplugged
- **Root Cause:** Android 10 and older devices require explicit Wi-Fi mode activation before unplugging.
- **Solution:**
  1. Plug in USB cable with USB Debugging enabled.
  2. Run `adb tcpip 5555` in Terminal while the cable is still attached.
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
