# Pinned scrcpy v2.1 Silently Stopped Working on New Android Versions

## 1. Context & Symptoms

Azdroid bundled scrcpy-server v2.1 (June 2023) since its first commit. Mirroring worked on every device the project was tested with, so the pin looked safe. An upgrade assessment in October 2026 (scrcpy was at v5.0.1) found that v2.1 **cannot mirror at all** on Android 14 QPR3, 15, and 16: the newest and most common devices.

## 2. Diagnostic Traces & Evidence

- scrcpy issue [#4656](https://github.com/Genymobile/scrcpy/issues/4656), on Android 14 QPR3:
  ```text
  java.lang.NoSuchMethodException: android.view.SurfaceControl.createDisplay [class java.lang.String, boolean]
      at com.genymobile.scrcpy.ScreenCapture.createDisplay(ScreenCapture.java:77)
  ```
  The hidden API that v2.1 uses to capture the screen was removed. Fixed in v2.4.
- Issue [#6362](https://github.com/Genymobile/scrcpy/issues/6362): a crash on Android 16 QPR2, fixed in v3.3.3.
- The only test device was a Xiaomi M2004J19C on Android 10/11, which is not affected.

## 3. Root Cause Analysis

scrcpy-server runs on hidden Android framework APIs, which Google changes every release. A pinned server therefore has a **shelf life**, even if Azdroid's own code never changes. Two gaps hid this: test coverage used one old device, and nothing tracked upstream releases or compatibility fixes.

## 4. Architectural Solution

- `docs/scrcpy-upgrade-assessment.md` compares versions by protocol compatibility, verified against server source. v3.3.4 is the last release with the v2.1 wire format, so it fixes Android 15/16 without code changes; v4.0+ needs a parser update (session packets).
- `test/unit/scrcpy_server_version_test.dart` keeps the jar, client constant, and README in sync during upgrades.

## 5. Prevention & Reusability Checklist

- [ ] Treat dependencies that use hidden or private platform APIs as expiring; review them with each new Android release.
- [ ] Test on at least one device or emulator with the **latest** Android version, not only on what is at hand.
- [ ] Before upgrading across major versions, diff the wire protocol in the upstream **source**, not only the docs: docs can lag (scrcpy's v3.3.4 doc still said "protocol in scrcpy v2.1").
- [ ] Prefer the newest release that is protocol-compatible as a quick fix, then plan the protocol migration separately.
