import 'dart:io';

import 'package:desk_droid/core/services/adb_service.dart';
import 'package:desk_droid/core/services/adb_tcpip_service.dart';
import 'package:desk_droid/core/services/process_executor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAdbService extends Mock implements AdbService {}

class MockProcessExecutor extends Mock implements ProcessExecutor {}

void main() {
  late MockAdbService mockAdbService;
  late MockProcessExecutor mockExecutor;
  late AdbTcpipService tcpipService;

  setUp(() {
    mockAdbService = MockAdbService();
    mockExecutor = MockProcessExecutor();
    tcpipService = AdbTcpipService(
      adbService: mockAdbService,
      processExecutor: mockExecutor,
    );

    when(() => mockAdbService.resolveAdbPath())
        .thenAnswer((_) async => '/mock/adb');
  });

  group('AdbTcpipService', () {
    test(
      'getDeviceWifiIp parses IP correctly from ip -f inet addr show wlan0',
      () async {
        const sampleAddrOutput = '''
30: wlan0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 3000
    inet 192.168.1.88/24 brd 192.168.1.255 scope global wlan0
       valid_lft forever preferred_lft forever
''';

        when(
          () => mockExecutor.run('/mock/adb', [
            '-s',
            'usb123',
            'shell',
            'ip',
            '-f',
            'inet',
            'addr',
            'show',
            'wlan0',
          ], timeout: any(named: 'timeout')),
        ).thenAnswer((_) async => ProcessResult(0, 0, sampleAddrOutput, ''));

        final ip = await tcpipService.getDeviceWifiIp('usb123');
        expect(ip, equals('192.168.1.88'));
      },
    );

    test('getDeviceWifiIp falls back to ip route when wlan0 fails', () async {
      const sampleRouteOutput = '''
192.168.0.0/24 dev wlan0 proto kernel scope link src 192.168.0.125
default via 192.168.0.1 dev wlan0
''';

      when(
        () => mockExecutor.run('/mock/adb', [
          '-s',
          'usb123',
          'shell',
          'ip',
          '-f',
          'inet',
          'addr',
          'show',
          'wlan0',
        ], timeout: any(named: 'timeout')),
      ).thenAnswer((_) async => ProcessResult(0, 1, '', 'Device not found'));

      when(
        () => mockExecutor.run('/mock/adb', [
          '-s',
          'usb123',
          'shell',
          'ip',
          'route',
        ], timeout: any(named: 'timeout')),
      ).thenAnswer((_) async => ProcessResult(0, 0, sampleRouteOutput, ''));

      final ip = await tcpipService.getDeviceWifiIp('usb123');
      expect(ip, equals('192.168.0.125'));
    });

    test('enableTcpip runs adb tcpip with given port', () async {
      when(
        () => mockExecutor.run('/mock/adb', [
          '-s',
          'usb123',
          'tcpip',
          '5555',
        ], timeout: any(named: 'timeout')),
      ).thenAnswer(
        (_) async =>
            ProcessResult(0, 0, 'restarting in TCP mode port: 5555\n', ''),
      );

      final result = await tcpipService.enableTcpip('usb123', port: 5555);
      expect(result.isSuccess, isTrue);
    });

    test('switchUsbToWifi succeeds when IP found, tcpip enabled, and connect called', () async {
      const sampleAddr = '    inet 192.168.1.99/24 scope global wlan0\n';

      when(
        () => mockExecutor.run('/mock/adb', [
          '-s',
          'usb123',
          'shell',
          'ip',
          '-f',
          'inet',
          'addr',
          'show',
          'wlan0',
        ], timeout: any(named: 'timeout')),
      ).thenAnswer((_) async => ProcessResult(0, 0, sampleAddr, ''));

      when(
        () => mockExecutor.run('/mock/adb', [
          '-s',
          'usb123',
          'tcpip',
          '5555',
        ], timeout: any(named: 'timeout')),
      ).thenAnswer(
        (_) async =>
            ProcessResult(0, 0, 'restarting in TCP mode port: 5555', ''),
      );

      when(() => mockAdbService.connect('192.168.1.99', 5555)).thenAnswer(
        (_) async => const AdbCommandResult(
          isSuccess: true,
          message: 'connected to 192.168.1.99:5555',
        ),
      );

      final result = await tcpipService.switchUsbToWifi('usb123', port: 5555);
      expect(result.isSuccess, isTrue);
      expect(result.message, contains('192.168.1.99'));
    });

    test('getHardwareSerial returns ro.serialno when query succeeds', () async {
      when(
        () => mockExecutor.run('/mock/adb', [
          '-s',
          '192.168.1.50:5555',
          'shell',
          'getprop',
          'ro.serialno',
        ], timeout: any(named: 'timeout')),
      ).thenAnswer((_) async => ProcessResult(0, 0, 'hw_serial_999\n', ''));

      final serial = await tcpipService.getHardwareSerial('192.168.1.50:5555');
      expect(serial, equals('hw_serial_999'));
    });
  });
}
