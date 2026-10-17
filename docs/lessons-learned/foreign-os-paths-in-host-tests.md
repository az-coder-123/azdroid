# Testing Windows Paths on a macOS File System

## 1. Context & Symptoms

A test built a Windows `HostToolchain` (`ANDROID_HOME` pointing at a macOS temp folder) and expected `AaptPathResolver` to find `aapt2.exe` on disk. It returned `null`.

## 2. Diagnostic Traces & Evidence

The Windows toolchain joins paths with `\`:

```text
/var/folders/.../aapt_sdk_9b5TR1\build-tools
```

That string is not a real directory on macOS, so `Directory.existsSync()` returned `false`.

## 3. Root Cause Analysis

The test mixed two concerns: **which names and paths** a toolchain produces (pure data) and **whether the file system contains them** (host I/O). A foreign-OS path context can never touch the host file system correctly.

## 4. Architectural Solution

- Data tests: `host_toolchain_test.dart` checks Windows names and paths as strings (`aapt2.exe`, `...\Android\Sdk\build-tools`).
- Behavior tests that use another OS's toolchain stub the process executor (for example `where aapt2.exe` returning CRLF output) and never touch disk.
- Real disk scans are tested only with the **host's own** path style.

## 5. Prevention & Reusability Checklist

- [ ] Test foreign-OS path *construction* as strings, never through `File` or `Directory`.
- [ ] Mock `ProcessExecutor` and inject `fileExists` callbacks for cross-OS behavior.
- [ ] Keep disk-touching tests on the host path style, so they pass on every CI runner.
