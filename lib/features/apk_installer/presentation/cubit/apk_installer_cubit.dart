import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wifi_desk/features/apk_installer/domain/entities/apk_install_options.dart';
import 'package:wifi_desk/features/apk_installer/domain/repositories/apk_installer_repository.dart';
import 'package:wifi_desk/features/apk_installer/presentation/cubit/apk_installer_state.dart';

/// Cubit managing APK package inspection, installation workflow, and remote launch.
class ApkInstallerCubit extends Cubit<ApkInstallerState> {
  ApkInstallerCubit({required this.repository, required String deviceSerial})
    : super(ApkInstallerInitial(deviceSerial: deviceSerial));

  final ApkInstallerRepository repository;

  /// Loads and inspects the specified APK file path.
  Future<void> selectApk(String filePath) async {
    final serial = state.deviceSerial;
    emit(ApkInstallerInspecting(deviceSerial: serial, filePath: filePath));

    try {
      final info = await repository.inspectApk(filePath);
      if (!isClosed) {
        emit(ApkInstallerReady(deviceSerial: serial, apkInfo: info));
      }
    } catch (_) {
      if (!isClosed) {
        emit(ApkInstallerInitial(deviceSerial: serial));
      }
    }
  }

  /// Updates install configuration flags (reinstall, permissions, downgrade, test).
  void updateOptions(ApkInstallOptions newOptions) {
    final current = state;
    if (current is ApkInstallerReady) {
      emit(
        ApkInstallerReady(
          deviceSerial: current.deviceSerial,
          apkInfo: current.apkInfo,
          options: newOptions,
        ),
      );
    } else if (current is ApkInstallerFailure) {
      emit(
        ApkInstallerReady(
          deviceSerial: current.deviceSerial,
          apkInfo: current.apkInfo,
          options: newOptions,
        ),
      );
    }
  }

  /// Executes the sideload and installation process on the Android device.
  Future<void> install() async {
    final current = state;
    final String serial = current.deviceSerial;
    final apkInfo = switch (current) {
      ApkInstallerReady s => s.apkInfo,
      ApkInstallerFailure s => s.apkInfo,
      _ => null,
    };
    final options = switch (current) {
      ApkInstallerReady s => s.options,
      ApkInstallerFailure s => s.options,
      _ => const ApkInstallOptions(),
    };

    if (apkInfo == null) return;

    emit(
      ApkInstallerInstalling(
        deviceSerial: serial,
        apkInfo: apkInfo,
        options: options,
        statusMessage: 'Streaming package to device and installing...',
      ),
    );

    final result = await repository.installApk(
      serial,
      apkInfo.filePath,
      options,
    );

    if (isClosed) return;

    if (result.success) {
      emit(
        ApkInstallerSuccess(
          deviceSerial: serial,
          apkInfo: apkInfo,
          result: result,
        ),
      );
    } else {
      emit(
        ApkInstallerFailure(
          deviceSerial: serial,
          apkInfo: apkInfo,
          options: options,
          result: result,
        ),
      );
    }
  }

  /// Launches the installed package's main launcher activity on the Android device.
  Future<void> launchApp() async {
    final current = state;
    if (current is! ApkInstallerSuccess) return;

    final pkg = current.apkInfo.packageName ?? current.result.packageName;
    if (pkg == null || pkg.isEmpty) return;

    final ok = await repository.launchApp(current.deviceSerial, pkg);
    if (!isClosed && ok) {
      emit(
        ApkInstallerSuccess(
          deviceSerial: current.deviceSerial,
          apkInfo: current.apkInfo,
          result: current.result,
          appLaunched: true,
        ),
      );
    }
  }

  /// Uninstalls existing conflicting package from device, then automatically retries installation.
  Future<void> uninstallAndRetry() async {
    final current = state;
    if (current is! ApkInstallerFailure) return;

    final pkg = current.apkInfo.packageName ?? current.result.packageName;
    if (pkg == null || pkg.isEmpty) return;

    emit(
      ApkInstallerFailure(
        deviceSerial: current.deviceSerial,
        apkInfo: current.apkInfo,
        options: current.options,
        result: current.result,
        isUninstallingOld: true,
      ),
    );

    await repository.uninstallApp(current.deviceSerial, pkg);

    if (!isClosed) {
      // Re-trigger install now that previous incompatible build is removed
      await install();
    }
  }

  /// Resets back to initial state to choose another APK.
  void reset() {
    emit(ApkInstallerInitial(deviceSerial: state.deviceSerial));
  }
}
