import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wifi_desk/core/services/adb_service.dart';
import 'package:wifi_desk/core/services/process_executor.dart';
import 'package:wifi_desk/features/apk_installer/data/datasources/apk_installer_datasource.dart';
import 'package:wifi_desk/features/apk_installer/domain/entities/apk_install_options.dart';

class MockProcessExecutor extends Mock implements ProcessExecutor {}

class MockAdbService extends Mock implements AdbService {}

void main() {
  late MockProcessExecutor mockExecutor;
  late MockAdbService mockAdbService;
  late ApkInstallerDatasourceImpl datasource;

  setUp(() {
    mockExecutor = MockProcessExecutor();
    mockAdbService = MockAdbService();
    datasource = ApkInstallerDatasourceImpl(
      adbService: mockAdbService,
      processExecutor: mockExecutor,
    );
  });

  group('ApkInstallerDatasourceImpl', () {
    test(
      'installApk invokes adb install with correct options and returns success',
      () async {
        when(() => mockAdbService.resolveAdbPath())
            .thenAnswer((_) async => '/mock/adb');
        when(
          () => mockExecutor.run(
            '/mock/adb',
            any(),
            timeout: any(named: 'timeout'),
          ),
        ).thenAnswer(
          (_) async =>
              ProcessResult(0, 0, 'Performing Streamed Install\nSuccess', ''),
        );

        final result = await datasource.installApk(
          'device-123',
          '/local/app.apk',
          const ApkInstallOptions(allowDowngrade: false),
          packageName: 'com.example.app',
        );

        expect(result.success, isTrue);
        expect(result.packageName, equals('com.example.app'));
        verify(
          () => mockExecutor.run('/mock/adb', [
            '-s',
            'device-123',
            'install',
            '-r',
            '-g',
            '-t',
            '/local/app.apk',
          ], timeout: any(named: 'timeout')),
        ).called(1);
      },
    );

    test('launchApp invokes monkey launcher intent', () async {
      when(() => mockAdbService.resolveAdbPath())
          .thenAnswer((_) async => '/mock/adb');
      when(
        () => mockExecutor.run(
          '/mock/adb',
          any(),
          timeout: any(named: 'timeout'),
        ),
      ).thenAnswer((_) async => ProcessResult(0, 0, 'Events injected: 1', ''));

      final ok = await datasource.launchApp('device-123', 'com.example.app');

      expect(ok, isTrue);
      verify(
        () => mockExecutor.run('/mock/adb', [
          '-s',
          'device-123',
          'shell',
          'monkey',
          '-p',
          'com.example.app',
          '-c',
          'android.intent.category.LAUNCHER',
          '1',
        ], timeout: any(named: 'timeout')),
      ).called(1);
    });

    test('uninstallApp invokes adb uninstall', () async {
      when(() => mockAdbService.resolveAdbPath())
          .thenAnswer((_) async => '/mock/adb');
      when(
        () => mockExecutor.run(
          '/mock/adb',
          any(),
          timeout: any(named: 'timeout'),
        ),
      ).thenAnswer((_) async => ProcessResult(0, 0, 'Success', ''));

      final ok = await datasource.uninstallApp('device-123', 'com.example.app');

      expect(ok, isTrue);
      verify(
        () => mockExecutor.run('/mock/adb', [
          '-s',
          'device-123',
          'uninstall',
          'com.example.app',
        ], timeout: any(named: 'timeout')),
      ).called(1);
    });
  });
}
