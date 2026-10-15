# Feature: Remote Input & Gesture Control

> **Subsystem:** `lib/features/control/`  
> **Key Interfaces:** `ControlRepository`, `ControlDatasource`  
> **Presentation:** `ControlBloc`, `InputGestureViewportOverlay`, `QuickTextInputDialog`, `TouchIndicatorOverlay`

---

## 📌 Overview

WifiDesk transforms your Mac trackpad, mouse, and keyboard into native Android input controllers. Mouse pointer actions and trackpad gestures are normalized and injected with millisecond responsiveness over binary socket channels.

```mermaid
flowchart LR
    MacInput["Mac Mouse / Trackpad / Keyboard\n(Listener & Raw Events)"] --> Viewport["InputGestureViewportOverlay\n(Coordinate Normalization 0.0 - 1.0)"]
    Viewport --> Bloc["ControlBloc\n(Event Throttling & Debouncing)"]
    Bloc --> Socket["Control Socket\n(Binary Touch / Key Packets)"]
    Socket --> Android["scrcpy-server Daemon\n(Android InputManager Injection)"]
```

---

## ⚡️ Key Capabilities

### 1. Advanced Pointer & Multi-Touch Emulation
- **Coordinate Normalization:** Normalizes cursor coordinates ($0.0 \to 1.0$) relative to the active video viewport, ensuring precision across arbitrary window sizes and device display resolutions.
- **Mouse Button Mapping:**
  - **Left Click & Drag:** Natural touch down, drag/swipe, and touch up.
  - **Right Click:** Triggers Android system **BACK** navigation (`KEYCODE_BACK`).
  - **Middle Click (Wheel Click):** Triggers Android system **HOME** (`KEYCODE_HOME`).
- **Visual Feedback:** `TouchIndicatorOverlay` renders an Apple-styled animated ripple at the pointer contact point.

### 2. Smooth Inertial Trackpad & Wheel Scrolling
- **Gesture Conversion:** Converts macOS two-finger trackpad flicks and mouse wheel rotations into natural Android scroll events (`AMOTION_EVENT_AXIS_VSCROLL` and `HSCROLL`).
- **Directional Fidelity:** Supports horizontal and vertical scrolling with adjustable sensitivity to mimic native mobile inertia.

### 3. Hardware Keyboard Forwarding & Android Shortcuts
- **Direct Keystroke Translation:** Maps macOS physical keys directly to Linux and Android standard keycodes via `AndroidKeyCodes`.
- **System Navigation Shortcuts:**
  - <kbd>Cmd</kbd> + <kbd>H</kbd>: Return to Home Screen.
  - <kbd>Cmd</kbd> + <kbd>Backspace</kbd>: Back button.
  - <kbd>Cmd</kbd> + <kbd>Tab</kbd>: App Switcher / Recent Apps (`KEYCODE_APP_SWITCH`).
  - <kbd>Cmd</kbd> + <kbd>R</kbd>: Rotate display orientation 90 degrees.
  - <kbd>Cmd</kbd> + <kbd>O</kbd>: Power phone screen off/on.

### 4. International Unicode & IME Text Injection (<kbd>Cmd</kbd> + <kbd>K</kbd>)
- **Direct Character Stream:** While standard hardware keyboard forwarding can encounter difficulties with complex multi-byte input, the **Quick Text Injector** modal (<kbd>Cmd</kbd> + <kbd>K</kbd>) directly injects UTF-8 text strings into the focused Android text field.
- **Accented & Asian Language Support:** Flawlessly supports Vietnamese (Telex, VNI), Japanese, Chinese, Korean, and emoji glyphs without dropping characters.

---

## 🔒 OEM Security Notice
- **Xiaomi (MIUI / HyperOS):** Requires **"USB debugging (Security settings)"** to be enabled in Developer Options to allow mouse click and keystroke injection.
- **Oppo / Realme / OnePlus:** If input is blocked, toggle ON **"Disable permission monitoring"** in Developer Options.
