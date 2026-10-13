import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wifi_desk/core/services/adb_service.dart';
import 'package:wifi_desk/core/services/adb_tcpip_service.dart';
import 'package:wifi_desk/features/discovery/data/datasources/device_discovery_datasource.dart';
import 'package:wifi_desk/features/discovery/domain/entities/device_entity.dart';

class MockAdbService extends Mock implements AdbService {}

class MockAdbTcpipService extends Mock implements AdbTcpipService {}

void main() {
  late MockAdbService mockAdbService;
  late MockAdbTcpipService mockTcpipService;
  late DeviceDiscoveryDatasourceImpl datasource;

  setUp(() {
    mockAdbService = MockAdbService();
    mockTcpipService = MockAdbTcpipService();
    datasource = DeviceDiscoveryDatasourceImpl(
      adbService: mockAdbService,
      adbTcpipService: mockTcpipService,
    );

    when(() => mockAdbService.getMdnsServices()).thenAnswer((_) async => []);
  });

  group('DeviceDiscoveryDatasourceImpl.scanDevices', () {
    test('merges USB and Wi-Fi endpoints of the same physical device into 1 dual-mode model', () async {
      const usbAdbDevice = AdbDevice(
        serial: '9789f2350404',
        state: 'device',
        product: 'lancelot_global',
        model: 'M2004J19C',
        device: 'lancelot',
      );

      const wifiAdbDevice = AdbDevice(
        serial: '192.168.1.3:5555',
        state: 'device',
        product: 'lancelot_global',
        model: 'M2004J19C',
        device: 'lancelot',
      );

      when(() => mockAdbService.getAttachedDevices())
          .thenAnswer((_) async => [usbAdbDevice, wifiAdbDevice]);

      when(() => mockTcpipService.getHardwareSerial('192.168.1.3:5555'))
          .thenAnswer((_) async => '9789f2350404');

      final devices = await datasource.scanDevices();

      // Exactly 1 deduplicated card instead of 2 redundant cards!
      expect(devices.length, equals(1));

      final device = devices.first;
      expect(device.isDualConnected, isTrue);
      expect(device.connectionType, equals(DeviceConnectionType.dual));
      expect(device.name, equals('M2004J19C'));
      expect(device.usbSerial, equals('9789f2350404'));
      expect(device.wirelessSerial, equals('192.168.1.3:5555'));
      expect(device.isConnected, isTrue);
    });

    test(
      'falls back to model and product match if ro.serialno query fails',
      () async {
        const usbAdbDevice = AdbDevice(
          serial: 'usb_fallback_123',
          state: 'device',
          product: 'pixel_tensor',
          model: 'Pixel 8',
        );

        const wifiAdbDevice = AdbDevice(
          serial: '192.168.1.50:5555',
          state: 'device',
          product: 'pixel_tensor',
          model: 'Pixel 8',
        );

        when(() => mockAdbService.getAttachedDevices())
            .thenAnswer((_) async => [usbAdbDevice, wifiAdbDevice]);

        when(() => mockTcpipService.getHardwareSerial('192.168.1.50:5555'))
            .thenAnswer((_) async => null);

        final devices = await datasource.scanDevices();

        expect(devices.length, equals(1));
        expect(devices.first.isDualConnected, isTrue);
        expect(devices.first.usbSerial, equals('usb_fallback_123'));
        expect(devices.first.wirelessSerial, equals('192.168.1.50:5555'));
      },
    );

    test('keeps distinct devices separate if they do not match', () async {
      const usbDevice = AdbDevice(
        serial: 'usb_phone_1',
        state: 'device',
        product: 'galaxy_s24',
        model: 'Galaxy S24',
      );

      const wifiDevice = AdbDevice(
        serial: '192.168.1.80:5555',
        state: 'device',
        product: 'pixel_8',
        model: 'Pixel 8',
      );

      when(() => mockAdbService.getAttachedDevices())
          .thenAnswer((_) async => [usbDevice, wifiDevice]);

      when(() => mockTcpipService.getHardwareSerial('192.168.1.80:5555'))
          .thenAnswer((_) async => 'different_hw_serial');

      final devices = await datasource.scanDevices();

      expect(devices.length, equals(2));
      expect(
        devices.any((d) => d.connectionType == DeviceConnectionType.usb),
        isTrue,
      );
      expect(
        devices.any((d) => d.connectionType == DeviceConnectionType.wireless),
        isTrue,
      );
      expect(devices.any((d) => d.isDualConnected), isFalse);
    });
  });
}
