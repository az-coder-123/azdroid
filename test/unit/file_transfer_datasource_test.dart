import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:desk_droid/core/services/adb_service.dart';
import 'package:desk_droid/core/services/process_executor.dart';
import 'package:desk_droid/features/productivity/data/datasources/file_transfer_datasource.dart';

class MockProcessExecutor extends Mock implements ProcessExecutor {}

class MockAdbService extends Mock implements AdbService {}

void main() {
  late MockProcessExecutor mockExecutor;
  late MockAdbService mockAdbService;
  late FileTransferDatasourceImpl datasource;

  const testSerial = '192.168.1.100:5555';

  setUp(() {
    mockExecutor = MockProcessExecutor();
    mockAdbService = MockAdbService();
    datasource = FileTransferDatasourceImpl(
      adbService: mockAdbService,
      processExecutor: mockExecutor,
    );

    when(() => mockAdbService.resolveAdbPath())
        .thenAnswer((_) async => '/opt/homebrew/bin/adb');
  });

  group('FileTransferDatasourceImpl', () {
    test('pushFile executes adb push command', () async {
      when(
        () => mockExecutor.run('/opt/homebrew/bin/adb', [
          '-s',
          testSerial,
          'push',
          '/path/to/photo.jpg',
          '/sdcard/Download/',
        ], timeout: any(named: 'timeout')),
      ).thenAnswer((_) async => ProcessResult(1, 0, '1 file pushed', ''));

      final result = await datasource.pushFile(
        testSerial,
        '/path/to/photo.jpg',
        '/sdcard/Download/',
      );

      expect(result, isTrue);
      verify(
        () => mockExecutor.run('/opt/homebrew/bin/adb', [
          '-s',
          testSerial,
          'push',
          '/path/to/photo.jpg',
          '/sdcard/Download/',
        ], timeout: any(named: 'timeout')),
      ).called(1);
    });

    test('installApk executes adb install -r command', () async {
      when(
        () => mockExecutor.run('/opt/homebrew/bin/adb', [
          '-s',
          testSerial,
          'install',
          '-r',
          '/path/to/app.apk',
        ], timeout: any(named: 'timeout')),
      ).thenAnswer((_) async => ProcessResult(1, 0, 'Success', ''));

      final result = await datasource.installApk(
        testSerial,
        '/path/to/app.apk',
      );

      expect(result, isTrue);
      verify(
        () => mockExecutor.run('/opt/homebrew/bin/adb', [
          '-s',
          testSerial,
          'install',
          '-r',
          '/path/to/app.apk',
        ], timeout: any(named: 'timeout')),
      ).called(1);
    });

    test('getExternalStorageDirectory returns physical SD card path', () async {
      when(
        () => mockExecutor.run('/opt/homebrew/bin/adb', [
          '-s',
          testSerial,
          'shell',
          'ls',
          '-d',
          '/storage/*',
        ], timeout: any(named: 'timeout')),
      ).thenAnswer(
        (_) async => ProcessResult(
          1,
          0,
          '/storage/emulated\n/storage/self\n/storage/3662-FF26\n',
          '',
        ),
      );

      final result = await datasource.getExternalStorageDirectory(testSerial);

      expect(result, equals('/storage/3662-FF26/'));
    });
  });
}
