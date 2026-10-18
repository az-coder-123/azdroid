# False Failures While Verifying scrcpy on Real Devices

## 1. Context & Symptoms

Upgrading scrcpy-server from v2.1 to v3.3.4 was verified on a real Redmi 9 (Android 10) and an Android 16 emulator. Three times, the **verification itself** produced a failure that had nothing to do with the server:

| Run | Observed | Real cause |
|:---|:---|:---|
| v3.3.4 on Android 16 emulator | `EOFError: socket closed after 0/77 bytes` | The script connected **once**, 0.3 s after the server's `Device:` line; on the slow emulator the device socket was not listening yet. |
| v2.1 and the Dart tool on Redmi 9 | Header received, then no packets until timeout | The phone **screen was off**, so the display produced no frames. |
| Dart tool, first attempt | `exit=0` printed | That was the exit code of `head` in the pipe, not of the tool, which had crashed (`dart:ui` not available). |

## 2. Diagnostic Traces & Evidence

- Emulator logcat at the moment of the single connection:
  ```text
  E adbd: failed to connect to socket 'localabstract:scrcpy_7a5e0001': could not connect to localabstract address
  ```
  With the native plugins' retry policy (30 × 300 ms), it connected on attempt 2 and streamed normally.
- `dumpsys power` on the Redmi: `mWakefulness=Asleep`, `Display Power: state=OFF`. After `input keyevent KEYCODE_WAKEUP`, both v2.1 and v3.3.4 streamed.
- `set -o pipefail` exposed the real exit code; the tool imported `ScrcpyServerManager`, which pulls in Flutter.

## 3. Root Cause Analysis

The harness did not reproduce the conditions under which the product runs. The app retries connections, and users have the screen on. The harness connected once and ignored device state, so it tested its own assumptions instead of the server. The pipe hid a crash, the same pattern as [smoke-test-false-pass.md](smoke-test-false-pass.md).

## 4. Architectural Solution

- `tool/verify_scrcpy_server.dart` uses the app's own `ScrcpyServerCommand`, retries like the native plugins, wakes the screen first, and reports `no video data in time: is the screen on and unlocked?` on a timeout.
- The scrcpy facts it needs moved to the pure-Dart `ScrcpyServerConstants`, so the tool runs on the plain Dart VM.
- Each conclusion was cross-checked with a **control**: v2.1 vs v3.3.4 on the same device and conditions.

## 5. Prevention & Reusability Checklist

- [ ] A verification harness uses the product's own retry, timing, and arguments, ideally by importing the same code.
- [ ] Record device state (screen, lock, battery saver) before trusting a "no data" result.
- [ ] Always run a control (old vs new version) under identical conditions before drawing a conclusion.
- [ ] Use `set -o pipefail` (or check `PIPESTATUS`) when piping a command whose exit code matters.
- [ ] Read the device log (`logcat`) when a socket closes early; it usually names the reason.
