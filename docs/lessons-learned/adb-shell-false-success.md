# adb Shell Commands Report Success They Did Not Have

## 1. Context & Symptoms

A review of the MCP tool catalog (2026-10-22) checked each description against a real device. Several tools returned success without doing anything:

- `android_set_clipboard`, `android_simulate_biometric`, `android_set_location`: "success" on Android 10, nothing changed. `android_set_location` also wrote `location_mode` first.
- `android_get_clipboard` returned the text `No shell command implementation.` as the clipboard content.
- `android_set_text` "set" the clipboard, then pasted the **old** clipboard and reported success.
- `android_dismiss_notification` with `clearAll` reported "Cleared all notifications" but only opened the shade.
- `android_get_logcat` with a filter returned nothing.

Unit tests passed throughout: they mocked the command and asserted the success message.

## 2. Diagnostic Traces & Evidence

```text
$ adb shell "cmd clipboard set probe"; echo exit=$?      # Android 10 and 13
No shell command implementation.
exit=0
$ adb shell "cmd location set-location 1 1"               # Android 13 has cmd location,
Location service commands: ...                            # but no such subcommand
$ adb logcat -d -t 3 '*:E' | wc -l
0                                                         # -t cuts before the filter
$ adb logcat -d '*:E' | tail -3                           # three error lines
```

- `cmd fingerprint`, `cmd biometric`: missing on Android 10 and 13 (biometrics are emulator-only: `adb emu finger touch`).
- `cmd notification` has no `cancel`; `snooze --for <ms> <key>` exists on Android 11+. `service call statusbar 1` is `expandNotificationsPanel`.
- The old test for `clearAll` expected "Cleared all notifications", so it locked the wrong behavior in.

## 3. Root Cause Analysis

The code treated `exitCode == 0` as success and was written from memory of command names, not from a device. Android's `cmd` dispatcher prints a message and exits 0 when a service has no shell handler, `logcat -t` applies before the filter spec, and a `service call` transaction number is not a stable API. Mock-based tests repeated the same assumption, so they could not catch it.

## 4. Architectural Solution

- `McpShellResult` (`mcp_shell_result.dart`): `succeeded` requires exit 0 **and** no "No shell command implementation" / "Can't find service" output.
- `McpUnsupportedOnDeviceException` carries the reason; `McpToolExecutor` returns it as the tool error, so agents read *why* instead of "Failed …".
- Clipboard, biometric, location, and notification tools rewritten against measured device behavior: test providers + `reset` for location, `snooze` for notifications, emulator-only biometrics, logcat filtering before taking the tail.
- `docs/mcp-tool-safety.md` §5 lists what works on Android 10 and 13. `test/unit/mcp_device_capability_test.dart` feeds the real outputs.

## 5. Prevention & Reusability Checklist

- [ ] Run every new `adb shell cmd …` on the oldest and newest supported Android before writing the tool; paste the output into a test fixture.
- [ ] Never treat `adb shell` exit code 0 as success for `cmd`; check the output.
- [ ] A mocked test that asserts a success message proves nothing about the device; feed it the device's real output.
- [ ] Do not change a device setting before the main command is known to work.
- [ ] Prefer an explicit "unsupported on this device" error over a fallback that silently does something else.
