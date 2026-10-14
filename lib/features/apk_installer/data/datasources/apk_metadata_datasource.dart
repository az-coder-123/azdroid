import 'dart:io';
import 'dart:typed_data';

import 'package:wifi_desk/core/constants/apk_installer_constants.dart';
import 'package:wifi_desk/core/services/app_logger.dart';
import 'package:wifi_desk/core/services/process_executor.dart';
import 'package:wifi_desk/features/apk_installer/domain/entities/apk_info_entity.dart';

/// Contract for extracting metadata from local APK files.
abstract class ApkMetadataDatasource {
  Future<ApkInfoEntity> inspectApk(String apkPath);
}

/// Concrete implementation utilizing Android build-tools `aapt` or macOS `unzip`.
class ApkMetadataDatasourceImpl implements ApkMetadataDatasource {
  ApkMetadataDatasourceImpl({
    ProcessExecutor processExecutor = const DefaultProcessExecutor(),
  }) : _executor = processExecutor;

  final ProcessExecutor _executor;
  String? _cachedAaptPath;

  @override
  Future<ApkInfoEntity> inspectApk(String apkPath) async {
    final file = File(apkPath);
    final fileName = apkPath.split('/').last;
    int sizeBytes = 0;
    try {
      if (file.existsSync()) {
        sizeBytes = file.lengthSync();
      }
    } catch (_) {}

    final aapt = await _resolveAaptPath();
    if (aapt == null) {
      return ApkInfoEntity(
        filePath: apkPath,
        fileName: fileName,
        fileSizeBytes: sizeBytes,
      );
    }

    try {
      final result = await _executor.run(
        aapt,
        ['dump', 'badging', apkPath],
        timeout: const Duration(
          seconds: ApkInstallerConstants.metadataTimeoutSeconds,
        ),
      );

      if (result.exitCode != 0) {
        return ApkInfoEntity(
          filePath: apkPath,
          fileName: fileName,
          fileSizeBytes: sizeBytes,
        );
      }

      final output = result.stdout.toString();
      return await _parseBadgingOutput(output, apkPath, fileName, sizeBytes);
    } catch (e, stack) {
      AppLogger.warning(
        'Failed to inspect APK badging: $e',
        error: e,
        stackTrace: stack,
      );
      return ApkInfoEntity(
        filePath: apkPath,
        fileName: fileName,
        fileSizeBytes: sizeBytes,
      );
    }
  }

  Future<ApkInfoEntity> _parseBadgingOutput(
    String output,
    String apkPath,
    String fileName,
    int sizeBytes,
  ) async {
    // 1. Package details
    String? packageName;
    int? versionCode;
    String? versionName;
    final pkgMatch = RegExp(
      r"package:\s*name='([^']+)'(?:\s+versionCode='([^']+)')?(?:\s+versionName='([^']+)')?",
    ).firstMatch(output);
    if (pkgMatch != null) {
      packageName = pkgMatch.group(1);
      versionCode = int.tryParse(pkgMatch.group(2) ?? '');
      versionName = pkgMatch.group(3);
    }

    // 2. Application label
    String? appName;
    final labelMatch =
        RegExp(r"application-label(?:-[a-zA-Z_-]+)?:\s*'([^']+)'")
            .firstMatch(output) ??
        RegExp(r"application:\s*label='([^']+)'").firstMatch(output);
    if (labelMatch != null) {
      appName = labelMatch.group(1);
    }

    // 3. SDK versions
    int? minSdkVersion;
    final minSdkMatch = RegExp(r"sdkVersion:\s*'(\d+)'").firstMatch(output);
    if (minSdkMatch != null) {
      minSdkVersion = int.tryParse(minSdkMatch.group(1) ?? '');
    }

    int? targetSdkVersion;
    final targetSdkMatch = RegExp(r"targetSdkVersion:\s*'(\d+)'")
        .firstMatch(output);
    if (targetSdkMatch != null) {
      targetSdkVersion = int.tryParse(targetSdkMatch.group(1) ?? '');
    }

    // 4. Extract App Icon if possible
    Uint8List? iconBytes;
    final iconMatch =
        RegExp(r"application-icon-(?:640|480|320|240|160):\s*'([^']+)'")
            .firstMatch(output) ??
        RegExp(r"application:\s*[^']*icon='([^']+)'").firstMatch(output);
    final iconPath = iconMatch?.group(1);

    if (iconPath != null && iconPath.isNotEmpty && !iconPath.endsWith('.xml')) {
      iconBytes = await _extractIconBytes(apkPath, iconPath);
    }

    return ApkInfoEntity(
      filePath: apkPath,
      fileName: fileName,
      fileSizeBytes: sizeBytes,
      packageName: packageName,
      versionName: versionName,
      versionCode: versionCode,
      appName: appName,
      minSdkVersion: minSdkVersion,
      targetSdkVersion: targetSdkVersion,
      iconBytes: iconBytes,
    );
  }

  Future<Uint8List?> _extractIconBytes(
    String apkPath,
    String iconInternalPath,
  ) async {
    try {
      final res = await _executor.run('/usr/bin/unzip', [
        '-p',
        apkPath,
        iconInternalPath,
      ], timeout: const Duration(seconds: 4));
      if (res.exitCode == 0 && res.stdout is List<int>) {
        return Uint8List.fromList(res.stdout as List<int>);
      }
    } catch (_) {}
    return null;
  }

  Future<String?> _resolveAaptPath() async {
    if (_cachedAaptPath != null) return _cachedAaptPath;

    // Check which aapt / aapt2
    for (final bin in ApkInstallerConstants.aaptBinaryNames) {
      try {
        final which = await _executor.run('/usr/bin/which', [bin]);
        final p = which.stdout.toString().trim();
        if (which.exitCode == 0 && p.isNotEmpty) {
          _cachedAaptPath = p;
          return p;
        }
      } catch (_) {}
    }

    // Search ~/Library/Android/sdk/build-tools/
    final home = Platform.environment['HOME'];
    if (home != null) {
      final buildToolsDir = Directory(
        '$home/${ApkInstallerConstants.androidSdkBuildToolsSubpath}',
      );
      if (buildToolsDir.existsSync()) {
        try {
          final entries =
              buildToolsDir.listSync().whereType<Directory>().toList()
                ..sort((a, b) => b.path.compareTo(a.path)); // Latest first
          for (final dir in entries) {
            for (final bin in ApkInstallerConstants.aaptBinaryNames) {
              final candidate = '${dir.path}/$bin';
              if (File(candidate).existsSync()) {
                _cachedAaptPath = candidate;
                return candidate;
              }
            }
          }
        } catch (_) {}
      }
    }

    return null;
  }
}
