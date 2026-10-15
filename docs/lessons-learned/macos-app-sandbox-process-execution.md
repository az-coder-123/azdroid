# Lesson Learned: macOS App Sandbox Restrictions on CLI Tool Execution

> **Category:** macOS Platform Integration / Entitlements / Security Sandbox  
> **Impact:** Silent failure or `Operation not permitted` when spawning `adb` or binding TCP sockets.

---

## 1. Context & Symptoms

When developing Flutter macOS desktop applications that invoke host CLI tools (such as `adb`, `which`, `open`) or listen on local TCP sockets:
- Attempts to spawn external binaries via `Process.run('adb', ...)` or `Process.start` fail with:
  ```text
  ProcessException: Operation not permitted (OS Error: Operation not permitted, errno = 1)
  ```
- Alternatively, the process fails silently, or dynamic PATH resolution via `/usr/bin/which adb` returns empty stdout.
- Raw TCP server sockets fail to bind or accept connections from local ports.

---

## 2. Diagnostic Traces & Evidence

1. **Terminal Inspection of Entitlements:**
   Checking `macos/Runner/DebugProfile.entitlements` and `Release.entitlements`:
   ```xml
   <key>com.apple.security.app-sandbox</key>
   <true/>
   ```
2. **System Log (`log stream` / Console.app):**
   ```text
   kernel: Sandbox: DeskDroid(pid) deny(1) process-fork
   kernel: Sandbox: DeskDroid(pid) deny(1) file-read-data /opt/homebrew/bin/adb
   ```
3. **Behavioral Divergence:**
   Running commands in standalone zsh succeeded without issue, whereas executing the exact same command inside the Flutter desktop Runner resulted in immediate permission denials.

---

## 3. Root Cause Analysis

### A. macOS App Sandbox Constraints
By default, newly generated Flutter macOS applications enable Apple's App Sandbox (`com.apple.security.app-sandbox`). 

The macOS App Sandbox strictly enforces:
1. **Child Process Execution Ban:** Sandboxed apps cannot fork arbitrary external binaries (like `/usr/local/bin/adb` or `/opt/homebrew/bin/adb`) outside of their tightly constrained container.
2. **Filesystem Isolation:** Sandboxed apps cannot read arbitrary system directories or search `/opt/homebrew/bin` unless explicitly user-granted via native file dialogs.
3. **Socket Binding Constraints:** Sandboxed apps require explicit network entitlements (`network.client`, `network.server`) to listen or connect over TCP/UDP.

### B. Developer Utility vs App Store Distribution
DeskDroid is designed as a power-user developer tool requiring direct integration with the host system's Android SDK, ADB daemon, Homebrew toolchain, and local networking. Because it is distributed as an open-source utility and standalone DMG (not distributed via the restricted Mac App Store), retaining App Sandbox imposes severe operational barriers with zero functional benefit.

---

## 4. Architectural Solution

### A. Disabling App Sandbox
Disabled App Sandbox in both `macos/Runner/DebugProfile.entitlements` and `macos/Runner/Release.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <false/>
    <key>com.apple.security.network.client</key>
    <true/>
    <key>com.apple.security.network.server</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
</dict>
</plist>
```

### B. Multi-Path ADB Discovery Fallback
To ensure resilience across diverse macOS installations, `AdbService.resolveAdbPath()` queries `/usr/bin/which adb` and falls back across standard user and Homebrew directories:
- `~/Library/Android/sdk/platform-tools/adb` (Android Studio default)
- `/opt/homebrew/bin/adb` (Apple Silicon Homebrew)
- `/usr/local/bin/adb` (Intel Homebrew)

---

## 5. Prevention & Reusability Checklist

- [ ] **Audit Entitlements First When `Operation Not Permitted` Occurs:** Always inspect `DebugProfile.entitlements` and `Release.entitlements` before assuming an OS permissions error is caused by user file rights.
- [ ] **Do Not Enable App Sandbox for Developer Bridge Tools:** If an application's primary function is coordinating local command-line tools (ADB, Git, Docker, FFmpeg), disable App Sandbox unless Mac App Store distribution is mandatory.
- [ ] **Support Multi-Architecture CLI Paths:** Always provide fallback discovery for Apple Silicon (`/opt/homebrew/bin`) and Intel (`/usr/local/bin`) Homebrew locations.
