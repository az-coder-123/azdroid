import 'dart:io';

import 'package:desk_droid/core/services/process_executor.dart';

/// Callback invoked when a single ADB discovery probe fails.
///
/// Receives a short description of the probe and the thrown error so callers
/// can route diagnostics to their own logger (Flutter app or pure Dart CLI).
typedef AdbProbeFailureHandler = void Function(String probe, Object error);

/// Pure Dart ADB executable discovery shared by the app and the MCP server.
///
/// This class must stay free of Flutter imports because the MCP server runs
/// through the plain `dart` VM.
class AdbBinaryLocator {
  const AdbBinaryLocator({
    this.executor = const DefaultProcessExecutor(),
    this.onProbeFailure,
    this.fileExists = _defaultFileExists,
    this.environment,
  });

  /// Bare command name resolved through the current `PATH`.
  static const String adbCommand = 'adb';

  /// Absolute path of the `which` utility on macOS and Linux.
  static const String whichExecutable = '/usr/bin/which';

  /// Argument used to verify that an ADB candidate is runnable.
  static const String versionArgument = 'version';

  /// Absolute installation paths checked when `which` cannot find ADB.
  static const List<String> systemAdbPaths = [
    '/opt/homebrew/bin/adb',
    '/usr/local/bin/adb',
  ];

  /// SDK-relative path of the ADB binary inside an Android SDK root.
  static const String sdkPlatformToolsAdb = 'platform-tools/adb';

  /// Default Android SDK location relative to the user's home directory.
  static const String defaultSdkHomeSubpath = 'Library/Android/sdk';

  /// Environment variables that may point to an Android SDK root.
  static const List<String> sdkEnvironmentKeys = [
    'ANDROID_HOME',
    'ANDROID_SDK_ROOT',
  ];

  final ProcessExecutor executor;
  final AdbProbeFailureHandler? onProbeFailure;
  final Future<bool> Function(String path) fileExists;

  /// Environment override for tests; defaults to [Platform.environment].
  final Map<String, String>? environment;

  static Future<bool> _defaultFileExists(String path) => File(path).exists();

  /// Candidate absolute ADB paths, ordered by preference.
  List<String> get candidatePaths {
    final env = environment ?? Platform.environment;
    final sdkRoots = <String>[
      for (final key in sdkEnvironmentKeys)
        if (env[key]?.isNotEmpty ?? false) env[key]!,
      if (env['HOME']?.isNotEmpty ?? false)
        '${env['HOME']}/$defaultSdkHomeSubpath',
    ];
    return [
      for (final root in sdkRoots) '$root/$sdkPlatformToolsAdb',
      ...systemAdbPaths,
    ];
  }

  /// Returns the first usable ADB executable, or `null` when none is found.
  Future<String?> locate() async {
    final fromPath = await _locateViaWhich();
    if (fromPath != null) return fromPath;

    for (final path in candidatePaths) {
      if (await _safeFileExists(path)) return path;
    }

    return await _isRunnable(adbCommand) ? adbCommand : null;
  }

  Future<String?> _locateViaWhich() async {
    try {
      final result = await executor.run(whichExecutable, [adbCommand]);
      final path = result.stdout.toString().trim();
      if (result.exitCode == 0 &&
          path.isNotEmpty &&
          await _safeFileExists(path)) {
        return path;
      }
    } catch (error) {
      onProbeFailure?.call('which $adbCommand', error);
    }
    return null;
  }

  Future<bool> _safeFileExists(String path) async {
    try {
      return await fileExists(path);
    } catch (error) {
      onProbeFailure?.call('stat $path', error);
      return false;
    }
  }

  Future<bool> _isRunnable(String executable) async {
    try {
      final result = await executor.run(executable, [versionArgument]);
      return result.exitCode == 0;
    } catch (error) {
      onProbeFailure?.call('$executable $versionArgument', error);
      return false;
    }
  }
}
