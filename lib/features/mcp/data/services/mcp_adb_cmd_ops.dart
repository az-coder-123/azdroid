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

  /// Dumps the recent logcat output.
  static Future<String> getLogcat(
    McpAdbClient client,
    String serial, {
    String? tag,
    int limit = 50,
  }) async {
    final cmd = ['-s', serial, 'logcat', '-d', '-t', '$limit'];
    if (tag != null && tag.isNotEmpty) {
      cmd.addAll(['-s', '$tag:*']);
    }
    final res = await client.run(cmd);
    return res.stdout.toString().trim();
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
    // 1. Query dedicated crash buffer (-b crash)
    final crashBufferRes = await client.run([
      '-s',
      serial,
      'logcat',
      '-b',
      'crash',
      '-d',
      '-t',
      '$limit',
    ]);
    final crashOutput = crashBufferRes.stdout.toString().trim();

    if (crashOutput.isNotEmpty &&
        !crashOutput.contains('--------- beginning of') &&
        (package == null ||
            crashOutput.toLowerCase().contains(package.toLowerCase()))) {
      return 'Crash detected in crash buffer:\n$crashOutput';
    }

    // 2. Query main logcat for FATAL EXCEPTION or AndroidRuntime errors
    final mainLogRes = await client.run([
      '-s',
      serial,
      'logcat',
      '-d',
      '-t',
      '${limit * 2}',
      '-s',
      'AndroidRuntime:E',
    ]);
    final mainLog = mainLogRes.stdout.toString().trim();

    if (mainLog.isNotEmpty &&
        (package == null ||
            mainLog.toLowerCase().contains(package.toLowerCase()))) {
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
        final snippet = anrOut.split('\n').take(30).join('\n');
        return 'ANR (Application Not Responding) detected for $package:\n$snippet';
      }
    }

    return 'No crashes or fatal exceptions detected${package != null ? ' for $package' : ''}.';
  }

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
