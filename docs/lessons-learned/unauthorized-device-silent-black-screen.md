# Unauthorized Device Shows a Silent Black Screen

> **Subsystem:** Streaming (`lib/features/streaming/data/`, `presentation/cubit/`)
> **Affected Platform:** All hosts; first seen on Windows with a phone that trusted only a Mac
> **Severity:** High (mirroring looks connected but shows nothing, with no error)
> **Resolution Date:** October 2026

---

## 1. 🔍 Context & Symptoms

On the first Windows run, the mirroring page opened with a black viewport. The
header still showed a green dot and `16ms`, `60 FPS`, `8 Mbps`, so the session
looked healthy. The Logcat panel stayed empty. Nothing told the user what was
wrong or what to do.

---

## 2. 🔬 Diagnostic Traces & Evidence

1. `deskdroid_dart.log` contained the real cause, logged only at debug level:
   ```text
   [scrcpy err] adb.exe: device unauthorized.
   Native video stream started with textureId: 2935551678384
   [logcat stderr] - waiting for device -
   ```
2. `%TEMP%\scrcpy_stream.log` showed the native plugin retrying a socket that
   never opened, then giving up 70 seconds later:
   ```text
   Session thread started for 127.0.0.1:27183
   Failed to connect and read the stream header after retries
   ```
3. `adb devices -l` confirmed the state:
   ```text
   192.168.1.3:5555       unauthorized transport_id:1
   ```
4. After the phone accepted the key (`adb disconnect` + `adb connect` showed
   the prompt again), the same build decoded more than 1,100 frames.

---

## 3. 🧩 Root Cause Analysis

Every step after the ADB check reported success, even though the device was
not ready:

1. `ScrcpyServerManager.startServerDaemon` returns `true` once the `adb shell`
   process starts, even when ADB exits at once with `device unauthorized`.
   `StreamingRepositoryImpl` also ignored its `false` result (ADB missing).
2. The native `startStream` returns a texture ID right away and connects in a
   background thread, so it cannot report a missing server synchronously.
3. The session entity used fixed telemetry values (`latencyMs: 16`), so the
   header looked healthy whatever happened.

ADB keys are stored per computer (`~/.android/adbkey`), so a phone that trusts
a Mac is still `unauthorized` for a new Windows PC.

---

## 4. 🏛️ Architectural Solution

1. **Domain error:** `StreamStartException` with a `StreamStartFailure` reason
   (`deviceUnauthorized`, `deviceOffline`, `deviceNotFound`,
   `serverStartFailed`) in `domain/errors/stream_start_exception.dart`.
2. **Preflight check:** `StreamDevicePreflight.ensureReady` reads
   `adb devices -l` and throws before any server or socket work starts.
3. **Checked server start:** the repository throws `serverStartFailed` when
   `startServerDaemon` returns `false`.
4. **Actionable UI:** `StreamingCubit` maps the reason to guidance with
   `StreamStartFailureMessage.messageFor` and emits `StreamingError`. The
   error view scrolls on short windows and wraps its buttons on narrow ones,
   and its **Retry Connection** button reruns the preflight.

---

## 5. ✅ Prevention & Reusability Checklist

- [x] **Check device readiness before long-running work.** A quick ADB state
      check is cheaper than a 70-second socket retry loop.
- [x] **Never ignore `bool` results from setup steps.** Turn `false` into a
      typed failure at the repository boundary.
- [x] **Map failures to guidance in the presentation layer.** Domain errors
      carry a reason; the cubit decides the wording.
- [ ] **Async native connections need their own failure signal.** Open: the
      native plugin should report "header never arrived" back to Dart.
- [ ] **Do not show fixed telemetry as live data.** Open: replace the fixed
      `latencyMs` with measured values.
