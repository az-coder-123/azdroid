import 'dart:io';

import 'package:desk_droid/core/extensions/line_split_extension.dart';
import 'package:desk_droid/core/platform/host_toolchain.dart';
import 'package:desk_droid/core/services/app_logger.dart';
import 'package:desk_droid/core/services/process_executor.dart';
import 'package:path/path.dart' as p;

/// Locates the Android Asset Packaging Tool (`aapt2` / `aapt`) on the host.
///
/// Resolution order: `PATH` lookup, then the newest version folder inside each
/// Android SDK `build-tools` directory. OS-specific names and folders come
/// from [HostToolchain]. The result is cached.
class AaptPathResolver {
  AaptPathResolver({
    ProcessExecutor processExecutor = const DefaultProcessExecutor(),
    HostToolchain? toolchain,
  }) : _executor = processExecutor,
       _toolchain = toolchain ?? HostToolchain.current();

  final ProcessExecutor _executor;
  final HostToolchain _toolchain;
  String? _cachedPath;

  /// Returns the aapt executable path, or `null` when it is not installed.
  Future<String?> resolve() async {
    return _cachedPath ??= await _resolveFromPath() ?? _resolveFromSdk();
  }

  Future<String?> _resolveFromPath() async {
    for (final bin in _toolchain.aaptExecutables) {
      try {
        final result = await _executor.run(_toolchain.pathLookupCommand, [bin]);
        final lines = result.stdout.toString().splitLines();
        if (result.exitCode == 0 && lines.isNotEmpty) {
          final path = lines.first.trim();
          if (path.isNotEmpty) return path;
        }
      } on Exception catch (error) {
        AppLogger.debug('aapt PATH probe for "$bin" failed: $error');
      }
    }
    return null;
  }

  String? _resolveFromSdk() {
    for (final buildTools in _toolchain.buildToolsDirectories) {
      final found = _newestAaptIn(Directory(buildTools));
      if (found != null) return found;
    }
    return null;
  }

  String? _newestAaptIn(Directory buildToolsDir) {
    if (!buildToolsDir.existsSync()) return null;
    try {
      final versionDirs =
          buildToolsDir.listSync().whereType<Directory>().toList()..sort(
            (a, b) =>
                compareVersionNames(p.basename(b.path), p.basename(a.path)),
          );
      for (final dir in versionDirs) {
        for (final bin in _toolchain.aaptExecutables) {
          final candidate = p.join(dir.path, bin);
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
