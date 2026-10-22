/// Agent-facing workflow guidance returned in the MCP `initialize` response.
///
/// Clients such as Claude Desktop and Cursor surface this string to the model
/// so it learns the intended tool-usage patterns before its first tool call.
/// Only verified behaviors of the executors may be documented here
/// (zero claims without code).
const String mcpServerInstructions = '''
Azdroid controls Android devices over USB/Wi-Fi via ADB.

Default workflow:
1. Call android_list_devices first. Pass the serial as deviceSerial when
   several devices are attached (tools refuse to guess); with a single
   device it can be omitted.
2. Inspect before acting: android_get_ui_tree returns a compact digest with
   [#ID] tags (format "xml" for raw XML when needed).
3. Prefer semantic targeting: android_click_element with id (the [#ID] from
   the latest tree) or with text, resourceId, or contentDesc. Fall back to
   android_tap with coordinates from the tree or a screenshot.
4. Text entry: android_input_text pastes exact text (IME-safe) and replaces
   the device clipboard; where adb cannot set the clipboard it types ASCII
   and rejects other text, and the result says which. method "type" types
   ASCII only and keeps the clipboard. An empty text clears the field.
5. Wait, do not poll: android_wait_for_condition blocks on the computer until
   the state matches. Chain long sequences into one android_batch_actions.
6. Verify and diagnose: android_take_screenshot (crop and JPEG quality save
   tokens), android_get_logcat (package and sinceSeconds for the app's own
   recent logs, crashesOnly for crash traces).

Building an app or game:
- After a change: android_install_apk, android_launch_app (measure: true
  for launch time), android_run_instrumentation for the app's tests.
- Games and canvases have no UI tree: android_find_image locates a sprite
  or a saved screen region, android_wait_for_condition image_present or
  screen_changed waits on the picture. android_multitouch_gesture with
  gesture "strokes" plays several fingers at once with ms timing (hold a
  joystick while tapping).
- Performance: android_get_device_stats kind "fps" (any window, games
  included), "thermal" (throttling), "memory", "cpu".
- Layout checks: android_set_display_config (dark mode, font scale,
  density, size); call it with reset: true when done.

Device support: a tool error that says a feature is unsupported on the
device (clipboard, biometrics, mock location, notification snooze) is final
for that device; do not retry it, report it or use another approach.

Tool selection rules:
- android_swipe: start/end for a fling, style "drag" for sliders and precise
  moves, direction for plain list scrolling.
- android_tap: taps 2 for a double tap, holdMs for a long press.
- android_press_key covers navigation, hardware, media, screen power
  (WAKEUP, SLEEP), and status bar panels (NOTIFICATIONS, QUICK_SETTINGS).
- Coordinates accept normalized ratios (0.0 to 1.0) or physical pixels;
  prefer xRatio/yRatio or xPixel/yPixel (and the startX/startY variants) to
  make the unit explicit.
- Confirm user intent before any destructive tool:
  * Data loss or reset: android_clear_app_data, android_install_apk,
    android_shell_command, android_stop_app, android_dismiss_notification,
    android_set_permission (revoking kills the app).
  * File overwrite: android_transfer_file.
  * Connection loss: android_set_network (offline, data_only, wifi_off,
    airplane_on) drops a Wi-Fi ADB connection with no remote way back; use
    it over USB only.
''';
