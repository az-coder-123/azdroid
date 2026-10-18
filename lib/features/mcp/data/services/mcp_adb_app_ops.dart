part of 'mcp_adb_client.dart';

/// Static operations providing application lifecycle and package governance for MCP.
class McpAdbAppOps {
  const McpAdbAppOps._();

  /// The foreground app (`package`, `activity`) and, when a system window
  /// such as the lock screen is in front of it, `overlay`.
  static Future<Map<String, String>?> getCurrentApp(
    McpAdbClient client,
    String serial,
  ) async {
    Future<String> dump(List<String> args) async =>
        (await client.run(['-s', serial, 'shell', 'dumpsys', ...args])).stdout
            .toString();

    final windows = await dump(['window', 'displays']);
    final app =
        McpForegroundAppParser.parse(windowDump: windows) ??
        McpForegroundAppParser.parse(
          windowDump: windows,
          activityDump: await dump(['activity', 'activities']),
        );
    if (app == null) return null;
    return {
      'package': app.package,
      'activity': app.activity,
      'overlay': ?app.overlayWindow,
    };
  }

  /// Launches an application by its package name using monkey launcher event.
  static Future<bool> launchApp(
    McpAdbClient client,
    String serial,
    String packageName,
  ) async {
    final res = await client.run([
      '-s',
      serial,
      'shell',
      'monkey',
      '-p',
      packageName,
      '-c',
      'android.intent.category.LAUNCHER',
      '1',
    ]);
    return res.exitCode == 0;
  }

  /// Force-terminates a running application.
  static Future<bool> stopApp(
    McpAdbClient client,
    String serial,
    String packageName,
  ) async {
    final res = await client.run([
      '-s',
      serial,
      'shell',
      'am',
      'force-stop',
      packageName,
    ]);
    return res.exitCode == 0;
  }

  /// Clears app user data and cache (resets app to freshly installed state).
  static Future<bool> clearAppData(
    McpAdbClient client,
    String serial,
    String packageName,
  ) async {
    final res = await client.run([
      '-s',
      serial,
      'shell',
      'pm',
      'clear',
      packageName,
    ]);
    return res.exitCode == 0;
  }

  /// Lists installed packages matching an optional filter or search query.
  static Future<List<String>> listPackages(
    McpAdbClient client,
    String serial, {
    bool thirdPartyOnly = true,
    String? query,
  }) async {
    final args = ['-s', serial, 'shell', 'pm', 'list', 'packages'];
    if (thirdPartyOnly) args.add('-3');
    final res = await client.run(args);
    if (res.exitCode != 0) return [];

    final lines = res.stdout.toString().splitLines();
    final pkgs = <String>[];
    for (final l in lines) {
      final trimmed = l.trim();
      if (trimmed.startsWith('package:')) {
        final name = trimmed.substring(8);
        if (query == null || name.toLowerCase().contains(query.toLowerCase())) {
          pkgs.add(name);
        }
      }
    }
    pkgs.sort();
    return pkgs;
  }
}
