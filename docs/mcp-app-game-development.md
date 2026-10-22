# Building Apps and Games with the Azdroid MCP Server

> How an AI assistant uses Azdroid's tools to check its own changes to an Android app or game: install, launch, test, read logs, measure, and look at screens that have no UI tree. Tool reference: [mcp-setup-guide.md](mcp-setup-guide.md#️-published-mcp-tools-38-tools). Safety: [mcp-tool-safety.md](mcp-tool-safety.md).

---

## 1. The Loop After Every Change

| Step | Call | Notes |
| :--- | :--- | :--- |
| Install | `android_install_apk(apkPath)` | Destructive: replaces the installed build. |
| Launch and time it | `android_launch_app(package, measure: true)` | Cold start by default (force-stops first). Returns `TotalTime` (first frame) and `WaitTime`. |
| Run the tests | `android_run_instrumentation(package)` | Finds the installed test runner; `testClass` narrows the run. Failures come with the top of their stack. |
| Read this run's logs | `android_get_logcat(package, sinceSeconds: 60)` | Only the app's process, only the last minute. The app must be running. |
| After a crash | `android_get_logcat(crashesOnly: true, package)` | Reads the crash buffer and AndroidRuntime errors; works after the process died. |

`android_run_instrumentation` needs the test APK on the device (for example `./gradlew installDebugAndroidTest`; a Flutter app's `integration_test` runs through the same runner). It stops after `timeoutSec` (default 600).

## 2. Screens Without a UI Tree (Games)

Games drawn with OpenGL, Vulkan, or an engine expose no accessibility nodes, so `android_get_ui_tree` and `android_click_element` see nothing. Use pictures instead:

1. **Get a template.** Either a sprite file from the project (`templatePath`), or a region of the current screen saved under a name: `android_find_image(saveAs: "start_button", x, y, width, height)`. Saved templates live in the server process's memory until it stops; nothing is written to disk.
2. **Find it.** `android_find_image(templateName: "start_button")` returns the center in pixels and as screen fractions, a score (1.0 = identical), and the size scale. Tap with `android_tap(xPixel, yPixel)`.
3. **Wait for it.** `android_wait_for_condition(condition: "image_present", templateName)` polls until it appears.
4. **Wait for anything to happen.** `android_wait_for_condition(condition: "screen_changed")` returns once at least `minChange` (default 1%) of the screen differs; the status bar is ignored.

Matching uses grayscale normalized cross-correlation, so it tolerates brightness and contrast changes but not rotation. When the template does not match at its own size, sizes 0.5×–3× are tried (pass `scale` when known). Measured 2026-10-22 on a Moto g play (720×1600): a saved region and a file crop were both found at the exact pixel position with score 1.000; synthetic tests find a 64 px template in about 0.2 s and a 2× scaled sprite in about 1 s.

Game keys: `android_press_key` accepts `DPAD_*`, `BUTTON_A`/`B`/`X`/`Y`/`L1`/`R1`/`START`/`SELECT`, `SPACE`, and `ESCAPE`.

## 3. Performance

| Question | Call |
| :--- | :--- |
| Is it smooth? | `android_get_device_stats(kind: "fps", package)`: samples `durationMs` (default 2000); `durationMs: 0` reads the last ≤128 frames already drawn, e.g. right after a swipe. |
| Is the phone throttling? | `android_get_device_stats(kind: "thermal")`: status (0 none … 6 shutdown) and sensor temperatures; status 2 or more means the system is cutting CPU/GPU speed. |
| Memory and CPU | `kind: "memory"` / `"cpu"` with `package`. |

`fps` reads `dumpsys SurfaceFlinger --latency` for the app's windows and keeps the one that drew the most, so it covers SurfaceView, OpenGL, and Vulkan content, which `kind: "gfx"` (`dumpsys gfxinfo`) does not. Pauses longer than 250 ms count as idle, not as slow frames. Measured on the Moto (90 Hz): scrolling Settings read 90.4 fps; a static screen read 0 frames; the Settings home page drew continuously because of an animation, which `gfxinfo` confirmed (193 frames in 2 s).

## 4. Layouts on Other Screens

`android_set_display_config` changes, until reset:

| Parameter | Effect |
| :--- | :--- |
| `nightMode: "yes"` | Dark theme (`cmd uimode night`; Settings visibly switched on Android 13). |
| `fontScale: 1.3` | Larger text, to catch clipped labels. |
| `density: "240"`, `size: "600x1334"` | Smaller density or another screen size; `"reset"` restores each. |
| `reset: true` | Light mode, font scale 1.0, physical density and size. |

Always finish with `reset: true`. A changed size also changes what Azdroid mirrors.

## 5. Limits

- `android_launch_app(measure: true)` on a locked screen cannot show the app; it stops after 30 s and says so. Android may still open the app once the phone is unlocked.
- Warm starts right after HOME sometimes report no `TotalTime` on Android 13; use cold starts to compare builds.
- Touch timing still goes through `adb shell input` (about 100–300 ms per command), which is too slow for rhythm or multi-finger game input.
- Not verified yet: a real `android_run_instrumentation` run (neither test phone had a test APK; its parser is tested with sample output in the documented `am instrument -r` format), and dark mode on Android 10.
