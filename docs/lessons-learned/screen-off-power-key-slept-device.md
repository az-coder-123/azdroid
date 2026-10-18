# Screen Off Pressed POWER: The Phone Slept Instead of Mirroring Dark

## 1. Context & Symptoms

DeskDroid's **Screen Off** button (documented as "turn the phone screen off, keep mirroring, like `--turn-screen-off`") actually sent `adb shell input keyevent 26` (POWER). The phone went to sleep: the mirror froze on the last frame, the lock screen engaged, and turning it "on" again pressed POWER a second time.

## 2. Diagnostic Traces & Evidence

- `ScrcpyServerManager.setScreenPower({powerOff})` ignored `powerOff` and always sent `KEYCODE_POWER`.
- scrcpy v3.3.4 implements screen-off mirroring with the control message `SET_DISPLAY_POWER` (type 10, one boolean byte). The server sets the **panel power mode** and leaves the device awake (`Controller.setDisplayPower`, `Device.setDisplayPower`).
- Android 16 emulator, after sending `[10, 0]` on the control socket:
  ```text
  off:   mWakefulness=Awake  powerMode=Off
  video bytes while off (3 s, screen changing): 37207
  after POWER key:     mWakefulness=Dozing powerMode=Off
  after 2nd POWER key: mWakefulness=Awake  powerMode=On
  after server exit (cleanup restore): powerMode=On
  ```
- Redmi 9 (Android 10): `powerMode=2` → `0` after the message, and video kept arriving (1.4 MB in 3 s).

## 3. Root Cause Analysis

The feature was named after the scrcpy option, but implemented with the only tool at hand before the control socket existed: a key event. POWER toggles **wakefulness**, not the panel. The docs described the intended behavior, nobody checked the device state, and the toggle "worked" in the sense that the phone screen went dark.

## 4. Architectural Solution

- `ScrcpyControlMessage.setDisplayPower` (golden-tested against scrcpy's `test_serialize_set_display_power`), sent by `ScrcpyControlConnector.setDisplayPower`.
- `StreamingRepositoryImpl.toggleScreenOff` returns whether it was sent; the cubit changes state only then. The POWER-key path was removed.
- A pipeline restart re-sends "off" (the old server's restore turns the panel on when it exits). Stopping sends "on"; `cleanup=true` covers crashes and disconnects.
- `tool/verify_scrcpy_server.dart` checks panel off while awake, video flowing, and panel on after exit.

## 5. Prevention & Reusability Checklist

- [ ] When a feature is named after an upstream option, implement it with that option's mechanism, or rename it.
- [ ] Verify a power feature with device state (`dumpsys power` wakefulness, `dumpsys SurfaceFlinger` power mode), not by looking at the phone.
- [ ] A parameter that the body ignores (`powerOff`) is a red flag in review.
- [ ] Record which Android versions a device-state check was run on; dumpsys formats differ (`0` vs `Off`).
