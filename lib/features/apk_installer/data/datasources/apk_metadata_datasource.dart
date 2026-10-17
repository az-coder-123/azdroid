import 'dart:io';
import 'dart:typed_data';

import 'package:desk_droid/core/constants/apk_installer_constants.dart';
import 'package:desk_droid/core/services/app_logger.dart';
import 'package:desk_droid/core/services/process_executor.dart';
import 'package:desk_droid/features/apk_installer/data/services/aapt_path_resolver.dart';
import 'package:desk_droid/features/apk_installer/data/services/apk_entry_reader.dart';
import 'package:desk_droid/features/apk_installer/domain/entities/apk_info_entity.dart';
import 'package:path/path.dart' as p;

/// Contract for extracting metadata from local APK files.
abstract class ApkMetadataDatasource {
  Future<ApkInfoEntity> inspectApk(String apkPath);
}

/// Concrete implementation utilizing Android build-tools `aapt` or macOS `unzip`.
class ApkMetadataDatasourceImpl implements ApkMetadataDatasource {
  ApkMetadataDatasourceImpl({
    ProcessExecutor processExecutor = const DefaultProcessExecutor(),
    AaptPathResolver? aaptResolver,
    this._entryReader = const ZipApkEntryReader(),
  }) : _executor = processExecutor,
       _aaptResolver =
           aaptResolver ?? AaptPathResolver(processExecutor: processExecutor);

  final ProcessExecutor _executor;
  final AaptPathResolver _aaptResolver;
  final ApkEntryReader _entryReader;

  @override
  Future<ApkInfoEntity> inspectApk(String apkPath) async {
    final file = File(apkPath);
    final fileName = p.basename(apkPath);
    final sizeBytes = _readFileSize(file);

    final aapt = await _aaptResolver.resolve();
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

  int _readFileSize(File file) {
    try {
      return file.existsSync() ? file.lengthSync() : 0;
    } on FileSystemException catch (error) {
      AppLogger.warning('Failed to read APK file size.', error: error);
      return 0;
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
  ) => _entryReader.readEntry(apkPath, iconInternalPath);
}
