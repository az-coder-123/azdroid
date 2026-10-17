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

    test('throws deviceUnauthorized when USB debugging is not allowed', () {
      stubDevices([const AdbDevice(serial: serial, state: 'unauthorized')]);

      expect(
        preflight.ensureReady(serial),
        throwsFailure(StreamStartFailure.deviceUnauthorized),
      );
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
}
