# WifiDesk — Wireless Pairing Guide

> Step-by-step wireless discovery and pairing instructions for Android devices.

---

## 📷 Method 1: QR Code Pairing (Android 11+)

1. On your phone: Go to **Settings ➔ Developer Options ➔ Wireless Debugging**.
2. Select **"Pair device with QR code"**.
3. On WifiDesk: Click **"Pair Device"** on the top bar.
4. Scan the displayed QR code with your phone camera.
5. The device will be paired and appear in the Discovered Devices list.

---

## 🔢 Method 2: Manual 6-Digit PIN (Android 11+)

1. On your phone: Tap **"Pair device with pairing code"** under Wireless Debugging.
2. Note the **Phone IP**, **Pairing Port**, and **6-Digit PIN** displayed.
3. On WifiDesk: Click **"Pair Device" ➔ "Manual 6-Digit PIN"** tab.
4. Enter the details and click **"Pair & Connect"**.

---

## 🔌 Method 3: USB TCPIP Mode (Android 10 & Older)

1. Connect the phone via USB cable with **USB Debugging** enabled.
2. Run in Mac Terminal:
   ```bash
   adb tcpip 5555
   ```
3. Disconnect the cable.
4. On WifiDesk: Click **"Direct IP"**, input `<phone-ip>:5555`, and connect.
