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

### ❌ "adb server version doesn't match this client; killing..."
- **Symptom:** Devices disconnect and reconnect repeatedly, often while Android Studio or another tool is open.
- **Root Cause:** Two different adb versions are used on one computer, for example DeskDroid's bundled adb and Android Studio's. Each one restarts the shared adb server with its own version.
- **Solution:** DeskDroid already prefers an installed adb over its bundled copy. If you installed adb *after* starting DeskDroid, restart DeskDroid so it picks the installed one. Check which adb DeskDroid uses in the app log (`ADB` lines). See [bundled-platform-tools.md](bundled-platform-tools.md#3-which-adb-is-used).

---

## 🎞️ 3. Mirroring & Video

### ❌ No Video on Android 15 or 16 (Black Screen, Mirroring Never Starts)
- **Root Cause:** DeskDroid builds before scrcpy-server v3.3.4 used an Android API that Google removed in Android 14 QPR3 (`SurfaceControl.createDisplay`). The app log shows `[scrcpy] [server] ERROR: … NoSuchMethodException`.
- **Solution:** Update DeskDroid. The bundled server (v3.3.4) captures the screen through the new `DisplayManager` API.

### ❌ Mirroring Waits While the Phone Screen Is Off
- **Root Cause:** Android produces no frames for a screen that is off. DeskDroid asks the server to turn the screen on when mirroring starts, but a PIN or pattern lock still blocks input.
- **Solution:** Unlock the phone. The stream starts as soon as the screen is on.

### ❌ "The input channel did not open"
- **Root Cause:** The video connected, but the scrcpy control socket did not. DeskDroid stops the session instead of showing a mirror that ignores clicks.
- **Solution:** Unlock the phone and tap **Retry Connection**. If it keeps failing, disconnect and reconnect the device.

### ❌ The Mirror Stops Updating After Turning the Phone Screen Off
- **Root Cause:** Screen Off keeps the phone awake, but its own screen timeout still runs. With **Keep Phone Awake** off, the phone goes to sleep when the timeout ends. Pressing the phone's power button while the screen is off also puts it to sleep.
- **Solution:** Keep **Keep Phone Awake** on (sun icon) while using Screen Off. To recover, wake the phone with its power button, unlock it, and press <kbd>Cmd</kbd> + <kbd>O</kbd> again.

### ❌ The Phone's Screen Timeout Is 24 Hours After Mirroring
- **Root Cause:** With **Keep Phone Awake** on, DeskDroid sets the phone's screen timeout to 24 hours and "Stay awake while charging" on during mirroring. A restore process on the phone puts the old values back when mirroring stops. If the phone restarts or its battery runs out during mirroring, that process never runs.
- **Solution:** Set the screen timeout in the phone's display settings (and **Developer options → Stay awake**) back to what you want. To avoid it, turn off Keep Phone Awake (sun icon in the side dock) before long unattended sessions.

### ❌ "scrcpy-server on the device is not vX" in the App Log
- **Root Cause:** The jar on the phone is an older version (for example when `adb push` failed for lack of storage). The server exits on a version mismatch.
- **Solution:** Free some storage on the phone and start mirroring again; DeskDroid pushes its jar on every start. The log shows `scrcpy-server.jar push failed: …` when the push itself fails.

---

## 📱 4. Xiaomi / MIUI / HyperOS Specifics

### ❌ Mouse Clicks & Typing Are Ignored
- **Root Cause:** Xiaomi disables remote input injection by default.
- **Solution:**
  1. Open phone **Settings ➔ Additional settings ➔ Developer options**.
  2. Enable **USB debugging (Security settings)** / *Gỡ lỗi USB (Cài đặt bảo mật)*.
  3. Accept the three 5-second security warnings. (Requires SIM card inserted or Mi Account).

> 💡 **Deep Dive:** For technical root-cause analyses on MIUI security and IME fallback, see [docs/lessons-learned/xiaomi-miui-input-security-restrictions.md](lessons-learned/xiaomi-miui-input-security-restrictions.md).

---

## 🪟 5. Windows Specifics (Preview)

### ❌ "Windows protected your PC" When Starting DeskDroid

- **Root Cause:** Release builds are not code-signed, so SmartScreen does not recognize the publisher.
- **Solution:** Click **More info**, then **Run anyway**. Check the ZIP against `SHA256SUMS-windows.txt` first (see [installation.md](installation.md#5-package-a-release)).

### ❌ "VCRUNTIME140.dll" or "MSVCP140.dll" Was Not Found

- **Root Cause:** The Visual C++ runtime is missing. Release ZIPs normally include it, but a ZIP built on a machine without the redistributable files does not.
- **Solution:** Install the [Microsoft Visual C++ Redistributable (x64)](https://aka.ms/vs/17/release/vc_redist.x64.exe), then start DeskDroid again.

### ❌ "ADB executable not found" After Installing Platform Tools

- **Root Cause:** Release builds bundle `adb.exe`, so this only appears in builds without it (for example a local build made before `dart run tool/fetch_platform_tools.dart`). Otherwise `winget` adds ADB to `PATH`, but programs that were already open keep the old `PATH`.
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

