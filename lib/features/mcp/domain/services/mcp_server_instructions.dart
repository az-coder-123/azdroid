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
2. Inspect before acting: android_get_semantic_tree returns a compact digest
   with [#ID] tags. Use android_dump_hierarchy only when raw XML is needed.
3. Prefer semantic targeting: android_click_element_by_id with the [#ID] from
   the latest tree, or android_click_element / android_find_element matched by
   text, resourceId, or contentDesc. Fall back to android_tap with coordinates
   taken from the tree or a screenshot.
4. Text entry: android_set_text pastes exact text (IME-safe) and replaces
   the device clipboard; where adb cannot set the clipboard it types ASCII
   and rejects other text, and the result says which. android_type_text
   types ASCII only and keeps the clipboard.
5. Wait, do not poll: android_wait_for_condition / android_wait_for_element
   block host-side until the state matches. Chain long sequences into a single
   android_batch_actions macro.
6. Verify and diagnose: android_take_screenshot (use crop and jpeg quality to
   save tokens), android_check_crash and android_get_logcat for failures.

Device support: a tool error that says a feature is unsupported on the
device (clipboard, biometrics, mock location, notification snooze) is final
for that device; do not retry it, report it or use another approach.

Tool selection rules:
- android_drag for precise sliders/seekbars, android_swipe for inertial
  flicks, android_scroll for directional list scrolling.
- android_press_key for navigation keys (BACK, HOME, APP_SWITCH, ...);
  android_press_button for media, camera, wake, and sleep controls.
- Coordinates accept normalized ratios (0.0 to 1.0) or physical pixels;
  prefer xRatio/yRatio or xPixel/yPixel (and the startX/startY variants) to
  make the unit explicit.
- Confirm user intent before any destructive tool:
  * Data loss or reset: android_clear_app_data, android_install_apk,
    android_shell_command, android_kill_process, android_stop_app,
    android_dismiss_notification, android_revoke_permission (kills the app).
  * File overwrite: android_push_file, android_pull_file.
  * Connection loss: android_toggle_wifi (off), android_toggle_airplane_mode
    (on) and android_set_network_condition (offline, data_only) drop a
    Wi-Fi ADB connection with no remote way back; use them over USB only.
''';
