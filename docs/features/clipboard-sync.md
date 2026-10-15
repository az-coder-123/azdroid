# Feature: Bidirectional Clipboard Synchronization

> **Subsystem:** `lib/features/productivity/`  
> **Key Interfaces:** `ClipboardRepository`, `ClipboardDatasource`, `ClipboardSyncDaemon`  
> **Presentation:** `ClipboardCubit`, `ClipboardSyncMenuButton`, `ClipboardFeedbackBanner`  
> **Shortcuts:** <kbd>Cmd</kbd> + <kbd>Shift</kbd> + <kbd>C</kbd> (Push to Android) / <kbd>Cmd</kbd> + <kbd>Shift</kbd> + <kbd>V</kbd> (Pull to Mac)

---

## 📌 Overview

DeskDroid provides seamless bidirectional clipboard synchronization between macOS and Android. Any text copied on your Mac is instantly pasteable on Android, and text selected and copied on Android is immediately available in the macOS pasteboard.

```mermaid
flowchart LR
    MacPasteboard["macOS Pasteboard\n(Cmd + C)"] -->|Clipboard Watcher| SyncDaemon["ClipboardSyncDaemon\n(Bidirectional Echo Suppression)"]
    SyncDaemon -->|ADB cmd clipboard / clipper.set| AndroidClipboard["Android System Clipboard\n(Long Press Paste)"]
    
    AndroidCopy["Android Text Selection\n(Copy Action)"] -->|Background Daemon Tick| SyncDaemon
    SyncDaemon -->|macOS Platform Channel| MacPasteboard
```

---

## ⚡️ Key Capabilities

### 1. Real-Time Two-Way Background Daemon
- **Background Daemon:** `ClipboardSyncDaemon` runs a non-intrusive 2-second background loop monitoring both macOS pasteboard and Android clipboard without user interaction.
- **Mac to Android:** When you copy text, URLs, API keys, or verification codes on macOS, DeskDroid immediately forwards the string to Android clipboard.
- **Android to Mac:** When you select and copy text on the phone, the daemon detects the clipboard change and pushes the text to the macOS clipboard, ready for <kbd>Cmd</kbd> + <kbd>V</kbd>.

### 2. Dual Strategy & Broad Android Compatibility
- **Primary Method:** Native Android `cmd clipboard set / get` for modern AOSP devices.
- **Broadcast Fallback:** Automatic fallback to `am broadcast -a clipper.set / clipper.get` when `cmd clipboard` is unavailable on custom ROMs.

### 3. Bidirectional Echo Loop Suppression
- **Dual Content Caching:** Maintains independent string hashes for host and device clipboards.
- **Loop Prevention:** Text received from Mac is marked before pushing to Android, ensuring subsequent Android polling does not reflect it back to Mac, completely preventing infinite ping-pong loops.

### 4. Desktop Shortcuts & HUD Feedback
- **Fast Shortcuts:** <kbd>Cmd</kbd> + <kbd>Shift</kbd> + <kbd>C</kbd> to manually force push to Android; <kbd>Cmd</kbd> + <kbd>Shift</kbd> + <kbd>V</kbd> to manually force pull to Mac.
- **HUD Feedback Toast:** `ClipboardFeedbackBanner` pops up a subtle toast badge with direction and text snippet, automatically dismissing after 4 seconds.
- **Dock Menu Button:** `ClipboardSyncMenuButton` provides one-click manual sync triggers and auto-sync toggle.
