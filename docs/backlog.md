# DeskDroid Product Backlog & Deferred Feature Proposals

> Curated record of prioritized feature proposals and architectural enhancements identified during development and code audits, cataloged for future sprint planning.

---

## 📋 Backlog Overview

| ID | Module / Subsystem | Feature Proposal | Priority | Target Milestone | Status |
|:---|:---|:---|:---:|:---:|:---:|
| **BL-01** | `logging` (Logcat) | macOS Native Keyboard Shortcuts (`Cmd+F`, `Cmd+K`, `Space`, `Cmd+Down`, `Esc`) | High | v1.1 | ✅ Completed |
| **BL-02** | `logging` (Logcat) | Search Term Visual Highlighting in Log Messages | Medium | v1.1 | ✅ Completed |
| **BL-03** | `streaming` / `productivity` | Direct Drag & Drop into Mirroring Viewport (APK install & media transfer) | High | v1.2 | ✅ Completed |
| **BL-04** | `productivity` (Clipboard) | Background Real-time Two-Way Clipboard Synchronization Daemon | High | v1.2 | ✅ Completed |
| **BL-05** | `streaming` (Audio) | Scrcpy v2.0+ Audio Forwarding Socket Pipeline (Android 10+) | Medium | v1.3 | ⏳ Backlog |
| **BL-06** | `architecture` (Clean Code) | Modularize Large Widget & Cubit Files (`device_log_cubit`, `apk_installer_dialog`, `log_filter_bar`) | Medium | Technical Debt | ⏳ In Progress |
| **BL-07** | `distribution` (DevOps) | macOS DMG Bundler, Apple Code-Signing & Sparkle Auto-Update Pipeline | High | Release Ready | ⏳ Backlog |

---

## 🔍 Detailed Feature Specifications

### BL-01: Logcat Console Keyboard Ergonomics
- **Problem Statement:** Power users inspecting real-time logcat logs currently rely on mouse clicks to clear logs, pause streams, or search.
- **Proposed Solution:** Implement macOS standard shortcut bindings inside `DeviceLogDialog`:
  - `Cmd + F`: Focus search filter input.
  - `Cmd + K`: Clear in-memory log entries.
  - `Space`: Pause or resume real-time stream.
  - `Cmd + Down`: Instantly scroll to latest entries (anchor bottom).
  - `Esc`: Close Detail Drawer if open; dismiss dialog if drawer is closed.

### BL-02: Search Query In-Message Highlighting
- **Problem Statement:** Finding specific tokens within lengthy logcat messages requires manual scanning.
- **Proposed Solution:** When `searchQuery` is active in `LogConsoleRow`, render `TextSpan` elements with background highlight (`AppColors.statusWarning.withValues(alpha: 0.3)`) around matching substrings.

### BL-03: Viewport Drag & Drop Ingestion
- **Problem Statement:** Installing APKs or transferring pictures requires opening separate dialogs.
- **Proposed Solution:** Wrap `MirroringActiveView` with Flutter's `DropTarget`. Dropping `.apk` triggers automatic background sideloading with a HUD progress badge; dropping media files transfers them to `/sdcard/Download/`.

### BL-04: Real-Time Two-Way Clipboard Synchronization
- **Problem Statement:** Clipboard syncing currently requires clicking the copy action button or key triggers.
- **Proposed Solution:** Run a lightweight background service monitoring macOS `NSPasteboard` changes and pushing text updates via `adb shell am broadcast -a clipper.set` or scrcpy input control socket, while capturing Android clipboard broadcasts.

### BL-05: Android Audio Forwarding (Scrcpy v2.0+)
- **Problem Statement:** Video is mirrored smoothly, but audio plays from the mobile device speakers.
- **Proposed Solution:** Connect to the scrcpy audio socket (OPUS or raw PCM streaming) and feed the audio stream into macOS CoreAudio / `audioplayers` output buffer with synchronized clock PTS.

### BL-06: Codebase Compactness & SRP Refactoring
- **Problem Statement:** Several presentation files hover between 260 and 340 lines.
- **Proposed Refactorings:**
  - `device_log_cubit.dart` (343 lines): Extract recording file stream management to a dedicated `LogRecordingDelegate`.
  - `apk_installer_dialog.dart` (288 lines): Extract permissions & package preview to `ApkMetadataCard`.
  - `log_filter_bar.dart` (280 lines): Extract filter popover sheets to `LogFilterPresetsMenu` and `LogExcludeTagsSheet`.
  - `side_controls_toolbar.dart` (261 lines): Extract quick capture buttons into `ToolbarCaptureGroup`.

### BL-07: macOS Distribution & Release Pipeline
- **Problem Statement:** The project is run via `flutter run`, lacking an automated release bundle.
- **Proposed Solution:** Create `scripts/build_dmg.sh` using `create-dmg` to produce styled DMG packages with background art, integrate Apple Developer ID signing, and configure `Sparkle.framework` for auto-updates.
