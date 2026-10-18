# Unlocking a MIUI Phone Remotely Fails: Input Injection Is Blocked

## 1. Context & Symptoms

To test Screen Off on a PIN-locked Redmi 9 (MIUI, Android 10), the user provided the PIN so the phone could be unlocked over adb. Taps on the PIN pad did nothing, the lock screen stayed, and screenshots of the lock screen were blank or empty.

## 2. Diagnostic Traces & Evidence

- `input swipe` showed the PIN pad, but taps on it failed:
  ```text
  java.lang.SecurityException: Injecting to another application requires INJECT_EVENTS permission
  ```
- `dumpsys window` kept `isStatusBarKeyguard=true`, `mCurrentFocus=Window{… StatusBar}`.
- `screencap` of the secure lock screen returned a blank image, or 0 bytes while the device was asleep. `uiautomator dump` still listed the PIN keys and their bounds.

## 3. Root Cause Analysis

MIUI checks injected input against the focused window. The lock screen belongs to System UI, and the `shell` user may inject into it only when **USB debugging (Security settings)** is on. scrcpy injects through the same `InputManager` path as the `shell` user, so DeskDroid cannot unlock such a phone either. The lock screen is also a secure window, so captures are blanked.

## 4. Architectural Solution

- Process rule: stop after the first `SecurityException` instead of retrying. Repeated attempts risk a PIN lockout and gain nothing. Ask the user to unlock the phone by hand.
- The verification tool already skips key checks while the keyguard shows, and reports it as "skipped", not "failed".
- [screen-off-streaming.md](../features/screen-off-streaming.md) tells users to unlock MIUI phones on the device itself.
- Credentials given for a test are never written to code, docs, logs, or memory.

## 5. Prevention & Reusability Checklist

- [ ] Before automating an unlock, check one injected tap for `SecurityException`.
- [ ] Use `uiautomator dump` to read a secure screen's layout; `screencap` is blanked.
- [ ] Treat a PIN as single-use test input: never store it, and never brute-force retries.
- [ ] Prefer test devices without a secure lock, or an emulator, for automated checks.
