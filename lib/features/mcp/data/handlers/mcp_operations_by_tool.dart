/// The executor operations each consolidated tool reaches
/// (`McpToolRouter.route` picks one per call). The catalog guard test
/// requires every key to be published and every operation to have a handler.
const Map<String, Set<String>> mcpOperationsByTool = {
  'android_tap': {'android_tap', 'android_double_tap', 'android_long_press'},
  'android_swipe': {'android_swipe', 'android_drag', 'android_scroll'},
  'android_multitouch_gesture': {
    'android_pinch_gesture',
    'android_rotate_gesture',
  },
  'android_input_text': {
    'android_set_text',
    'android_type_text',
    'android_clear_text',
  },
  'android_press_key': {
    'android_press_key',
    'android_press_button',
    'android_open_notification_panel',
  },
  'android_get_ui_tree': {
    'android_get_semantic_tree',
    'android_dump_hierarchy',
  },
  'android_click_element': {
    'android_click_element',
    'android_click_element_by_id',
  },
  'android_stop_app': {'android_stop_app', 'android_kill_process'},
  'android_set_permission': {
    'android_grant_permission',
    'android_revoke_permission',
  },
  'android_get_device_stats': {
    'android_get_device_info',
    'android_get_battery_stats',
    'android_get_network_info',
    'android_get_cpu_usage',
    'android_get_memory_info',
    'android_get_gfx_info',
    'android_get_frame_rate',
    'android_get_thermal',
  },
  'android_set_network': {
    'android_set_network_condition',
    'android_toggle_wifi',
    'android_toggle_airplane_mode',
  },
  'android_clipboard': {'android_get_clipboard', 'android_set_clipboard'},
  'android_transfer_file': {
    'android_push_file',
    'android_pull_file',
    'android_scan_media_file',
  },
  'android_list_apps': {'android_list_packages', 'android_list_processes'},
  'android_get_logcat': {
    'android_get_logcat',
    'android_check_crash',
    'android_get_app_logcat',
  },
  'android_launch_app': {'android_launch_app', 'android_measure_app_start'},
  'android_wait_for_condition': {
    'android_wait_for_condition',
    'android_wait_for_screen',
  },
};
