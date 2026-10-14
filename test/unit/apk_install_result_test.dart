import 'package:flutter_test/flutter_test.dart';
import 'package:wifi_desk/features/apk_installer/domain/entities/apk_install_options.dart';
import 'package:wifi_desk/features/apk_installer/domain/entities/apk_install_result.dart';

void main() {
  group('ApkInstallResult', () {
    test('constructs success result when stdout contains Success', () {
      const output = 'Performing Streamed Install\nSuccess';
      final result = ApkInstallResult.fromAdbOutput(
        output,
        packageName: 'com.example.app',
      );

      expect(result.success, isTrue);
      expect(result.packageName, equals('com.example.app'));
      expect(result.errorCode, isNull);
    });

    test('diagnoses INSTALL_FAILED_UPDATE_INCOMPATIBLE signature mismatch', () {
      const output =
          'Performing Streamed Install\nFailure [INSTALL_FAILED_UPDATE_INCOMPATIBLE: Package com.example signatures do not match previously installed version; ignoring!]';
      final result = ApkInstallResult.fromAdbOutput(
        output,
        packageName: 'com.example',
      );

      expect(result.success, isFalse);
      expect(result.errorCode, equals('INSTALL_FAILED_UPDATE_INCOMPATIBLE'));
      expect(result.errorTitle, equals('Signature Key Mismatch'));
      expect(result.suggestedAction, contains('Uninstall'));
    });

    test('diagnoses INSTALL_FAILED_VERSION_DOWNGRADE', () {
      const output =
          'Failure [INSTALL_FAILED_VERSION_DOWNGRADE: Package version code 10 is less than currently installed 20]';
      final result = ApkInstallResult.fromAdbOutput(output);

      expect(result.success, isFalse);
      expect(result.errorCode, equals('INSTALL_FAILED_VERSION_DOWNGRADE'));
      expect(result.errorTitle, equals('Version Downgrade Blocked'));
      expect(result.suggestedAction, contains('-d'));
    });

    test('diagnoses INSTALL_FAILED_USER_RESTRICTED for OEM/MIUI security', () {
      const output =
          'Failure [INSTALL_FAILED_USER_RESTRICTED: Install canceled by user]';
      final result = ApkInstallResult.fromAdbOutput(output);

      expect(result.success, isFalse);
      expect(result.errorCode, equals('INSTALL_FAILED_USER_RESTRICTED'));
      expect(result.errorTitle, contains('Security'));
      expect(result.suggestedAction, contains('Install via USB'));
    });

    test('diagnoses INSTALL_FAILED_TEST_ONLY for debug builds', () {
      const output =
          'Failure [INSTALL_FAILED_TEST_ONLY: install -t is required]';
      final result = ApkInstallResult.fromAdbOutput(output);

      expect(result.success, isFalse);
      expect(result.errorCode, equals('INSTALL_FAILED_TEST_ONLY'));
      expect(result.suggestedAction, contains('-t'));
    });
  });

  group('ApkInstallOptions', () {
    test('produces default flags -r, -g, -t', () {
      const options = ApkInstallOptions();
      expect(options.toCliArgs(), equals(['-r', '-g', '-t']));
    });

    test('includes -d flag when allowDowngrade is enabled', () {
      const options = ApkInstallOptions(allowDowngrade: true);
      expect(options.toCliArgs(), equals(['-r', '-g', '-d', '-t']));
    });
  });
}
