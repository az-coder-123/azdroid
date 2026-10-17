# `Directory.systemTemp` on macOS Is Not `/tmp`

## 1. Context & Symptoms

While moving the diagnostic log path into `HostPaths`, the first draft used `Directory.systemTemp` for every OS. This would have **silently moved** the macOS log from `/tmp/deskdroid_dart.log` to a folder like `/var/folders/8_/7881x22x.../T/`.

## 2. Diagnostic Traces & Evidence

- On macOS, `Directory.systemTemp` reads `$TMPDIR`, a per-user folder under `/var/folders/...`.
- The native Swift plugin still writes `/tmp/scrcpy_stream.log`.
- The two logs that are always read together during debugging would have ended up in different places.

## 3. Root Cause Analysis

"Temp directory" sounds portable, but each OS defines it differently:

| OS | `Directory.systemTemp` |
|:---|:---|
| macOS | `$TMPDIR` → `/var/folders/<id>/T` |
| Linux | `/tmp` (usually) |
| Windows | `%TEMP%` → `C:\Users\<u>\AppData\Local\Temp` |

## 4. Architectural Solution

`SystemHostPaths.diagnosticLogFile` keeps `/tmp` on POSIX hosts and uses the system temp folder only on Windows. Unit tests pin the expected path for each OS.

## 5. Prevention & Reusability Checklist

- [ ] When centralizing a path, compare the new value with the old one on every OS before switching.
- [ ] Keep log files that are read together in the same folder.
- [ ] Pin user-visible paths in tests, so a change shows up in review.
