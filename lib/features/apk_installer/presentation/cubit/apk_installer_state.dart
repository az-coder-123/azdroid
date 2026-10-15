import 'package:equatable/equatable.dart';
import 'package:desk_droid/features/apk_installer/domain/entities/apk_info_entity.dart';
import 'package:desk_droid/features/apk_installer/domain/entities/apk_install_options.dart';
import 'package:desk_droid/features/apk_installer/domain/entities/apk_install_result.dart';

/// Base state for APK installation lifecycle.
abstract class ApkInstallerState extends Equatable {
  const ApkInstallerState({required this.deviceSerial});

  final String deviceSerial;

  @override
  List<Object?> get props => [deviceSerial];
}

/// Initial idle state where user chooses an APK file or drops one.
class ApkInstallerInitial extends ApkInstallerState {
  const ApkInstallerInitial({required super.deviceSerial});
}

/// Parsing and extracting APK metadata.
class ApkInstallerInspecting extends ApkInstallerState {
  const ApkInstallerInspecting({
    required super.deviceSerial,
    required this.filePath,
  });

  final String filePath;

  @override
  List<Object?> get props => [deviceSerial, filePath];
}

/// APK is inspected and ready for installation.
class ApkInstallerReady extends ApkInstallerState {
  const ApkInstallerReady({
    required super.deviceSerial,
    required this.apkInfo,
    this.options = const ApkInstallOptions(),
  });

  final ApkInfoEntity apkInfo;
  final ApkInstallOptions options;

  @override
  List<Object?> get props => [deviceSerial, apkInfo, options];
}

/// Active installation streaming or verifying on device.
class ApkInstallerInstalling extends ApkInstallerState {
  const ApkInstallerInstalling({
    required super.deviceSerial,
    required this.apkInfo,
    required this.options,
    this.statusMessage = 'Streaming package to device and installing...',
  });

  final ApkInfoEntity apkInfo;
  final ApkInstallOptions options;
  final String statusMessage;

  @override
  List<Object?> get props => [deviceSerial, apkInfo, options, statusMessage];
}

/// Installation completed successfully.
class ApkInstallerSuccess extends ApkInstallerState {
  const ApkInstallerSuccess({
    required super.deviceSerial,
    required this.apkInfo,
    required this.result,
    this.appLaunched = false,
  });

  final ApkInfoEntity apkInfo;
  final ApkInstallResult result;
  final bool appLaunched;

  @override
  List<Object?> get props => [deviceSerial, apkInfo, result, appLaunched];
}

/// Installation failed with diagnostic details.
class ApkInstallerFailure extends ApkInstallerState {
  const ApkInstallerFailure({
    required super.deviceSerial,
    required this.apkInfo,
    required this.options,
    required this.result,
    this.isUninstallingOld = false,
  });

  final ApkInfoEntity apkInfo;
  final ApkInstallOptions options;
  final ApkInstallResult result;
  final bool isUninstallingOld;

  @override
  List<Object?> get props => [
    deviceSerial,
    apkInfo,
    options,
    result,
    isUninstallingOld,
  ];
}
