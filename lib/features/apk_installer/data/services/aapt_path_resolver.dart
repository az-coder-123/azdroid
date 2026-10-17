import 'dart:io';

import 'package:desk_droid/core/constants/apk_installer_constants.dart';
import 'package:desk_droid/core/services/app_logger.dart';
import 'package:desk_droid/core/services/process_executor.dart';

/// Locates the Android Asset Packaging Tool (`aapt2` / `aapt`) on the host.
///
/// Resolution order: `PATH` lookup via `which`, then the newest version folder
/// inside the Android SDK `build-tools` directory. The result is cached.
class AaptPathResolver {
  AaptPathResolver({
    ProcessExecutor processExecutor = const DefaultProcessExecutor(),
    Map<String, String>? environment,
  }) : _executor = processExecutor,
       _environment = environment ?? Platform.environment;

  final ProcessExecutor _executor;
  final Map<String, String> _environment;
  String? _cachedPath;

  /// Returns the aapt executable path, or `null` when it is not installed.
  Future<String?> resolve() async {
    return _cachedPath ??= await _resolveFromPath() ?? _resolveFromSdk();
  }

  Future<String?> _resolveFromPath() async {
    for (final bin in ApkInstallerConstants.aaptBinaryNames) {
      try {
        final which = await _executor.run(ApkInstallerConstants.whichPath, [
          bin,
        ]);
        final path = which.stdout.toString().trim();
        if (which.exitCode == 0 && path.isNotEmpty) return path;
      } on Exception catch (error) {
        AppLogger.debug('aapt PATH probe for "$bin" failed: $error');
      }
    }
    return null;
  }

  String? _resolveFromSdk() {
    final home = _environment['HOME'];
    if (home == null) return null;

    final buildToolsDir = Directory(
      '$home/${ApkInstallerConstants.androidSdkBuildToolsSubpath}',
    );
    if (!buildToolsDir.existsSync()) return null;

    try {
      final versionDirs =
          buildToolsDir.listSync().whereType<Directory>().toList()..sort(
            (a, b) => compareVersionNames(
              b.path.split(Platform.pathSeparator).last,
              a.path.split(Platform.pathSeparator).last,
            ),
          );
      for (final dir in versionDirs) {
        for (final bin in ApkInstallerConstants.aaptBinaryNames) {
          final candidate = '${dir.path}/$bin';
          if (File(candidate).existsSync()) return candidate;
        }
      }
    } on FileSystemException catch (error) {
      AppLogger.warning(
        'Failed to scan Android SDK build-tools directory.',
        error: error,
      );
    }
    return null;
  }

  /// Compares dotted version names numerically (e.g. `9.0.0` < `34.0.0`).
  ///
  /// Non-numeric segments such as `-rc1` sort after their numeric prefix
  /// using plain string comparison, so ordering stays deterministic.
  static int compareVersionNames(String a, String b) {
    final aParts = a.split('.');
    final bParts = b.split('.');
    final length = aParts.length > bParts.length
        ? aParts.length
        : bParts.length;
    for (var i = 0; i < length; i++) {
      final aSeg = i < aParts.length ? aParts[i] : '0';
      final bSeg = i < bParts.length ? bParts[i] : '0';
      final aNum = int.tryParse(aSeg);
      final bNum = int.tryParse(bSeg);
      final cmp = (aNum != null && bNum != null)
          ? aNum.compareTo(bNum)
          : aSeg.compareTo(bSeg);
      if (cmp != 0) return cmp;
    }
    return 0;
  }
}
