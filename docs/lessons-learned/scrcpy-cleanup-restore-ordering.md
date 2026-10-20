# scrcpy Stay Awake: Restore Process, Jar Deletion, and Restart Ordering

## 1. Context & Symptoms

Azdroid needed "keep the phone awake while mirroring". scrcpy-server offers `stay_awake` and `screen_off_timeout`, but both change **global device settings**. Azdroid ran with `cleanup=false`, so a changed setting would have stayed changed after mirroring, and the phone would never sleep on its own again. Also, `stay_awake` alone does nothing for a phone on battery over Wi-Fi: it sets "stay on while plugged in".

## 2. Diagnostic Traces & Evidence

- scrcpy v3.3.4 `CleanUp.java`: with `cleanup=true`, the server starts a separate `app_process` (`com.genymobile.scrcpy.CleanUp`, own session via `setsid`). It records the old values, waits for its stdin to close (the server exiting), and then restores them. It records a value only **if it differs** from the new one. It also deletes the server jar (`unlinkSelf`).
- Redmi 9 (Android 10), original values `stay_on_while_plugged_in=0` (temporarily, for the test) and `screen_off_timeout=600000`:
  ```text
  during:    7 86400000
  t+250ms:   7 600000
  t+500ms:   0 600000      # both restored ~0.5 s after the server was killed
  jar:       No such file or directory
  ```
  The device was then set back to its real original values (`7`, `600000`).
- A first `pgrep -f com.genymobile.scrcpy.CleanUp` always found one PID, its own shell (the pattern is in its command line). `pgrep -f '...CleanU[p]'` returned 1 (none), 0 (running), 1 (after restore), as expected.
- The verification tool now checks the round trip: `original=600000, during=86400000, after=600000 (changed=true, restored=true)`.

## 3. Root Cause Analysis

Three facts are easy to miss:

1. **Restore needs `cleanup=true`.** Without it, scrcpy changes the setting and never puts it back.
2. **The restore runs after the server exits, asynchronously.** On a pipeline restart (bitrate or keep-awake change), a new server can start while the old restore process is still running. If it reads the settings before the old values come back, it sees the changed value, considers it "unchanged", and records nothing. The old process then restores the original, so the new session silently is not kept awake. This was **not reproduced** on the Redmi (push + start took longer than the ~0.5 s restore), but nothing in scrcpy orders the two; it depends on device speed.
3. **`cleanup=true` deletes the pushed jar.** That is fine only because Azdroid pushes the jar on every start.

## 4. Architectural Solution

- `ScrcpyServerCommand`: `cleanup=true` always; with stay awake, `stay_awake=true` (charging) **and** `screen_off_timeout` (battery). The timeout is 24 hours (`ScrcpyServerConstants.stayAwakeScreenOffTimeoutMs`), not "forever". If the restore is lost (the phone reboots mid-session), the phone still sleeps eventually.
- `ScrcpyCleanupWaiter` polls `pgrep` for the restore process before each server start (bounded at 3 s, never throws). A guard test checks that the `CleanUp` class exists in the bundled jar.
- The choice is a user preference (`MirroringPreferences`, `FileMirroringPreferencesRepository`, default on) with a toolbar toggle. A change restarts the pipeline via the shared `StreamingReconfigurator`.
- `tool/verify_scrcpy_server.dart` checks changed-while-running and restored-after-stop on every scrcpy upgrade.
- [troubleshooting.md](../troubleshooting.md) explains how to fix the settings if the phone restarted mid-session.

## 5. Prevention & Reusability Checklist

- [ ] Before enabling a scrcpy option, read whether it changes a device setting and who restores it.
- [ ] When an external process restores state asynchronously, order the next start after it, or the "original" value you record may be your own.
- [ ] Prefer a finite value over "infinite" for a setting that may fail to be restored.
- [ ] Record a device's original settings before an experiment, and verify they are restored after it.
- [ ] With `pgrep -f`/`pkill -f` over `adb shell`, bracket one character of the pattern so it does not match its own shell.

## Update: scrcpy v5.0.1 and `keep_active` (2026-10-18)

- Keep Phone Awake now uses `keep_active=true` (scrcpy 4.0+): the server reports user activity every 4 s and changes no device setting. `stay_awake`, `screen_off_timeout` and the 24-hour constant are gone. The verification tool checks that the settings stay untouched and that the last user-activity time advances on its own.
- The upgrade plan said to drop `ScrcpyCleanupWaiter` with it. While implementing, the restore process turned out to have a second job: it turns the screen back on after Screen Off. On a restart, an old restore process that runs late would undo the "off" sent to the new server, so the waiter stays, with its reason updated.
- [ ] Before removing a guard, list **every** state the guarded process touches, not only the one that motivated the guard.

