# logcat Buffer Header Lines Are Not Log Entries

## 1. Context & Symptoms

On 2026-10-22, `android_get_logcat` with `crashesOnly: true` (formerly `android_check_crash`) answered on a Redmi 9 (Android 10) that had no crash:

```
Fatal exception detected in AndroidRuntime:
--------- beginning of main
```

The same code also could never report a real entry from the dedicated crash buffer.

## 2. Diagnostic Traces & Evidence

```bash
adb -s 192.168.1.3:5555 logcat -d -s AndroidRuntime:E
# --------- beginning of system
# --------- beginning of main
adb -s 192.168.1.3:5555 logcat -b crash -d     # nothing on this device
```

logcat prints one `--------- beginning of <buffer>` line per buffer it reads, even when no entry matches the filter. The Motorola (Android 13) printed none, so the fault showed up only on the Redmi.

## 3. Root Cause Analysis

`McpAdbCmdOps.checkCrash` used two opposite rules for the same header:

| Buffer | Rule | Effect |
| :--- | :--- | :--- |
| `-b crash` | Ignore output that **contains** a header | Every non-empty dump contains one, so crashes were never reported |
| main, `AndroidRuntime:E` | Any non-empty output is a crash | The header alone was reported as a fatal exception |

The main query also used `-t 100`, which counts lines **before** the tag filter applies: the same mistake fixed earlier for `android_get_logcat`.

## 4. Architectural Solution

`McpAdbCmdOps._logEntries` drops header and blank lines and keeps the last `limit` entries, so both buffers are read the same way. The main buffer is filtered first (no `-t`), and the tail is taken in Dart. Tests in `test/unit/mcp_device_capability_test.dart` feed the real header-only output and a crash after a header.

## 5. Prevention & Reusability Checklist

- [ ] Treat logcat's `--------- beginning of` lines as framing, never as entries.
- [ ] Decide "is there a result" after removing framing, not from raw output length.
- [ ] Filter before `-t`; take the tail in code.
- [ ] Run "nothing to report" cases on several Android versions: framing differs by device.
