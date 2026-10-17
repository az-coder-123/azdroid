import 'dart:io';

import 'package:desk_droid/core/extensions/line_split_extension.dart';
import 'package:desk_droid/core/platform/host_toolchain.dart';
import 'package:desk_droid/core/services/process_executor.dart';

/// Callback invoked when a single ADB discovery probe fails.
///
/// Receives a short description of the probe and the thrown error so callers
/// can route diagnostics to their own logger (Flutter app or pure Dart CLI).
typedef AdbProbeFailureHandler = void Function(String probe, Object error);

/// Pure Dart ADB executable discovery shared by the app and the MCP server.
///
/// All OS-specific names and folders come from [HostToolchain]; this class
/// only implements the search order. It must stay free of Flutter imports
/// because the MCP server runs through the plain `dart` VM.
class AdbBinaryLocator {
  AdbBinaryLocator({
    HostToolchain? toolchain,
    this.executor = const DefaultProcessExecutor(),
    this.onProbeFailure,
    this.fileExists = _defaultFileExists,
  }) : toolchain = toolchain ?? HostToolchain.current();

  /// Argument used to verify that an ADB candidate is runnable.
  static const String versionArgument = 'version';

  final HostToolchain toolchain;
  final ProcessExecutor executor;
  final AdbProbeFailureHandler? onProbeFailure;
  final Future<bool> Function(String path) fileExists;

  static Future<bool> _defaultFileExists(String path) => File(path).exists();

  /// Returns the first usable ADB executable, or `null` when none is found.
  ///
  /// Order: `PATH` lookup, SDK and system install folders, then a bare
  /// `adb` invocation as a last resort.
  Future<String?> locate() async {
    final fromPath = await _locateOnPath();
    if (fromPath != null) return fromPath;

    for (final path in toolchain.adbSearchPaths) {
      if (await _safeFileExists(path)) return path;
    }

    final bare = toolchain.adbExecutable;
    return await _isRunnable(bare) ? bare : null;
  }

  Future<String?> _locateOnPath() async {
    final lookup = toolchain.pathLookupCommand;
    final adb = toolchain.adbExecutable;
    try {
      final result = await executor.run(lookup, [adb]);
      if (result.exitCode != 0) return null;
      // `where` on Windows may print several matches; the first one wins.
      final lines = result.stdout.toString().splitLines();
      final path = lines.isEmpty ? '' : lines.first.trim();
      if (path.isNotEmpty && await _safeFileExists(path)) return path;
    } on Exception catch (error) {
      onProbeFailure?.call('$lookup $adb', error);
    }
    return null;
  }

  Future<bool> _safeFileExists(String path) async {
    try {
      return await fileExists(path);
    } on Exception catch (error) {
      onProbeFailure?.call('stat $path', error);
      return false;
    }
  }

  Future<bool> _isRunnable(String executable) async {
    try {
      final result = await executor.run(executable, [versionArgument]);
      return result.exitCode == 0;
    } on Exception catch (error) {
      onProbeFailure?.call('$executable $versionArgument', error);
      return false;
    }
  }
}
