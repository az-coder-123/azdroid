import 'dart:io';

import 'package:desk_droid/core/services/app_logger.dart';
import 'package:desk_droid/core/services/process_executor.dart';

/// Resolves and discovers the local ADB executable path across macOS environments.
class AdbPathResolver {
  const AdbPathResolver({
    this.executor = const DefaultProcessExecutor(),
    this.explicitPath,
  });

  final ProcessExecutor executor;
  final String? explicitPath;

  /// Known macOS fallback paths where ADB is frequently installed.
  static final List<String> _knownAdbPaths = [
    'adb',
    '${Platform.environment['HOME']}/Library/Android/sdk/platform-tools/adb',
    '/opt/homebrew/bin/adb',
    '/usr/local/bin/adb',
  ];

  /// Locates the active ADB executable path.
  Future<String?> resolve([String? cachedPath]) async {
    if (explicitPath != null) return explicitPath;
    if (cachedPath != null) return cachedPath;

    try {
      final whichRes = await executor.run('which', ['adb']);
      if (whichRes.exitCode == 0) {
        final path = whichRes.stdout.toString().trim();
        if (path.isNotEmpty && await File(path).exists()) {
          return path;
        }
      }
    } catch (_) {}

    for (final path in _knownAdbPaths) {
      if (await File(path).exists()) {
        return path;
      }
    }

    try {
      final res = await executor.run('adb', ['version']);
      if (res.exitCode == 0) return 'adb';
    } catch (_) {}

    AppLogger.warning('Could not resolve ADB executable on system.');
    return null;
  }
}
