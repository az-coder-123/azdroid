# scrcpy Server Upgrade Assessment (2026-10-18)

> Decision record: whether and how to upgrade the bundled scrcpy-server from **v2.1** (June 2023). Status: **step 1 done (v3.3.4, 2026-10-18)**; step 2 (v5.0.1) pending.

---

## 1. How DeskDroid Uses scrcpy

| Aspect | Current use |
|:---|:---|
| Server | `assets/scrcpy-server.jar` **v3.3.4** (was v2.1), started by `ScrcpyServerManager` |
| Arguments | `scid`, `tunnel_forward=true`, `video_bit_rate`, `max_fps`, `audio=false`, `control=true`, `clipboard_autosync=false`, `cleanup=true`, and with Keep Phone Awake `stay_awake=true` + `screen_off_timeout` |
| Video | H.264 parsed by `macos/Runner/ScrcpyStreamPlugin.swift` and `native/scrcpy_core` (Windows) |
| Input | scrcpy control socket for touch and keys; text and the fallback path use `adb shell input` ([remote-input-control.md](features/remote-input-control.md)) |
| Audio | **Not functional**: the server runs with `audio=false`, and no Opus/AAC decoder or player exists; the UI toggle only changes state |
| Readiness | Waits for the `[server] INFO: Device:` log line |

Only the video socket is used, so protocol changes to the video stream are what matter.

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
- **Audio**: either implement it (scrcpy audio, Android 11+, plus an Opus decoder and player on both platforms) or hide the toggle until it works.

---

## 5. Upgrade Procedure

1. Download `scrcpy-server-vX` and `SHA256SUMS.txt` + `.asc` from the GitHub release. Check the SHA-256 against both the sums file and GitHub's asset digest, and verify the signature with Romain Vimont's key from `https://github.com/rom1v.gpg` (primary fingerprint `4569 58E8 5A18 5DD5 C2D1 E4E8 0C82 2B29 8461 FA03`) in a temporary `GNUPGHOME`.
2. Diff the wire format in the server **source** (`Streamer.java`, `DesktopConnection.java`), not only `doc/develop.md`.
3. Replace `assets/scrcpy-server.jar`, update `ScrcpyServerConstants.version` and the README badge. Run `flutter test` (version and option-key guards).
4. Run `dart run tool/verify_scrcpy_server.dart --serial=<serial>` on an old device **and** on the newest Android (emulator is fine). It uses the app's exact arguments and retries like the native plugins. It checks that the stay-awake settings change while the server runs and come back after it stops, turns the screen off first and checks that `power_on` turns it back on (`--keep-screen` skips this), checks SPS/PPS and an IDR frame, sends HOME and BACK through the control socket (skipped while the phone is locked, or with `--skip-keys`), checks that the server ignores a touch with the wrong frame size, and checks that `SET_DISPLAY_POWER` turns the panel off while video keeps flowing and that it is on again after the server exits.

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

