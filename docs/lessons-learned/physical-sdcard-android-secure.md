# Lesson Learned: Physical MicroSD Mounts & Android Secure Permission Handling

> **Category:** Android Storage Architecture / Linux Filesystem Permissions / Error Handling  
> **Impact:** Remote file manager displaying empty folder state instead of real SD card files.

---

## 1. Context & Symptoms

When browsing Android storage via the remote file explorer:
1. Navigating to `/sdcard/` only displays shared internal storage (`/storage/emulated/0`), not the physical MicroSD card.
2. Clicking or listing the actual physical MicroSD card path (e.g., `/storage/3662-FF26/`) or subdirectories caused the UI to display:
   ```text
   No files in this folder.
   ```
   even though dozens of files and directories existed on the physical card.

---

## 2. Diagnostic Traces & Evidence

1. **Running raw ADB `ls -lp` on the physical SD card:**
   ```bash
   adb shell ls -lp /storage/3662-FF26/
   ```
2. **Command Exit Code and Output:**
   - **Exit Code:** `1` (Non-zero failure).
   - **Stderr:**
     ```text
     ls: /storage/3662-FF26//.android_secure: Permission denied
     ```
   - **Stdout:**
     ```text
     total 7424
     -rwxrwx--x  1 root sdcard_rw   68483 2016-03-25 19:39 8 câu nói truyền cảm hứng.pdf
     drwxrwx--x  2 root sdcard_rw   32768 2026-03-28 10:47 Alarms/
     drwxrwx--x  5 root sdcard_rw   32768 2021-08-03 08:34 Android/
     -rwxrwx--x  1 root sdcard_rw  532713 2016-03-25 19:39 nha-gia-kim.pdf
     ... (23 valid files and directories)
     ```
3. **Previous Naive Datasource Logic:**
   ```dart
   if (result.exitCode != 0) return [];
   ```
   Because `exitCode == 1`, the datasource returned `[]`, discarding all 23 valid files in `stdout`!

---

## 3. Root Cause Analysis

### A. Android Internal vs External Storage Layout
- `/sdcard` is a legacy symlink pointing to `/storage/emulated/0` (the virtualized shared internal flash storage), **not** the physical MicroSD expansion card.
- Physical MicroSD cards and USB OTG volumes are mounted by the Android Volume Daemon (`vold`) under `/storage/<UUID>/` (e.g., `/storage/3662-FF26/`).

### B. System-Protected Folder `.android_secure`
FAT32/exFAT formatted MicroSD cards used on Android contain an encrypted system directory named `.android_secure` (used historically to store apps moved to SD card). The shell user does not have permission to list this directory. Consequently, `ls -lp /storage/<UUID>/` writes a `Permission denied` warning to `stderr` and returns `exitCode = 1`, despite successfully listing every other file to `stdout`.

### C. Error Swallowing Antipattern
Returning an empty list `[]` when `exitCode != 0` conceals the real error from the presentation layer (BLoC/Cubit). The UI assumes the directory is legitimately empty (`DeviceFileManagerLoaded(files: [])`), preventing users and developers from discovering permission or connectivity problems.

---

## 4. Architectural Solution

### A. Non-Destructive Stdout Parsing
Updated `FileTransferDatasourceImpl.listRemoteFiles` to parse stdout whenever content is present, only failing if stdout is genuinely empty:

```dart
final stdoutStr = result.stdout.toString();
// Only treat as fatal if exitCode is non-zero AND no files were output
if (result.exitCode != 0 && stdoutStr.trim().isEmpty) {
  final err = result.stderr.toString().trim();
  throw Exception(err.isNotEmpty ? err : 'Error reading $remoteDirectory');
}
```

### B. Bubble Errors to UI via Exceptions
When an ADB call truly fails (e.g., `device offline`), rethrow the exception so `DeviceFileManagerCubit` emits `DeviceFileManagerError`. The UI then displays a clear error badge and a "Retry" button.

### C. Automatic MicroSD Detection & Dedicated Navigation
Implemented `getExternalStorageDirectory` to query `/storage/*` for non-emulated UUID mounts, adding a dedicated `💳 SD Card` shortcut chip to the file explorer toolbar.

---

## 5. Prevention & Reusability Checklist

- [ ] **Do Not Discard Partial Success:** When executing Unix tools (`ls`, `find`, `tar`) on heterogeneous Android environments, a non-zero exit code often accompanies partial success (e.g., one inaccessible system entry). If stdout has valid lines, parse them.
- [ ] **Never Return Empty Collections on Failure:** Distinguish "0 items found" from "failed to read items". Throw exceptions or use `Result`/`Either` monads so the presentation layer knows to show an error state.
- [ ] **Respect Platform Storage Semantics:** Never hardcode `/sdcard` as the sole external storage; always query `/storage/` mounts dynamically for external media.
