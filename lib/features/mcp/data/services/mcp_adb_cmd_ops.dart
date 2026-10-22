part of 'mcp_adb_client.dart';

/// Static operations for intent dispatching, logcat diagnostics, APK sideloading, and raw shell execution.
class McpAdbCmdOps {
  const McpAdbCmdOps._();

  /// Fires an explicit or implicit Android intent.
  static Future<String> dispatchIntent(
    McpAdbClient client,
    String serial,
    String action, {
    String? dataUri,
    String? package,
    String? component,
    Map<String, dynamic>? extras,
  }) async {
    final cmd = ['-s', serial, 'shell', 'am', 'start', '-a', action];
    if (dataUri != null && dataUri.isNotEmpty) {
      cmd.addAll(['-d', dataUri]);
    }
    if (package != null && package.isNotEmpty) {
      cmd.addAll(['-p', package]);
    }
    if (component != null && component.isNotEmpty) {
      cmd.addAll(['-n', component]);
    }
    if (extras != null) {
      extras.forEach((key, value) {
        if (value is bool) {
          cmd.addAll(['--ez', key, value.toString()]);
        } else if (value is int) {
          cmd.addAll(['--ei', key, value.toString()]);
        } else {
          cmd.addAll(['--es', key, value.toString()]);
        }
      });
    }
    final res = await client.run(cmd);
    return res.stdout.toString().trim();
  }

  /// Logcat priorities, lowest first (Verbose … Fatal).
  static const List<String> logcatLevels = ['V', 'D', 'I', 'W', 'E', 'F'];

  /// The newest [limit] log lines, optionally only [tag], only from [level]
  /// up, only from process [pid] (`--pid`, Android 7+), and only since
  /// [sinceEpochSeconds] on the device clock (`-t <seconds>.000`).
  ///
  /// `logcat -t N` keeps the last N lines of the whole buffer *before* the
  /// filter runs (a level E query with `-t 3` returned nothing on Android
  /// 13), so filtered reads dump the filtered buffer and keep the tail here.
  static Future<String> getLogcat(
    McpAdbClient client,
    String serial, {
    String? tag,
    String? level,
    int limit = 50,
    int? pid,
    int? sinceEpochSeconds,
  }) async {
    final minLevel = logcatLevels.contains(level?.toUpperCase())
        ? level!.toUpperCase()
        : logcatLevels.first;
    final hasTag = tag != null && tag.isNotEmpty;
    final filtered =
        hasTag ||
        minLevel != logcatLevels.first ||
        pid != null ||
        sinceEpochSeconds != null;
    final res = await client.run([
      '-s',
      serial,
      'logcat',
      '-d',
      if (!filtered) ...['-t', '$limit'],
      if (pid != null) '--pid=$pid',
      // `adb logcat` quotes each argument for the device shell itself:
      // extra quotes would reach logcat ("not in time format").
      if (sinceEpochSeconds != null) ...['-t', '$sinceEpochSeconds.000'],
      // Filter spec "<tag>:<level>"; with a tag, every other tag is silenced.
      if (hasTag) ...['-s', '$tag:$minLevel'],
      if (!hasTag && filtered) '*:$minLevel',
    ]);
    return _logEntries(res.stdout.toString(), limit);
  }

  /// The id of [package]'s running process, or `null` when it is not
  /// running.
  static Future<int?> pidOf(
    McpAdbClient client,
    String serial,
    String package,
  ) async {
    final res = await client.run(['-s', serial, 'shell', 'pidof', package]);
    return int.tryParse(res.stdout.toString().trim().split(' ').first);
  }

  /// The device clock in seconds since the epoch.
  static Future<int?> deviceEpochSeconds(
    McpAdbClient client,
    String serial,
  ) async {
    final res = await client.run(['-s', serial, 'shell', 'date', '+%s']);
    return int.tryParse(res.stdout.toString().trim());
  }

  /// Installs an APK file from host machine onto the target device.
  static Future<bool> installApk(
    McpAdbClient client,
    String serial,
    String apkPath, {
    bool reinstall = true,
    bool grantPermissions = true,
  }) async {
    final cmd = ['-s', serial, 'install'];
    if (reinstall) cmd.add('-r');
    if (grantPermissions) cmd.add('-g');
    cmd.add(apkPath);
    final res = await client.run(cmd);
    return res.exitCode == 0;
  }

  /// Executes an arbitrary shell command.
  static Future<String> shell(
    McpAdbClient client,
    String serial,
    String command,
  ) async {
    final res = await client.run(['-s', serial, 'shell', command]);
    return 'Exit: ${res.exitCode}\n${res.stdout}\n${res.stderr}'.trim();
  }

  /// Inspects Android dedicated crash buffer (-b crash) and runtime exceptions.
  static Future<String> checkCrash(
    McpAdbClient client,
    String serial, {
    String? package,
    int limit = 50,
  }) async {
    // 1. The dedicated crash buffer (-b crash).
    final crashBufferRes = await client.run([
      '-s',
      serial,
      'logcat',
      '-b',
      'crash',
      '-d',
    ]);
    final crashOutput = _logEntries(crashBufferRes.stdout.toString(), limit);
    if (crashOutput.isNotEmpty && _mentions(crashOutput, package)) {
      return 'Crash detected in crash buffer:\n$crashOutput';
    }

    // 2. AndroidRuntime errors (FATAL EXCEPTION) in the main buffer. Filter
    // before taking the tail: `-t` counts lines before the filter applies.
    final mainLogRes = await client.run([
      '-s',
      serial,
      'logcat',
      '-d',
      '-s',
      'AndroidRuntime:E',
    ]);
    final mainLog = _logEntries(mainLogRes.stdout.toString(), limit * 2);
    if (mainLog.isNotEmpty && _mentions(mainLog, package)) {
      return 'Fatal exception detected in AndroidRuntime:\n$mainLog';
    }

    // 3. Check for ANR traces if package provided
    if (package != null && package.isNotEmpty) {
      final anrRes = await client.run([
        '-s',
        serial,
        'shell',
        'dumpsys',
        'activity',
        'lastanr',
      ]);
      final anrOut = anrRes.stdout.toString().trim();
      if (anrOut.contains(package)) {
        final snippet = anrOut.splitLines().take(30).join('\n');
        return 'ANR (Application Not Responding) detected for $package:\n$snippet';
      }
    }

    return 'No crashes or fatal exceptions detected${package != null ? ' for $package' : ''}.';
  }

  /// The last [limit] log lines without logcat's `--------- beginning of`
  /// buffer headers, which logcat prints even when no entry matched.
  static String _logEntries(String output, int limit) {
    final lines = output
        .splitLines()
        .where((l) => l.trim().isNotEmpty && !l.startsWith('---------'))
        .toList();
    return lines.skip(max(0, lines.length - limit)).join('\n');
  }

  static bool _mentions(String log, String? package) =>
      package == null || log.toLowerCase().contains(package.toLowerCase());

  /// Triggers MediaStore to index a newly pushed or modified media file immediately.
  static Future<bool> scanMediaFile(
    McpAdbClient client,
    String serial,
    String filePath,
  ) async {
    final formattedPath = filePath.startsWith('file://')
        ? filePath
        : 'file://$filePath';
    final res = await client.run([
      '-s',
      serial,
      'shell',
      'am',
      'broadcast',
      '-a',
      'android.intent.action.MEDIA_SCANNER_SCAN_FILE',
      '-d',
      formattedPath,
    ]);
    return res.exitCode == 0;
  }
}
