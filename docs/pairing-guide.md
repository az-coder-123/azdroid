# Azdroid — Wireless Pairing Guide

> Step-by-step wireless discovery, 1-click USB switch, and 6-digit PIN pairing instructions for Android devices.

---

## 💡 Understanding Host IP vs. Phone IP

When configuring wireless connections, distinguish between these two addresses:

1. **Computer IP (Shown in Azdroid Pairing Dialog):**
   - The local IP address of your computer (Mac or Windows PC) on your Wi-Fi network (e.g. `192.168.1.15`).
   - Displayed in the top banner of the Pairing Dialog so you can verify that your computer and phone are on the same local subnet.
2. **Phone IP (Shown in Android Settings):**
   - The local IP address of your phone (e.g. `192.168.1.35`).
   - Located on your phone under **Settings ➔ Developer Options ➔ Wireless Debugging** or **Settings ➔ Wi-Fi ➔ Network Details**.
   - Used when connecting via **6-Digit Wi-Fi PIN** or **Direct IP**.

> [!NOTE]
> Both your computer and your phone must be connected to the exact same Wi-Fi SSID and local subnet.

---

## 🔌 Method 1: 1-Click USB to Wi-Fi Switch (Easiest & Zero-Config)

*Recommended for all Android devices (Android 5 through 15) for a foolproof setup:*

1. Plug your phone into your computer with a USB cable (Windows may need the [Google USB Driver](https://developer.android.com/studio/run/win-usb) or your phone maker's driver).
2. Tap **"Allow USB debugging"** on your phone screen when prompted.
3. Azdroid immediately detects your phone under **Discovered Devices**.
4. Click the **"Wi-Fi Mode"** button on the device card.
   - Azdroid automatically queries the phone's internal Wi-Fi IP address via `adb shell ip`.
   - Azdroid switches the ADB daemon to TCP mode (`adb tcpip 5555`).
   - Azdroid connects wirelessly (`adb connect <phone-ip>:5555`).
5. Unplug the USB cable! Your phone remains connected wirelessly.

> [!TIP]
> No Terminal commands or manual IP entry needed. The TCP/IP port 5555 stays active until the phone is restarted.

---

## 🔢 Method 2: Android 11+ Wireless 6-Digit PIN Pairing (100% Cable-Free)

*For Android 11+ devices without needing a USB cable:*

1. Under **Settings ➔ Developer Options ➔ Wireless Debugging**, toggle **Wireless Debugging** to ON.
2. Tap **"Pair device with pairing code"** (*Ghép nối bằng mã ghép nối*).
3. Note the three values shown on the phone pop-up:
   - **Device IP address** (e.g., `192.168.1.35`)
   - **Pairing Port** (e.g., `37129` — note: this is the *pairing* port, not port 5555)
   - **6-Digit Pairing Code** (e.g., `123456`)
4. On Azdroid: Click **"Pair with Wi-Fi Code"** on the top bar or empty state screen.
5. Enter the IP, port, and 6-digit code.
6. Click **"Pair & Connect"**.

> [!IMPORTANT]
> Keep the pairing pop-up visible on your phone screen until Azdroid confirms successful pairing. Closing the pop-up on your phone cancels the temporary pairing PIN.

---

## ⚡️ Method 3: Direct IP Connection & Recent Devices

1. **Recent Devices:** If you previously connected to a device, Azdroid persists it in `history.json`. Click any device chip under **"Recent Devices"** on the empty state screen to reconnect in 1 click!
2. **Direct IP:** Click **"Direct IP"**, enter your phone IP and port (default: 5555), and click **Connect**.

---

## 📱 Xiaomi / MIUI / HyperOS Specific Instructions

Xiaomi devices have additional security layers that must be enabled:

1. **Enable Developer Options:**
   - Go to **Settings ➔ About phone**.
   - Tap **OS version** or **MIUI version** repeatedly (7 times) until *"You are now a developer!"* appears.
2. **Enable Required Debugging Flags:**
   - Go to **Settings ➔ Additional settings ➔ Developer options**.
   - Enable **USB debugging**.
   - Enable **Install via USB**.
   - Enable **USB debugging (Security settings)** (*Gỡ lỗi USB - Cài đặt bảo mật*).
     - *Note:* Xiaomi requires an active Mi Account and SIM card to toggle Security settings. You will be asked to confirm 3 security prompts (5 seconds each).
3. **If Wireless Debugging Fails on Xiaomi:**
   - Use **Method 1 (1-Click USB to Wi-Fi Switch)** with USB cable first. This reliably bypasses MIUI wireless pairing restrictions.
   - If mouse clicks or keyboard typing are ignored during screen mirroring, verify that **USB debugging (Security settings)** is turned ON.
