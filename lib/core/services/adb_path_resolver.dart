import 'package:desk_droid/core/platform/host_toolchain.dart';
import 'package:desk_droid/core/services/adb_binary_locator.dart';
import 'package:desk_droid/core/services/app_logger.dart';
import 'package:desk_droid/core/services/process_executor.dart';

/// Resolves the local ADB executable path for the Flutter desktop app.
///
/// Delegates discovery to [AdbBinaryLocator] and routes probe failures to
/// [AppLogger] so no discovery error is swallowed silently.
class AdbPathResolver {
  AdbPathResolver({
    ProcessExecutor executor = const DefaultProcessExecutor(),
    this.explicitPath,
    HostToolchain? toolchain,
    AdbBinaryLocator? locator,
  }) : _locator =
           locator ??
           AdbBinaryLocator(
             toolchain: toolchain,
             executor: executor,
             onProbeFailure: _logProbe,
           );

  final String? explicitPath;
  final AdbBinaryLocator _locator;

  static void _logProbe(String probe, Object error) =>
      AppLogger.debug('ADB probe "$probe" failed: $error');

  /// Locates the active ADB executable path.
  Future<String?> resolve([String? cachedPath]) async {
    if (explicitPath != null) return explicitPath;
    if (cachedPath != null) return cachedPath;

    final path = await _locator.locate();
    if (path == null) {
      AppLogger.warning('Could not resolve ADB executable on system.');
    } else {
      final source = path == _locator.toolchain.bundledAdbPath
          ? 'bundled'
          : 'installed';
      AppLogger.info('Using $source ADB at $path');
    }
    return path;
  }
}
