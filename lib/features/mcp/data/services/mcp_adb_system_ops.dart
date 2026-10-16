part of 'mcp_adb_client.dart';

/// Static operations for Android connectivity, audio volume, permissions, and settings navigation.
class McpAdbSystemOps {
  const McpAdbSystemOps._();

  /// Toggles device Wi-Fi radio on or off via svc.
  static Future<bool> toggleWifi(
    McpAdbClient client,
    String serial,
    bool enable,
  ) async {
    final cmd = [
      '-s',
      serial,
      'shell',
      'svc',
      'wifi',
      enable ? 'enable' : 'disable',
    ];
    final res = await client.run(cmd);
    return res.exitCode == 0;
  }

  /// Toggles device Airplane mode.
  static Future<bool> toggleAirplaneMode(
    McpAdbClient client,
    String serial,
    bool enable,
  ) async {
    final stateStr = enable ? 'enable' : 'disable';
    final res = await client.run([
      '-s',
      serial,
      'shell',
      'cmd',
      'connectivity',
      'airplane-mode',
      stateStr,
    ]);
    if (res.exitCode == 0) return true;

    // Fallback via settings put global
    final fbRes = await client.run([
      '-s',
      serial,
      'shell',
      'settings',
      'put',
      'global',
      'airplane_mode_on',
      enable ? '1' : '0',
    ]);
    return fbRes.exitCode == 0;
  }

  /// Grants a runtime permission to an application package.
  static Future<bool> grantPermission(
    McpAdbClient client,
    String serial,
    String packageName,
    String permission,
  ) async {
    final res = await client.run([
      '-s',
      serial,
      'shell',
      'pm',
      'grant',
      packageName,
      permission,
    ]);
    return res.exitCode == 0;
  }

  /// Revokes a runtime permission from an application package.
  static Future<bool> revokePermission(
    McpAdbClient client,
    String serial,
    String packageName,
    String permission,
  ) async {
    final res = await client.run([
      '-s',
      serial,
      'shell',
      'pm',
      'revoke',
      packageName,
      permission,
    ]);
    return res.exitCode == 0;
  }

  /// Sets audio stream volume (stream: 1=SYSTEM, 2=RING, 3=MUSIC/MEDIA, 4=ALARM, 5=NOTIFICATION).
  static Future<bool> setVolume(
    McpAdbClient client,
    String serial, {
    required int stream,
    required int volumeIndex,
  }) async {
    final res = await client.run([
      '-s',
      serial,
      'shell',
      'cmd',
      'media_session',
      'volume',
      '--stream',
      '$stream',
      '--set',
      '$volumeIndex',
    ]);
    return res.exitCode == 0;
  }

  /// Wakes up the device screen or puts it into sleep mode.
  static Future<bool> wakeOrSleep(
    McpAdbClient client,
    String serial,
    bool wake,
  ) async {
    final keyCode = wake ? 224 : 223; // KEYCODE_WAKEUP vs KEYCODE_SLEEP
    final res = await client.run([
      '-s',
      serial,
      'shell',
      'input',
      'keyevent',
      '$keyCode',
    ]);
    return res.exitCode == 0;
  }

  /// Launches a system settings panel or specific application details view.
  static Future<String> openSettings(
    McpAdbClient client,
    String serial, {
    String? action,
    String? packageName,
  }) async {
    final targetAction =
        action ??
        (packageName != null && packageName.isNotEmpty
            ? 'android.settings.APPLICATION_DETAILS_SETTINGS'
            : 'android.settings.SETTINGS');

    final cmd = ['-s', serial, 'shell', 'am', 'start', '-a', targetAction];
    if (packageName != null && packageName.isNotEmpty) {
      cmd.addAll(['-d', 'package:$packageName']);
    }

    final res = await client.run(cmd);
    return res.stdout.toString().trim();
  }
}
