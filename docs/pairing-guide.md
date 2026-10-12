# WifiDesk — Wireless Pairing Guide

> Step-by-step wireless discovery, QR pairing, and USB TCP/IP instructions for Android devices.

---

## 💡 Understanding Host IP vs. Phone IP

When configuring wireless connections, distinguish between these two addresses:

1. **Host Mac IP (Shown in WifiDesk Pairing Dialog):**
   - The local IP address of your Mac on your Wi-Fi network (e.g. `192.168.1.15`).
   - Displayed in the top banner of the Pairing Dialog so you can verify that your Mac and phone are on the same local subnet.
2. **Phone IP (Shown in Android Settings):**
   - The local IP address of your phone (e.g. `192.168.1.35`).
   - Located on your phone under **Settings ➔ Developer Options ➔ Wireless Debugging** or **Settings ➔ Wi-Fi ➔ Network Details**.
   - Used when connecting via **Manual 6-Digit PIN** or **Direct IP**.

> [!NOTE]
> Both your Mac and your phone must be connected to the exact same Wi-Fi SSID and local subnet.

---

## 📷 Method 1: QR Code Pairing (Android 11+)

1. Connect your phone to the same Wi-Fi as your Mac.
2. On your phone: Go to **Settings ➔ Additional Settings ➔ Developer Options ➔ Wireless Debugging**.
3. Toggle **Wireless Debugging** to ON.
4. Tap **"Pair device with QR code"** (*Ghép nối thiết bị bằng mã QR*).
5. On WifiDesk: Click **"Pair Device"** on the macOS top bar.
6. Point your phone camera at the QR code displayed on the Mac screen.
7. Once recognized, the phone pairs and appears in WifiDesk's **Discovered Devices** list.

---

## 🔢 Method 2: Manual 6-Digit PIN (Android 11+)

If your phone camera cannot scan the QR code:

1. Under **Wireless Debugging**, tap **"Pair device with pairing code"** (*Ghép nối bằng mã ghép nối*).
2. Note the three values shown on the phone pop-up:
   - **Device IP address** (e.g., `192.168.1.35`)
   - **Pairing Port** (e.g., `37129` — note: this is the *pairing* port, not the connect port)
   - **6-Digit Pairing Code** (e.g., `123456`)
3. On WifiDesk: Click **"Pair Device"** ➔ **"Manual 6-Digit PIN"** tab.
4. Enter the IP, port, and 6-digit code.
5. Click **"Pair & Connect"**.

> [!IMPORTANT]
> Keep the pairing pop-up visible on your phone screen until WifiDesk confirms successful pairing. Closing the pop-up on your phone cancels the temporary pairing PIN.

---

## 🔌 Method 3: One-Time USB Activation (`adb tcpip 5555`)

*Recommended for Android 10 and older, or devices where Wireless Debugging is unavailable:*

1. Connect your phone to your Mac using a USB cable.
2. Ensure **USB Debugging** is turned ON in Developer Options.
3. Open Terminal on your Mac and run:
   ```bash
   adb tcpip 5555
   ```
   *(Expected output: `restarting in TCP mode port: 5555`)*
4. Disconnect the USB cable.
5. Check your phone IP under **Settings ➔ Wi-Fi** (e.g., `192.168.1.35`).
6. On WifiDesk: Click **"Direct IP"**, enter `<phone-ip>:5555`, and click **Connect**.

> [!TIP]
> The TCP/IP port 5555 stays active until the phone is restarted or powered off.

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
   - Use **Method 3 (`adb tcpip 5555`)** with USB cable first. This bypasses MIUI wireless pairing restrictions reliably.
   - If clicks or typing are ignored in mirrored screen, verify that **USB debugging (Security settings)** is turned ON.

