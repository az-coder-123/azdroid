# `adb logcat` Quotes Its Arguments Itself

## 1. Context & Symptoms

On 2026-10-22, `android_get_logcat(package: "com.android.systemui", sinceSeconds: 600)` returned "(no lines)" on a Redmi 9 (Android 10), while the same filter typed by hand gave 546 lines.

## 2. Diagnostic Traces & Evidence

```bash
adb -s 192.168.1.3:5555 logcat -d --pid=2405 -t "'1792668394.000'" '*:V'
#   -t "'1792668394.000'" not in time format          (0 lines)
adb -s 192.168.1.3:5555 shell logcat -d --pid=2405 -t "'1792668394.000'" '*:V'
#   498 lines
adb -s 192.168.1.3:5555 logcat -d --pid=2405 -t 1792668394.000 '*:V'
#   506 lines
```

## 3. Root Cause Analysis

The code added single quotes around the time, following [adb-shell-argument-quoting.md](adb-shell-argument-quoting.md): `adb shell` joins its arguments into one command line for the device shell. But the tool calls `adb logcat`, a host command that builds `exec logcat …` and quotes **each** argument itself. The added quotes reached logcat as characters, and logcat rejected the time. The error went to stderr, the tool read stdout, and an empty result looked like "no logs".

## 4. Architectural Solution

`McpAdbCmdOps.getLogcat` passes `-t <seconds>.000` unquoted, with a comment on why. A unit test pins the argument form (`--pid=2405`, `-t`, `1792668394.000`). Verified on the Redmi: the last two systemui lines of the past 600 s.

## 5. Prevention & Reusability Checklist

- [ ] Quote for the device shell only with `adb shell <one string>`; `adb logcat`, `adb install`, `adb push` pass arguments as they are.
- [ ] When a filtered read is empty, check stderr before concluding "nothing matched".
- [ ] Compare a tool's output with the same query typed by hand on a real device.
