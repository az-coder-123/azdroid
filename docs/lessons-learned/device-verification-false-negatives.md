# False Failures While Verifying scrcpy on Real Devices

## 1. Context & Symptoms

Upgrading scrcpy-server from v2.1 to v3.3.4 was verified on a real Redmi 9 (Android 10) and an Android 16 emulator. Three times, the **verification itself** produced a failure that had nothing to do with the server:

| Run | Observed | Real cause |
|:---|:---|:---|
| v3.3.4 on Android 16 emulator | `EOFError: socket closed after 0/77 bytes` | The script connected **once**, 0.3 s after the server's `Device:` line; on the slow emulator the device socket was not listening yet. |
| v2.1 and the Dart tool on Redmi 9 | Header received, then no packets until timeout | The phone **screen was off**, so the display produced no frames. |
| Dart tool, first attempt | `exit=0` printed | That was the exit code of `head` in the pipe, not of the tool, which had crashed (`dart:ui` not available). |
| Control check, `power_on` (Redmi 9) | Screen reported off after the run | Checked ~20 s after control connected; the PIN lock screen had already turned the display off again. |
| Control check, HOME/BACK (Redmi 9) | Keys had no effect | The phone was PIN-locked. Keys reach the lock screen, not the launcher. |
| Control check, HOME (Redmi 9) | Resumed activity "unknown" | Android 10 prints `ResumedActivity:`, not `mResumedActivity`. |
| Control check, size check | 2 ignored events, 1 expected | A wrong-size tap is a DOWN and an UP: two positional events. |
| Control check, emulator | BACK did not close Settings | Fixed sleeps were too short for the emulator, and the tool had stopped reading video (see [adb-forward-shared-transport-stall.md](adb-forward-shared-transport-stall.md)). |

## 2. Diagnostic Traces & Evidence

- Emulator logcat at the moment of the single connection:
  ```text
  E adbd: failed to connect to socket 'localabstract:scrcpy_7a5e0001': could not connect to localabstract address
  ```
  With the native plugins' retry policy (30 × 300 ms), it connected on attempt 2 and streamed normally.
- `dumpsys power` on the Redmi: `mWakefulness=Asleep`, `Display Power: state=OFF`. After `input keyevent KEYCODE_WAKEUP`, both v2.1 and v3.3.4 streamed.
- `set -o pipefail` exposed the real exit code; the tool imported `ScrcpyServerManager`, which pulls in Flutter.

## 3. Root Cause Analysis

The harness did not reproduce the conditions under which the product runs. The app retries connections, and users have the screen on. The harness connected once and ignored device state, so it tested its own assumptions instead of the server. The pipe hid a crash, the same pattern as [smoke-test-false-pass.md](smoke-test-false-pass.md). The control checks repeated the pattern: each assumed a device state (unlocked, display awake for long, fast emulator, one log line per tap, one `dumpsys` format) that the test never checked.

## 4. Architectural Solution

- `tool/verify_scrcpy_server.dart` uses the app's own `ScrcpyServerCommand`, retries like the native plugins, wakes the screen first, and reports `no video data in time: is the screen on and unlocked?` on a timeout.
- The scrcpy facts it needs moved to the pure-Dart `ScrcpyServerConstants`, so the tool runs on the plain Dart VM.
- Each conclusion was cross-checked with a **control**: v2.1 vs v3.3.4 on the same device and conditions.
- Control checks: `power_on` is checked 1.5 s after control connects; HOME/BACK are skipped with a clear message while the keyguard shows (the tool never unlocks a user's phone); waits poll a condition with a bound instead of sleeping; the resumed-activity matcher accepts every Android format; the size check expects two ignored events.

## 5. Prevention & Reusability Checklist

- [ ] A verification harness uses the product's own retry, timing, and arguments, ideally by importing the same code.
- [ ] Record device state (screen, lock, battery saver) before trusting a "no data" result.
- [ ] Always run a control (old vs new version) under identical conditions before drawing a conclusion.
- [ ] Use `set -o pipefail` (or check `PIPESTATUS`) when piping a command whose exit code matters.
- [ ] Read the device log (`logcat`) when a socket closes early; it usually names the reason.
- [ ] Poll for the expected condition with a time limit; never rely on a fixed sleep tuned on one device.
- [ ] Check lock state before testing keys or touches, and report "skipped" rather than "failed".
- [ ] Derive the expected count of events from the protocol (DOWN + UP), not from intuition.
