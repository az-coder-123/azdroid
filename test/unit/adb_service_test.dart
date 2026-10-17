import 'dart:io';

import 'package:desk_droid/core/services/adb_service.dart';
import 'package:desk_droid/core/services/process_executor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProcessExecutor extends Mock implements ProcessExecutor {}

void main() {
  late MockProcessExecutor mockExecutor;
  late AdbService adbService;

  setUp(() {
    mockExecutor = MockProcessExecutor();
    adbService = AdbService(
      processExecutor: mockExecutor,
      explicitAdbPath: '/usr/local/bin/adb',
    );
  });

  group('AdbService - Parsing', () {
    test('parseDevicesOutput correctly parses USB, Wi-Fi, and unauthorized devices', () {
      const sampleStdout = '''
List of devices attached
192.168.1.100:5555     device product:raven model:Pixel_6_Pro device:raven transport_id:1
emulator-5554          device product:sdk_gphone64 model:sdk_gphone64 device:emulator transport_id:2
2A011FDH2000EK         unauthorized usb:337641472X product:redfin model:Pixel_5 device:redfin transport_id:3
''';

      final devices = adbService.parseDevicesOutput(sampleStdout);

      expect(devices.length, equals(3));

      // Device 1: Wi-Fi Pixel 6 Pro
      expect(devices[0].serial, equals('192.168.1.100:5555'));
      expect(devices[0].state, equals('device'));
      expect(devices[0].model, equals('Pixel 6 Pro'));
      expect(devices[0].isUsb, isFalse);
      expect(devices[0].isAuthorized, isTrue);

      // Device 2: Emulator
      expect(devices[1].serial, equals('emulator-5554'));
      expect(devices[1].isUsb, isTrue);
      expect(devices[1].isAuthorized, isTrue);

      // Device 3: Unauthorized USB Pixel 5
      expect(devices[2].serial, equals('2A011FDH2000EK'));
      expect(devices[2].isUsb, isTrue);
      expect(devices[2].isUnauthorized, isTrue);
      expect(devices[2].model, equals('Pixel 5'));
    });

    test(
      'parseMdnsServicesOutput correctly parses connect and pairing services',
      () {
        const sampleMdns = '''
List of discovered mdns services
adb-1234-abcd._adb-tls-connect._tcp.   192.168.1.50:41235
adb-1234-abcd._adb-tls-pairing._tcp.   192.168.1.50:37123
galaxy-s24._adb._tcp.                  192.168.1.75:5555
''';

        final services = adbService.parseMdnsServicesOutput(sampleMdns);

        expect(services.length, equals(3));

        // Connect service
        expect(services[0].serviceName, equals('adb-1234-abcd'));
        expect(services[0].isConnectService, isTrue);
        expect(services[0].isPairingService, isFalse);
        expect(services[0].ipAddress, equals('192.168.1.50'));
        expect(services[0].port, equals(41235));

        // Pairing service
        expect(services[1].serviceName, equals('adb-1234-abcd'));
        expect(services[1].isPairingService, isTrue);
        expect(services[1].ipAddress, equals('192.168.1.50'));
        expect(services[1].port, equals(37123));

        // Standard adb._tcp service
        expect(services[2].serviceName, equals('galaxy-s24'));
        expect(services[2].isConnectService, isTrue);
        expect(services[2].ipAddress, equals('192.168.1.75'));
        expect(services[2].port, equals(5555));
      },
    );
  });

  group('AdbService - Commands', () {
    test('connect returns success when stdout contains connected to', () async {
      when(
        () => mockExecutor.run('/usr/local/bin/adb', [
          'connect',
          '192.168.1.50:5555',
        ], timeout: any(named: 'timeout')),
      ).thenAnswer(
        (_) async => ProcessResult(1, 0, 'connected to 192.168.1.50:5555', ''),
      );

      final result = await adbService.connect('192.168.1.50', 5555);

      expect(result.isSuccess, isTrue);
      expect(result.message, contains('connected to 192.168.1.50:5555'));
    });

    test(
      'connect auto-heals on No route to host by recycling adb server',
      () async {
        var callCount = 0;
        when(
          () => mockExecutor.run('/usr/local/bin/adb', [
            'connect',
            '192.168.43.148:5555',
          ], timeout: any(named: 'timeout')),
        ).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) {
            return ProcessResult(
              1,
              0,
              "failed to connect to '192.168.43.148:5555': No route to host",
              '',
            );
          }
          return ProcessResult(1, 0, 'connected to 192.168.43.148:5555', '');
        });

        when(
          () => mockExecutor.run('/usr/local/bin/adb', [
            'kill-server',
          ], timeout: any(named: 'timeout')),
        ).thenAnswer((_) async => ProcessResult(1, 0, '', ''));

        final result = await adbService.connect('192.168.43.148', 5555);

        expect(result.isSuccess, isTrue);
        expect(result.message, contains('connected to 192.168.43.148:5555'));
        verify(
          () => mockExecutor.run('/usr/local/bin/adb', [
            'kill-server',
          ], timeout: any(named: 'timeout')),
        ).called(1);
      },
    );

    test(
      'pair returns success when stdout contains Successfully paired',
      () async {
        when(
          () => mockExecutor.run('/usr/local/bin/adb', [
            'pair',
            '192.168.1.50:37123',
            '123456',
          ], timeout: any(named: 'timeout')),
        ).thenAnswer(
          (_) async => ProcessResult(
            1,
            0,
            'Successfully paired to 192.168.1.50:37123 [guid=adb-1234]',
            '',
          ),
        );

        final result = await adbService.pair('192.168.1.50', 37123, '123456');

        expect(result.isSuccess, isTrue);
        expect(result.message, contains('Successfully paired'));
      },
    );

    test('pair returns failure when rejected', () async {
      when(
        () => mockExecutor.run('/usr/local/bin/adb', [
          'pair',
          '192.168.1.50:37123',
          '000000',
        ], timeout: any(named: 'timeout')),
      ).thenAnswer(
        (_) async => ProcessResult(
          1,
          1,
          'Failed: Wrong password or connection was dropped.',
          '',
        ),
      );

      final result = await adbService.pair('192.168.1.50', 37123, '000000');

      expect(result.isSuccess, isFalse);
      expect(result.message, contains('Failed: Wrong password'));
    });
  });
}
