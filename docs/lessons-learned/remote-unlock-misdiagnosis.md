# Remote Unlock Over adb: A Wrong Diagnosis From One Exception

## 1. Context & Symptoms

To test on a PIN-locked Redmi 9 (MIUI, Android 10), the user shared the PIN so the phone could be unlocked over adb. The first attempts failed, and the lock screen stayed. Based on one exception, the conclusion was "MIUI blocks injected input on the lock screen", and that conclusion went into the docs. It was wrong: the first PIN given was wrong. With the correct PIN, the same taps unlocked the phone at once.

## 2. Diagnostic Traces & Evidence

- One command ran a swipe (to open the PIN pad), taps, and `uiautomator dump`. Its output contained:
  ```text
  java.lang.SecurityException: Injecting to another application requires INJECT_EVENTS permission
      at com.android.commands.input.Input$InputSwipe.sendSwipe(Input.java:273)
  ```
  The trace names `InputSwipe`. The **swipe** failed part way (the PIN pad still opened); the taps raised nothing.
- With the correct PIN, the same sequence (wake, swipe, then taps on the key centers from `uiautomator dump`) gave `isStatusBarKeyguard=false` and the launcher in focus.
- `screencap` of the secure lock screen returned a blank image (or 0 bytes while asleep); `uiautomator dump` still listed the keys and their bounds.

## 3. Root Cause Analysis

Two signals were merged into one story. A real exception from one step (the swipe) was blamed for the failure of another step (the taps), whose real cause was a wrong PIN. The conclusion was not re-checked against the stack trace, and it was written into user documentation as a fact.

## 4. Architectural Solution

- The wrong statement was removed from [screen-off-streaming.md](../features/screen-off-streaming.md), and this case study replaces the earlier one.
- Unlock procedure that worked: `input keyevent KEYCODE_WAKEUP`, `input swipe 540 2250 540 700 400`, read the key bounds with `uiautomator dump`, then `input tap` each digit at its key center, all in one `adb shell` call so the PIN pad does not time out.
- After unlocking, `tool/verify_scrcpy_server.dart --keep-screen` ran every check on the real phone, including HOME and BACK through the control socket. A full run without `--keep-screen` turns the screen off first, which locks the phone again.
- Credentials given for a test are never written to code, docs, commit messages, logs, or memory. Only a few attempts were made, to stay far from the lockout limit.

## 5. Prevention & Reusability Checklist

- [ ] Attribute an exception to the step its stack trace names, not to the step that "looks" related.
- [ ] Before documenting a platform limitation, reproduce it once more with the other causes ruled out (here: a known-good PIN).
- [ ] Run one action per command when diagnosing, so each result is clear.
- [ ] Use `uiautomator dump` to read a secure screen's layout; `screencap` is blanked.
- [ ] Treat a PIN as single-use test input: never store it, and keep attempts few.
