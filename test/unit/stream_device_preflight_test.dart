import 'package:desk_droid/core/services/adb_service.dart';
import 'package:desk_droid/features/streaming/data/services/stream_device_preflight.dart';
import 'package:desk_droid/features/streaming/domain/errors/stream_start_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAdbService extends Mock implements AdbService {}

void main() {
  const serial = '192.168.1.3:5555';
  late MockAdbService adbService;
  late StreamDevicePreflight preflight;

  setUp(() {
    adbService = MockAdbService();
    preflight = StreamDevicePreflight(adbService: adbService);
  });

  void stubDevices(List<AdbDevice> devices) {
    when(() => adbService.getAttachedDevices())
        .thenAnswer((_) async => devices);
  }

  Matcher throwsFailure(StreamStartFailure failure) => throwsA(
    isA<StreamStartException>()
        .having((e) => e.failure, 'failure', failure)
        .having((e) => e.deviceSerial, 'deviceSerial', serial),
  );

  group('StreamDevicePreflight.ensureReady', () {
    test('completes when the device is authorized', () async {
      stubDevices([const AdbDevice(serial: serial, state: 'device')]);

      await expectLater(preflight.ensureReady(serial), completes);
    });

    test(
      'reconnects an unauthorized Wi-Fi device so the phone prompts again',
      () async {
        stubDevices([const AdbDevice(serial: serial, state: 'unauthorized')]);
        const ok = AdbCommandResult(isSuccess: true, message: '');
        when(() => adbService.disconnect(serial)).thenAnswer((_) async => ok);
        when(() => adbService.connect('192.168.1.3', 5555))
            .thenAnswer((_) async => ok);

        await expectLater(
          preflight.ensureReady(serial),
          throwsFailure(StreamStartFailure.deviceUnauthorized),
        );
        verifyInOrder([
          () => adbService.disconnect(serial),
          () => adbService.connect('192.168.1.3', 5555),
        ]);
      },
    );

    test('leaves an unauthorized USB device connected', () async {
      const usbSerial = 'R58M12ABCDE';
      stubDevices([const AdbDevice(serial: usbSerial, state: 'unauthorized')]);

      await expectLater(
        preflight.ensureReady(usbSerial),
        throwsA(isA<StreamStartException>()),
      );
      verifyNever(() => adbService.disconnect(any()));
      verifyNever(() => adbService.connect(any(), any()));
    });

    test('throws deviceOffline for any other non-ready state', () {
      stubDevices([const AdbDevice(serial: serial, state: 'offline')]);

      expect(
        preflight.ensureReady(serial),
        throwsFailure(StreamStartFailure.deviceOffline),
      );
    });

    test('throws deviceNotFound when only other devices are listed', () {
      stubDevices([const AdbDevice(serial: 'other:5555', state: 'device')]);

      expect(
        preflight.ensureReady(serial),
        throwsFailure(StreamStartFailure.deviceNotFound),
      );
    });
  });

  group('StreamDevicePreflight.wifiEndpointOf', () {
    test('splits an ip:port serial', () {
      expect(StreamDevicePreflight.wifiEndpointOf('192.168.1.3:5555'), (
        host: '192.168.1.3',
        port: 5555,
      ));
    });

    test('returns null for USB and mDNS serials', () {
      expect(StreamDevicePreflight.wifiEndpointOf('R58M12ABCDE'), isNull);
      expect(
        StreamDevicePreflight.wifiEndpointOf(
          'adb-R58M12ABCDE-x1y2z3._adb-tls-connect._tcp',
        ),
        isNull,
      );
    });
  });
}
