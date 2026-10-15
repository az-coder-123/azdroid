import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wifi_desk/core/services/adb_service.dart';
import 'package:wifi_desk/core/services/adb_tcpip_service.dart';
import 'package:wifi_desk/features/discovery/data/services/usb_wifi_auto_handoff_service.dart';

class MockAdbTcpipService extends Mock implements AdbTcpipService {}

void main() {
  late MockAdbTcpipService mockTcpipService;
  late UsbWifiAutoHandoffServiceImpl handoffService;

  setUp(() {
    mockTcpipService = MockAdbTcpipService();
    handoffService = UsbWifiAutoHandoffServiceImpl(
      adbTcpipService: mockTcpipService,
    );
  });

  group('UsbWifiAutoHandoffServiceImpl', () {
    test('ignores non-USB devices and unauthorized devices', () async {
      final devices = [
        const AdbDevice(
          serial: '192.168.1.3:5555',
          state: 'device',
          model: 'Phone1',
        ),
        const AdbDevice(
          serial: 'USB_UNAUTH_1',
          state: 'unauthorized',
          model: 'Phone2',
        ),
      ];

      final provisioned = await handoffService.autoProvisionUsbDevices(devices);
      expect(provisioned, isFalse);
      verifyNever(() => mockTcpipService.switchUsbToWifi(any()));
    });

    test(
      'auto-provisions authorized USB device only once per attachment',
      () async {
        const usbDevice = AdbDevice(
          serial: 'USB_SERIAL_123',
          state: 'device',
          model: 'Moto G',
        );

        when(() => mockTcpipService.switchUsbToWifi('USB_SERIAL_123'))
            .thenAnswer(
              (_) async =>
                  const AdbCommandResult(isSuccess: true, message: 'ok'),
            );

        // First run: should provision
        final firstRun = await handoffService.autoProvisionUsbDevices([
          usbDevice,
        ]);
        expect(firstRun, isTrue);
        verify(() => mockTcpipService.switchUsbToWifi('USB_SERIAL_123'))
            .called(1);

        // Second run: should skip already provisioned serial
        final secondRun = await handoffService.autoProvisionUsbDevices([
          usbDevice,
        ]);
        expect(secondRun, isFalse);
        verifyNoMoreInteractions(mockTcpipService);
      },
    );

    test('re-provisions if device was disconnected and reconnects', () async {
      const usbDevice = AdbDevice(
        serial: 'USB_SERIAL_123',
        state: 'device',
        model: 'Moto G',
      );

      when(() => mockTcpipService.switchUsbToWifi('USB_SERIAL_123')).thenAnswer(
        (_) async => const AdbCommandResult(isSuccess: true, message: 'ok'),
      );

      // Provision initially
      await handoffService.autoProvisionUsbDevices([usbDevice]);

      // Device disconnected (empty attached list)
      await handoffService.autoProvisionUsbDevices([]);

      // Device re-attached: should provision again
      final reconnected = await handoffService.autoProvisionUsbDevices([
        usbDevice,
      ]);
      expect(reconnected, isTrue);
      verify(() => mockTcpipService.switchUsbToWifi('USB_SERIAL_123'))
          .called(2);
    });
  });
}
