# scrcpy Server Upgrade Assessment (2026-10-18)

> Decision record: whether and how to upgrade the bundled scrcpy-server from **v2.1** (June 2023). Status: **step 1 done (v3.3.4)**; **step 2 done (v5.0.1, 2026-10-18)**, assessed in [section 7](#7-step-2-assessment-v501), results in [section 8](#8-step-2-results-v501).

---

## 1. How DeskDroid Uses scrcpy

| Aspect | Current use |
|:---|:---|
| Server | `assets/scrcpy-server.jar` **v5.0.1** (was v2.1, then v3.3.4), started by `ScrcpyServerManager` |
| Arguments | `scid`, `tunnel_forward=true`, `video_bit_rate`, `max_fps`, `audio=true` + `audio_codec=raw` (when the platform has a player), `control=true`, `clipboard_autosync=false`, `cleanup=true`, and with Keep Phone Awake `keep_active=true` |
| Video | H.264 parsed by `macos/Runner/ScrcpyVideoSession.swift` and `native/scrcpy_core` (Windows) |
| Input | scrcpy control socket for touch and keys; text and the fallback path use `adb shell input` ([remote-input-control.md](features/remote-input-control.md)) |
| Audio | Raw PCM through the audio socket, played natively ([native-audio-contract.md](native-audio-contract.md)) |
| Readiness | Waits for the `[server] INFO: Device:` log line |

DeskDroid uses the video, audio and control sockets, so protocol changes to any of them matter.

---

## 2. Findings

### 2.1 v2.1 breaks basic mirroring on current Android

| Problem in v2.1 | Affected devices | Fixed in |
|:---|:---|:---|
| `SurfaceControl.createDisplay(String, boolean)` removed → `NoSuchMethodException`, no video ([#4656](https://github.com/Genymobile/scrcpy/issues/4656)) | Android 14 QPR3+, **Android 15, 16** | v2.4 |
| Crash right after start ([#6362](https://github.com/Genymobile/scrcpy/issues/6362)) | Android 16 QPR2 | v3.3.3 |
| Rotation stops updating ([#5908](https://github.com/Genymobile/scrcpy/issues/5908)) | Android 15 updates | v3.2 |
| Samsung-specific workarounds | Samsung | v2.3.1, v3.3.2 |

The only device tested so far (Xiaomi M2004J19C, Android 10/11) is not affected, which is why this went unnoticed.

### 2.2 Protocol compatibility by version

Verified in the server source (`Streamer.java`, `DesktopConnection.java`) and `doc/develop.md`:

| Version range | Video socket after dummy byte + 64-byte name | Packet header | Code changes needed |
|:---|:---|:---|:---|
| **2.1 → 3.3.4** | codec id + width + height (12 bytes) | bit 63 config, bit 62 key, PTS u62 | **None**: jar + version constant |
| **4.0 → 5.0.1** | codec id only (4 bytes); then **session packets** (MSB = 1: width, height, "client resized" flag) on every capture session (rotation) | MSB = 0 media; bit 62 config, bit 61 key, PTS u61 | Parser in `scrcpy_core` and in the Swift plugin |

Session metadata ([PR #6159](https://github.com/Genymobile/scrcpy/pull/6159)) was merged on 2026-01-10 and shipped in v4.0. All arguments DeskDroid passes still exist in v3.3.4 and v5.0.1, and both still log `Device: […]`.

### 2.3 What newer versions add for DeskDroid

| Version | Benefit for DeskDroid |
|:---|:---|
| 2.4 – 3.3.4 | Android 14 QPR3 / 15 / 16 mirroring fixes, Samsung fixes, generic fix for future added AIDL methods (3.3.3) |
| 4.0 | Encoder `KEY_PRIORITY` / `KEY_LATENCY` at minimum (lower latency), respects encoder capability constraints, optimal size alignment, explicit session packets on rotation |
| 5.0 | Mostly client-side (hardware decoding, which DeskDroid already has); server picks up 4.x fixes |

scrcpy does not backport fixes: future Android releases will only be supported on the newest line.

---

## 3. Options

| Option | Effort | Risk | Outcome |
|:---|:---|:---|:---|
| A. Stay on v2.1 | – | **High**: no video on Android 15/16 | Not acceptable |
| B. v3.3.4 (last protocol-compatible) | **Small**: jar, `serverVersion`, README badge; guard test enforces consistency | Low: wire format identical (verified in source) | Fixes Android 15/16 now |
| C. v5.0.1 (latest) | Medium: session packets and flag shift in `scrcpy_core` **and** Swift; contract update | Medium: Windows plugin is still unverified on hardware | Current, lower latency, future fixes |
| D. B now, then C | Small + medium | Low, then medium | Fast fix; protocol migration done once Windows is verified |

---

## 4. Recommendation

**Option D.**

1. **Now — v3.3.4.** Replace the jar (90,980 bytes, from the official v3.3.4 release), update `ScrcpyServerManager.serverVersion` and the README badge, and run the version guard test. Verify on the current device and, if possible, on an Android 15/16 emulator image.
2. **Next — v5.0.1**, after the first Windows hardware run. Teach `scrcpy_core` and the Swift plugin to read session packets and the shifted flags, update [native-video-contract.md](native-video-contract.md), and verify on both platforms.

Related work, independent of the version (all versions support it):
- **Control socket** (`control=true`) instead of `adb shell input`: much lower input latency; multi-touch becomes possible later. ✅ Done: see [remote-input-control.md](features/remote-input-control.md).
- **Audio**: either implement it (scrcpy audio, Android 11+, plus an Opus decoder and player on both platforms) or hide the toggle until it works. ✅ Done with raw PCM (no decoder): [audio-forwarding.md](features/audio-forwarding.md).

---

## 5. Upgrade Procedure

1. Download `scrcpy-server-vX` and `SHA256SUMS.txt` + `.asc` from the GitHub release. Check the SHA-256 against both the sums file and GitHub's asset digest, and verify the signature with Romain Vimont's key from `https://github.com/rom1v.gpg` (primary fingerprint `4569 58E8 5A18 5DD5 C2D1 E4E8 0C82 2B29 8461 FA03`) in a temporary `GNUPGHOME`.
2. Diff the wire format in the server **source** (`Streamer.java`, `DesktopConnection.java`), not only `doc/develop.md`.
3. Replace `assets/scrcpy-server.jar`, update `ScrcpyServerConstants.version` and the README badge. Run `flutter test` (version and option-key guards).
4. Run `dart run tool/verify_scrcpy_server.dart --serial=<serial>` on an old device **and** on the newest Android (emulator is fine). It uses the app's exact arguments and retries like the native plugins. It checks that `keep_active` reports user activity while the server runs and that the device's sleep settings stay untouched, turns the screen off first and checks that `power_on` turns it back on (`--keep-screen` skips this), checks a leading session packet with the size, SPS/PPS and an IDR frame, sends HOME and BACK through the control socket (skipped while the phone is locked, or with `--skip-keys`), checks that the server ignores a touch with the wrong frame size, and checks that `SET_DISPLAY_POWER` turns the panel off while video keeps flowing and that it is on again after the server exits. On a PIN-locked phone, run it twice: once as is (checks `power_on`; keys are skipped because the phone locks), and once unlocked with `--keep-screen` (checks HOME and BACK).

---

## 6. Step 1 Results (v3.3.4)

**Provenance:** SHA-256 `8588238c…2303079e` matches `SHA256SUMS.txt` and GitHub's digest; `SHA256SUMS.txt` has a good signature from the maintainer key above.

| Device | v2.1 | v3.3.4 |
|:---|:---|:---|
| Xiaomi Redmi 9 (M2004J19C), Android 10, real device | ✅ stream OK | ✅ stream OK (SPS/PPS, IDR, P-frames) |
| Emulator, **Android 16** (API 36) | ❌ `NoSuchMethodException: SurfaceControl.createDisplay`, no video | ✅ stream OK (`Display: using DisplayManager API`) |

The native Swift and C++ parsers did not change: the v3.3.4 header and packet format are identical to v2.1 (verified in source and on the wire). The full app UI was not exercised in this check.

Findings recorded for later:
- With `control=false`, the server cannot power the screen on; a phone with its screen off produces no frames (the stream waits). ✅ Resolved: control is now enabled, which also enables `power_on`.
- The `stayAwake` setting is passed to `startServer` but never reaches the server. Wiring it to `stay_awake` changes a global device setting, and `cleanup=false` would leave it changed, so it needs its own decision. ✅ Resolved: `cleanup=true` with `stay_awake` and `screen_off_timeout`, a toolbar toggle, verified restored on device ([lesson](lessons-learned/scrcpy-cleanup-restore-ordering.md)).

---

## 7. Step 2 Assessment (v5.0.1)

Checked on 2026-10-18 against the v5.0.1 server source and the v4.0 – v5.0.1 release notes. The server diff v3.3.4 → v5.0.1 touches 51 files; v5.0 → v5.0.1 changes only the build version, so the v5.0.1 server behaves like v5.0. Most v4/v5 headlines are client-only (SDL3, hardware decoding, window, shortcuts) and do not affect DeskDroid, which ships only the server.

**Server changes that help DeskDroid**

| Change (version) | Effect for DeskDroid |
|:---|:---|
| `keep_active` (4.0) | Calls `PowerManager.userActivity()` every ~4 s. Keeps the phone awake **without changing any device setting**. It would replace Keep Phone Awake's `stay_awake` + 24 h `screen_off_timeout`, the risk of a lost restore after a reboot, and `ScrcpyCleanupWaiter`. |
| Encoder `KEY_PRIORITY` / `KEY_LATENCY` at minimum (4.0) | Lower encoding latency on encoders that honor it. |
| Encoder size constraints and alignment (4.0, fixed in 4.1) | Fewer encoder configuration failures on devices that need aligned sizes; the size may round by a few pixels (DeskDroid already reads the size from the stream). |
| Session packets (4.0) | Exact video size at start and after each rotation, before the first frame; touch mapping no longer waits for decoding. |
| `SCAN_FILE` control message (4.1) | Media scan through `MediaScannerConnection` instead of the deprecated `MEDIA_SCANNER_SCAN_FILE` broadcast. |
| Clipboard fix on rooted devices (4.0) | Helps the Quick Text paste path there. |
| Staying current | Future Android fixes land only on new versions. |

Not relevant: hardware decoding (DeskDroid already decodes natively), VP8/VP9, camera torch/zoom, flex display, gamepads, OTG.

**What breaks** (no compatibility mode; the jar and the parsers must change together)

| Area | v3.3.4 | v5.0.1 | Code to change |
|:---|:---|:---|:---|
| Video header after dummy byte + 64-byte name | codec + width + height (12 bytes) | codec only (4 bytes) | `scrcpy_core` `stream_header`, Swift `ScrcpyVideoSession`, `StreamProbe` |
| Video packets | — | session packet: `u32` (bit 31 = 1, bit 0 = client resize) + width + height | new parse branch in all three |
| Packet flags (video and audio) | config bit 63, key bit 62 | session bit 63, config bit 62, key bit 61 | `packet_header`, Swift video and audio sessions |
| Options DeskDroid passes | all present | all present (`send_codec_meta` renamed `send_stream_meta`, unused) | none |
| Socket order, dummy byte, device name, audio header, control messages 0–17, `Device:` log line | — | unchanged | none |

**Recommendation: upgrade now, together with `keep_active`.** The parsing changes are small and mostly in `scrcpy_core`, which is unit-tested on every OS, so the unverified Windows plugin only needs a few lines of glue. `keep_active` removes the most fragile part of Keep Phone Awake. Plan:

1. `scrcpy_core`: 4-byte video header, session packets, shifted flags, with tests (golden bytes from the v5.0.1 source).
2. Swift video and audio sessions, Windows `stream_session.cpp`, `StreamProbe`; size from session packets.
3. `ScrcpyServerCommand`: `keep_active=true` instead of `stay_awake` + `screen_off_timeout` (keep `cleanup=true` for display power); drop `ScrcpyCleanupWaiter`.
4. Jar, version constant, guards, contract docs; verify with `verify_scrcpy_server.dart` and `check_macos_native.sh` on Android 10 (Redmi 9) and Android 16 (emulator).

---

## 8. Step 2 Results (v5.0.1)

**Provenance:** SHA-256 `764eb6f7…2bc536` matches `SHA256SUMS.txt`; `SHA256SUMS.txt.asc` has a good signature from the maintainer key above. The jar is 733,930 bytes (it now includes the Kotlin standard library).

| Check | Xiaomi Redmi 9, Android 10 | Emulator, Android 16 |
|:---|:---|:---|
| `verify_scrcpy_server.dart --keep-screen` | ✅ `RESULT: OK`: 69-byte header, session packet first (`1080x2340`, a second one after a rotation event), SPS/PPS, IDR, HOME/BACK, size check, keep active, screen off | ⏳ not run (emulator being recreated) |
| `check_macos_native.sh video` (app's Swift classes) | ✅ `Session: 1080x2340`, hardware decoder, 69 frames, none after stop | ⏳ not run |
| Audio | Disabled by the server (Android 10) | ⏳ not run |

Notes:
- The size is now `1080x2340` on the Redmi (v3.3.4: `1080x2336`): v4.0's encoder alignment rules round differently. Touch mapping reads the size from the stream, so nothing else changed.
- Deviation from the plan: `ScrcpyCleanupWaiter` stays. With `keep_active` no setting needs restoring, but the restore process still turns the screen back on after Screen Off. On a pipeline restart, an old restore process that ran after DeskDroid turned the screen off on the new server would turn it on again, so the next start still waits for it.
- The Windows plugin (`stream_session.cpp`, `audio_session.cpp`) was updated but not compiled or run (no Windows machine); its parsing lives in `scrcpy_core`, which is tested on macOS in three build variants.
