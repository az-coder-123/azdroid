part of 'mcp_adb_client.dart';

/// Static operations providing application lifecycle and package governance for MCP.
class McpAdbAppOps {
  const McpAdbAppOps._();

  /// Retrieves the package and activity of the app currently focused on the screen.
  static Future<Map<String, String>?> getCurrentApp(
    McpAdbClient client,
    String serial,
  ) async {
    final res = await client.run([
      '-s',
      serial,
      'shell',
      'dumpsys',
      'window',
      'displays',
    ]);
    final out = res.stdout.toString();
    final match =
        RegExp(
          r'mCurrentFocus=Window\{[^\}]*\s+([a-zA-Z0-9_\.]+)/([a-zA-Z0-9_\.]+)',
        ).firstMatch(out) ??
        RegExp(
          r'mFocusedApp=ActivityRecord\{[^\}]*\s+([a-zA-Z0-9_\.]+)/([a-zA-Z0-9_\.]+)',
        ).firstMatch(out);
    if (match != null) {
      return {'package': match.group(1)!, 'activity': match.group(2)!};
    }
    return null;
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
