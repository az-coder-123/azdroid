# Faster Input Exposed a Race: A Key Can Overtake the Tap Before It

## 1. Context & Symptoms

On 2026-10-22, `android_press_key` moved from `adb shell input keyevent` to the scrcpy control session (about 5 ms instead of 100 ms or more). On a Moto g play (Android 13), BACK, BACK, HOME sent right after `android_click_element` opened a Settings page left the device on that page, and a batch `tap → key HOME` ended in Settings. The same keys sent when the screen was idle always worked.

## 2. Diagnostic Traces & Evidence

A Python client on the raw scrcpy protocol, Settings home, tapping "Hiển thị" (which opens a page), then BACK after a gap, final activity read 2 s later:

| BACK after the tap | scrcpy | `adb shell input keyevent` |
| :--- | :--- | :--- |
| 0 ms | lost (page stays open) | works |
| 100, 250, 500, 800 ms | works | works |

BACK 0 ms after a tap on a spot that opens nothing always worked, and HOME on a settled screen always worked. Two of the apparent failures were misreadings: a back stack left by earlier test runs (`am start` on top of an old page), and reading the foreground app 100 ms after HOME, mid-animation.

## 3. Root Cause Analysis

A tap's click runs after its UP event, posted to the app's main thread. A key injected in the same instant reaches the window first, so it acts on the old screen (or is lost in the switch), and the new screen opens afterwards. `adb shell input` hid this because each command needs about 100 ms to start a JVM, which spaced events like a person would.

## 4. Architectural Solution

`McpFastInput` keeps at least `minGap` (120 ms) between the end of one input and the start of the next on a device (`beforeInput`/`afterInput`, also used by the gesture executor). Events inside one gesture (a stroke, a double tap) are not spaced. After the change, the failing MCP sequence and batch ended on the expected screens, and agents rarely notice the gap: their calls are usually further apart.

## 5. Prevention & Reusability Checklist

- [ ] When replacing a slow path with a fast one, list the timing the slow path provided for free and keep what behavior depended on it.
- [ ] Measure the race directly (vary the gap) before choosing a delay.
- [ ] Start device tests from a clean state (`am force-stop`) and read state only after transitions end.
