# DeskDroid — User Guide & Setup Handbook

> Complete handbook for host requirements (macOS and Windows), Android device configuration, wireless screen mirroring, touch injection, and productivity features. Installing the app itself: [installation.md](installation.md). What works on each platform: [platform-support.md](platform-support.md).

---

## 🛠️ 1. Required Tools & Prerequisites

### 1.1 Computer Preparation
DeskDroid needs the Android Debug Bridge (`adb`). **Release builds bundle it**, so nothing has to be installed. If `adb` is already installed (Android Studio, Homebrew, winget), DeskDroid uses that copy instead, so only one adb version runs on your computer. Details: [bundled-platform-tools.md](bundled-platform-tools.md).

#### macOS

- **Optional — installing ADB via Homebrew** (useful if you also run `adb` in Terminal):
  ```bash
  brew install android-platform-tools
  ```
- **If Android Studio is already installed:** DeskDroid detects ADB inside your Android SDK (`~/Library/Android/sdk/platform-tools/adb`). No extra installation is needed.
- **Automated Path Discovery:** DeskDroid searches these locations without manual configuration:
  - Android SDK: `~/Library/Android/sdk/platform-tools/adb`
  - Apple Silicon Homebrew: `/opt/homebrew/bin/adb`
  - Intel Mac Homebrew: `/usr/local/bin/adb`
  - Current shell `$PATH` via `which adb`
  - Bundled copy inside the app (`DeskDroid.app/Contents/MacOS/adb`), used last

#### Windows (Preview)

- **Optional — installing ADB via winget** (useful if you also run `adb` in a terminal):
  ```powershell
  winget install Google.PlatformTools
  ```
  Restart DeskDroid afterwards so it sees the updated `PATH`. Without it, DeskDroid uses the `adb.exe` bundled next to `desk_droid.exe`.
- **If Android Studio is already installed:** DeskDroid detects ADB inside your Android SDK (`%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe`, or the folder in `ANDROID_HOME`).
- **USB connections** may need the [Google USB Driver](https://developer.android.com/studio/run/win-usb) or your phone maker's driver. Wi-Fi connections need no driver.

> [!NOTE]
> You do **not** need to install `scrcpy` or `ffmpeg`. The `scrcpy-server.jar` daemon is bundled inside DeskDroid. Video is decoded natively: **Apple VideoToolbox** on macOS, **Media Foundation** on Windows.

### 1.2 Android Device Preparation

#### Step 1: Unlock Developer Options
1. Open phone **Settings ➔ About phone** (or *About device*).
2. Tap **Build number** (or **MIUI / OS version** on Xiaomi) **7 times** until the toast *"You are now a developer!"* appears.

#### Step 2: Enable Debugging
1. Open **Settings ➔ System ➔ Developer options** (or *Additional settings ➔ Developer options*).
2. Toggle **USB debugging** to **ON**.
3. For Android 11+: Toggle **Wireless debugging** to **ON** (required for 100% cable-free pairing).

#### Step 3: Authorize This Computer
When connecting for the first time via USB or Wi-Fi, an authorization dialog appears on your phone screen:
- Check **"Always allow from this computer"** and tap **Allow**.
- Each computer has its own ADB key, so a phone that already trusts your Mac asks again for your Windows PC (and the other way round).

#### Step 4: Brand-Specific Permissions (Crucial)
- **Xiaomi / Redmi / POCO (MIUI & HyperOS):**
  You **must** turn ON **USB debugging (Security settings)** (*Gỡ lỗi USB - Cài đặt bảo mật*) in Developer options. Without this, Xiaomi blocks mouse clicks and keystrokes from desktop apps.
  *(Requires inserting a SIM card and signing into a Mi Account to toggle; accept 3 consecutive 5-second security warnings).*
- **Oppo / Realme / OnePlus (ColorOS / OxygenOS):**
  If touch events are blocked, turn ON **"Disable permission monitoring"** in Developer options.
- **Samsung / Google Pixel / Motorola:**
  Standard **USB debugging** is sufficient without extra flags.

---

## 🚀 2. Connection Methods

DeskDroid provides 3 connection pathways:

### Method 1: 1-Click USB to Wi-Fi Switch (Easiest & Most Reliable)
1. Plug your phone into your computer via USB cable.
2. Allow USB Debugging on your phone.
3. Your phone immediately appears under **Discovered Devices**.
4. Click **"Wi-Fi Mode"** on the device card. DeskDroid automatically switches ADB to wireless TCP mode (`adb tcpip 5555`) and establishes the wireless connection.
5. Unplug the USB cable! Mirroring continues smoothly over Wi-Fi.

### Method 2: Wireless 6-Digit PIN Pairing (Android 11+ Cable-Free)
1. On your phone: Go to **Settings ➔ Developer Options ➔ Wireless Debugging**.
2. Tap **"Pair device with pairing code"** (*Ghép nối bằng mã ghép nối*).
3. On DeskDroid: Click **"Pair with Wi-Fi Code"** on the top toolbar.
4. Enter the IP, port, and 6-digit code shown on your phone screen, then click **Pair & Connect**.

### Method 3: Direct IP Connection
1. Find your phone's local IP address under **Settings ➔ Wi-Fi ➔ Current Network Details** (e.g. `192.168.1.35`).
2. Click **"Direct IP"** on DeskDroid, enter the IP address (port defaults to 5555), and click **Connect**.

---

## 🖱️ 3. Mouse & Keyboard Gestures

### Mouse Controls
- **Left Click & Drag:** Tap, swipe, scroll, flick, and drag across the screen.
- **Right Click:** Triggers Android system **BACK** navigation.
- **Middle Click (Scroll Wheel Click):** Triggers Android system **HOME**.
- **Mouse Wheel / Trackpad 2 Fingers:** Smooth vertical and horizontal list scrolling.

### Keyboard Shortcuts

Shown with <kbd>Cmd</kbd> (macOS). On Windows use <kbd>Ctrl</kbd> instead, for example <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>S</kbd>.

- <kbd>Cmd</kbd> + <kbd>H</kbd>: Go to Home Screen.
- <kbd>Cmd</kbd> + <kbd>Backspace</kbd>: Back key.
- <kbd>Cmd</kbd> + <kbd>Tab</kbd>: App Switcher (Recent Apps).
- <kbd>Cmd</kbd> + <kbd>S</kbd>: Full Screenshot to your Downloads folder & clipboard.
- <kbd>Cmd</kbd> + <kbd>Shift</kbd> + <kbd>S</kbd>: Area Screenshot crop.
- <kbd>Cmd</kbd> + <kbd>Shift</kbd> + <kbd>R</kbd>: Hardware MP4 Screen Recording.
- <kbd>Cmd</kbd> + <kbd>U</kbd>: Send Files / APK with the native file picker.
- <kbd>Cmd</kbd> + <kbd>Shift</kbd> + <kbd>F</kbd>: Open Android File Explorer.
- <kbd>Cmd</kbd> + <kbd>Shift</kbd> + <kbd>I</kbd>: Open APK Sideload & Package Manager.
- <kbd>Cmd</kbd> + <kbd>Shift</kbd> + <kbd>L</kbd>: Open Real-Time Device Logcat Console.
- <kbd>Cmd</kbd> + <kbd>K</kbd>: Quick Text Injector (Direct Unicode & Vietnamese accents).
- <kbd>Cmd</kbd> + <kbd>R</kbd>: Rotate display 90 degrees.
- <kbd>Cmd</kbd> + <kbd>O</kbd>: Turn phone screen off/on (`--turn-screen-off`).

---

## 📁 4. Productivity Features

### Drag & Drop & File Picker Transfers
- Press <kbd>Cmd</kbd> + <kbd>U</kbd> or click the toolbar upload icon to select files via the native file dialog (Finder on macOS, File Explorer on Windows).
- Drag files, photos, or documents directly from Finder or File Explorer onto the stream to push to `/sdcard/Download/`.
- Sideload `.apk` packages automatically upon drop or selection.

### APK Sideload & Package Manager
- Press <kbd>Cmd</kbd> + <kbd>Shift</kbd> + <kbd>I</kbd> or click the package icon on the vertical dock.
- Select any `.apk` file to inspect package name, version, SDK requirements, and file size.
- Configure install flags (`-r`, `-g`, `-t`, `-d`) and click **Install APK**.
- Provides 1-click **Launch App** and **Uninstall** upon completion with automated error diagnosis for permission or signature conflicts.

### Device File Explorer & Pull to Computer
- Press <kbd>Cmd</kbd> + <kbd>Shift</kbd> + <kbd>F</kbd> or click the folder icon on the side dock to browse Android storage (`Downloads`, `DCIM`, `Screenshots`, `Movies`, and `SD Card`).
- Select files and download them directly to the `DeskDroid` folder inside your Downloads folder, with 1-click reveal in Finder or File Explorer.

### Real-Time Device Logcat Console & Debugging
- Press <kbd>Cmd</kbd> + <kbd>Shift</kbd> + <kbd>L</kbd> or click **Logs** on any device card to launch the live Logcat Console.
- **Filter Presets:** Use the Preset dropdown menu (top-left) to switch between *All*, *Crashes & ANRs*, *Network & HTTP*, *Audio & Media*, *Android System*, or *Starred Only*.
- **Multi-Tier Filtering:** Filter by minimum priority level (`V`, `D`, `I`, `W`, `E`, `F`), text query, regular expressions, dynamic Tag, and PID.
- **Exclude Tags:** Exclude spammy system tags by clicking **Exclude Tag** in the drawer or managing `-tag` chips with 1-click removal.
- **Bookmarking (Star Logs):** Click the star icon on any log row to bookmark it. Toggle the **Starred** filter chip to isolate flagged logs during testing.
- **Detail Drawer & Stack Trace Viewer:** Click any log row to open the side inspector drawer. View full metadata, colored Java/Kotlin stack traces, and click **Format JSON** to pretty-print JSON payloads.
- **Toggle Soft-Wrap:** Click the wrap icon in the footer to toggle between multi-line text wrapping and single-line fixed-extent virtualized scrolling (60 FPS).
- **Pause & Disk Recording:** Click **Pause** to freeze the log stream for inspection, or click **Record** to continuously save streaming logs to `deskdroid_logs/logcat_<serial>_<yyyyMMdd_HHmmss>.log` inside your Downloads folder.

### Bidirectional Clipboard Sync
- Text copied on the computer (<kbd>Cmd</kbd>/<kbd>Ctrl</kbd> + <kbd>C</kbd>) is automatically synced to the Android clipboard.
- Text copied on Android is instantly available on the computer (<kbd>Cmd</kbd>/<kbd>Ctrl</kbd> + <kbd>V</kbd>).

---

## 🔧 5. Troubleshooting & FAQ

#### 1. "No route to host" or cannot connect
- Ensure both the computer and Android are connected to the **same Wi-Fi network**.
- Check for **AP Isolation** on cafe/public Wi-Fi networks (use a home network or a hotspot from the computer).

#### 2. Mouse clicks do nothing on Xiaomi
- Verify that **USB debugging (Security settings)** is turned ON in Developer options.

#### 3. Device status says "Unauthorized"
- Check your phone screen and tap **"Always allow from this computer"** on the USB debugging authorization dialog.
