import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wifi_desk/core/services/adb_service.dart';
import 'package:wifi_desk/core/services/process_executor.dart';
import 'package:wifi_desk/features/streaming/data/datasources/scrcpy_server_manager.dart';

class MockProcessExecutor extends Mock implements ProcessExecutor {}

void main() {
  late MockProcessExecutor mockExecutor;
  late AdbService adbService;
  late ScrcpyServerManager serverManager;

  setUp(() {
    mockExecutor = MockProcessExecutor();
    adbService = AdbService(
      processExecutor: mockExecutor,
      explicitAdbPath: '/usr/local/bin/adb',
    );
    serverManager = ScrcpyServerManager(
      adbService: adbService,
      processExecutor: mockExecutor,
    );
  });

  group('ScrcpyServerManager', () {
    const testSerial = '192.168.1.100:5555';

    test('setupPortForward runs adb forward command', () async {
      when(
        () => mockExecutor.run('/usr/local/bin/adb', [
          '-s',
          testSerial,
          'forward',
          'tcp:27183',
          'localabstract:scrcpy_00000000',
        ], timeout: any(named: 'timeout')),
      ).thenAnswer((_) async => ProcessResult(1, 0, '', ''));

      final success = await serverManager.setupPortForward(
        deviceSerial: testSerial,
        localPort: 27183,
      );

      expect(success, isTrue);
    });

    test('removePortForward executes forward --remove', () async {
      when(
        () => mockExecutor.run('/usr/local/bin/adb', [
          '-s',
          testSerial,
          'forward',
          '--remove',
          'tcp:27183',
        ], timeout: any(named: 'timeout')),
      ).thenAnswer((_) async => ProcessResult(1, 0, '', ''));

      final success = await serverManager.removePortForward(
        deviceSerial: testSerial,
        localPort: 27183,
      );

      expect(success, isTrue);
    });

    test('sendKeyevent dispatches input keyevent via adb shell', () async {
      when(
        () => mockExecutor.run('/usr/local/bin/adb', [
          '-s',
          testSerial,
          'shell',
          'input',
          'keyevent',
          '4',
        ], timeout: any(named: 'timeout')),
      ).thenAnswer((_) async => ProcessResult(1, 0, '', ''));

      final success = await serverManager.sendKeyevent(
        deviceSerial: testSerial,
        keyCode: 4,
      );

      expect(success, isTrue);
    });
  });
}
