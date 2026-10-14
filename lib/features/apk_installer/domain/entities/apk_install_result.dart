import 'package:equatable/equatable.dart';

/// Result and diagnostic analysis of an APK installation attempt.
class ApkInstallResult extends Equatable {
  const ApkInstallResult({
    required this.success,
    required this.rawOutput,
    this.packageName,
    this.errorCode,
    this.errorTitle,
    this.errorDescription,
    this.suggestedAction,
  });

  final bool success;
  final String rawOutput;
  final String? packageName;
  final String? errorCode;
  final String? errorTitle;
  final String? errorDescription;
  final String? suggestedAction;

  /// Parses ADB process output to construct a rich [ApkInstallResult].
  factory ApkInstallResult.fromAdbOutput(
    String output, {
    String? packageName,
    int exitCode = 0,
  }) {
    final lower = output.toLowerCase();
    final isSuccess =
        exitCode == 0 &&
        (lower.contains('success') || !lower.contains('failure'));

    if (isSuccess && !lower.contains('failure [')) {
      return ApkInstallResult(
        success: true,
        rawOutput: output,
        packageName: packageName,
      );
    }

    // Extract failure code, e.g. "Failure [INSTALL_FAILED_UPDATE_INCOMPATIBLE]"
    final match = RegExp(r'Failure\s*\[([A-Z0-9_]+)(?::\s*([^\]]+))?\]')
        .firstMatch(output);
    final code = match?.group(1);
    final detail = match?.group(2)?.trim();

    final diagnosis = _diagnoseErrorCode(code, detail);

    return ApkInstallResult(
      success: false,
      rawOutput: output,
      packageName: packageName,
      errorCode:
          code ??
          (exitCode != 0 ? 'EXIT_CODE_$exitCode' : 'INSTALL_UNKNOWN_ERROR'),
      errorTitle: diagnosis.title,
      errorDescription: diagnosis.description,
      suggestedAction: diagnosis.action,
    );
  }

  static _Diagnosis _diagnoseErrorCode(String? code, String? detail) {
    switch (code) {
      case 'INSTALL_FAILED_UPDATE_INCOMPATIBLE':
        return const _Diagnosis(
          title: 'Signature Key Mismatch',
          description: 'The app is already installed on this device with a different signing key (e.g. Play Store build vs Debug build).',
          action: 'Uninstall the existing version from the device first, then reinstall.',
        );
      case 'INSTALL_FAILED_VERSION_DOWNGRADE':
        return const _Diagnosis(
          title: 'Version Downgrade Blocked',
          description: 'The version you are installing is older than the version currently installed on the device.',
          action: 'Enable "Allow Version Downgrade (-d)" in options or uninstall the existing app first.',
        );
      case 'INSTALL_FAILED_TEST_ONLY':
        return const _Diagnosis(
          title: 'Test-Only Build Restricted',
          description: 'This APK is marked with android:testOnly="true" (common for IDE debug builds).',
          action: 'Enable "Allow Test Packages (-t)" in options.',
        );
      case 'INSTALL_FAILED_INSUFFICIENT_STORAGE':
        return const _Diagnosis(
          title: 'Insufficient Device Storage',
          description: 'The Android device does not have enough free space to install this application.',
          action: 'Free up internal storage space on your device and retry.',
        );
      case 'INSTALL_FAILED_USER_RESTRICTED':
        return const _Diagnosis(
          title: 'Blocked by Device Security / OEM',
          description: 'Installation was blocked by device policy (e.g. Xiaomi MIUI "Install via USB" setting or missing user confirmation).',
          action: 'Check your phone screen for an install confirmation prompt, or enable "Install via USB" in Developer Options.',
        );
      case 'INSTALL_FAILED_NO_MATCHING_ABIS':
        return const _Diagnosis(
          title: 'CPU Architecture Incompatible',
          description: 'This APK contains native code (.so) that is incompatible with your device CPU architecture.',
          action: 'Obtain an APK compiled for your device CPU architecture (e.g. arm64-v8a).',
        );
      case 'INSTALL_FAILED_ALREADY_EXISTS':
        return const _Diagnosis(
          title: 'Package Already Exists',
          description: 'An existing package conflict occurred.',
          action: 'Ensure "Reinstall / Replace (-r)" is enabled in options.',
        );
      case 'INSTALL_PARSE_FAILED_NOT_APK':
        return const _Diagnosis(
          title: 'Invalid APK Package',
          description:
              'The selected file is not a valid Android package archive.',
          action: 'Verify that the file is not damaged or corrupted.',
        );
      default:
        final msg = detail != null && detail.isNotEmpty
            ? detail
            : 'Android Package Manager rejected the install.';
        return _Diagnosis(
          title: 'Installation Failed',
          description: msg,
          action: 'Review device screen for security prompts or check developer options.',
        );
    }
  }

  @override
  List<Object?> get props => [
    success,
    rawOutput,
    packageName,
    errorCode,
    errorTitle,
    errorDescription,
    suggestedAction,
  ];
}

class _Diagnosis {
  const _Diagnosis({
    required this.title,
    required this.description,
    required this.action,
  });

  final String title;
  final String description;
  final String action;
}
