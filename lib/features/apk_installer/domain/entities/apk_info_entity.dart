import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// Entity encapsulating parsed metadata and properties of an Android APK file.
class ApkInfoEntity extends Equatable {
  const ApkInfoEntity({
    required this.filePath,
    required this.fileName,
    required this.fileSizeBytes,
    this.packageName,
    this.versionName,
    this.versionCode,
    this.appName,
    this.minSdkVersion,
    this.targetSdkVersion,
    this.iconBytes,
  });

  final String filePath;
  final String fileName;
  final int fileSizeBytes;
  final String? packageName;
  final String? versionName;
  final int? versionCode;
  final String? appName;
  final int? minSdkVersion;
  final int? targetSdkVersion;
  final Uint8List? iconBytes;

  /// Returns user-friendly app display title, falling back to file name.
  String get displayName =>
      appName?.trim().isNotEmpty == true ? appName! : fileName;

  /// Formatted file size string (e.g. "45.2 MB").
  String get formattedSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Formatted version string (e.g. "v1.2.3 (build 42)").
  String get versionDisplay {
    if (versionName != null && versionCode != null) {
      return 'v$versionName (build $versionCode)';
    }
    if (versionName != null) return 'v$versionName';
    if (versionCode != null) return 'Build $versionCode';
    return 'Unknown version';
  }

  /// Formatted SDK target info (e.g. "Target API 34 (Android 14)").
  String get sdkDisplay {
    if (targetSdkVersion == null) return 'SDK Universal';
    final androidName = _mapApiToAndroidVersion(targetSdkVersion!);
    return 'Target API $targetSdkVersion ($androidName)';
  }

  static String _mapApiToAndroidVersion(int api) {
    switch (api) {
      case 36:
        return 'Android 16';
      case 35:
        return 'Android 15';
      case 34:
        return 'Android 14';
      case 33:
        return 'Android 13';
      case 32:
      case 31:
        return 'Android 12';
      case 30:
        return 'Android 11';
      case 29:
        return 'Android 10';
      case 28:
        return 'Android 9';
      case 27:
      case 26:
        return 'Android 8';
      default:
        return api >= 21 ? 'Android 5+' : 'Legacy';
    }
  }

  @override
  List<Object?> get props => [
    filePath,
    fileName,
    fileSizeBytes,
    packageName,
    versionName,
    versionCode,
    appName,
    minSdkVersion,
    targetSdkVersion,
  ];
}
