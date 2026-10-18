import 'package:desk_droid/core/models/device_entity.dart';
import 'package:desk_droid/core/services/video_stream_native_service.dart';
import 'package:desk_droid/features/streaming/data/datasources/scrcpy_server_manager.dart';
import 'package:desk_droid/features/streaming/data/repositories/streaming_repository_impl.dart';
import 'package:desk_droid/features/streaming/data/services/scrcpy_control_connector.dart';
import 'package:desk_droid/features/streaming/data/services/stream_device_preflight.dart';
import 'package:desk_droid/features/streaming/domain/errors/stream_start_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/fake_audio_stream_native_service.dart';

class MockScrcpyServerManager extends Mock implements ScrcpyServerManager {}

class MockVideoStreamNativeService extends Mock
    implements IVideoStreamNativeService {}

class MockStreamDevicePreflight extends Mock implements StreamDevicePreflight {}

class MockScrcpyControlConnector extends Mock
    implements ScrcpyControlConnector {}

void main() {
  late MockScrcpyServerManager mockServerManager;
  late MockVideoStreamNativeService mockNativeService;
  late MockStreamDevicePreflight mockPreflight;
  late MockScrcpyControlConnector mockControl;
  late StreamingRepositoryImpl repository;

  setUp(() {
    mockServerManager = MockScrcpyServerManager();
    mockNativeService = MockVideoStreamNativeService();
    mockPreflight = MockStreamDevicePreflight();
    mockControl = MockScrcpyControlConnector();
    when(() => mockPreflight.ensureReady(any())).thenAnswer((_) async {});
    when(() => mockControl.waitForVideoSocket()).thenAnswer((_) async => true);
    when(
      () => mockControl.openControl(
        deviceSerial: any(named: 'deviceSerial'),
        port: any(named: 'port'),
      ),
    ).thenAnswer((_) async => true);
    when(() => mockControl.disconnect()).thenAnswer((_) async {});
    repository = StreamingRepositoryImpl(
      serverManager: mockServerManager,
      videoStreamNativeService: mockNativeService,
      devicePreflight: mockPreflight,
      controlConnector: mockControl,
      audioService: FakeAudioStreamNativeService(),
    );
  });

  group('StreamingRepositoryImpl', () {
    const testDevice = DeviceEntity(
      id: '192.168.1.100:5555',
      name: 'Google Pixel 8 Pro',
      ipAddress: '192.168.1.100',
      port: 5555,
      connectionType: DeviceConnectionType.wireless,
    );

    test('startSession starts server daemon, calls native stream, and returns session', () async {
      when(
        () => mockServerManager.startServerDaemon(
          deviceSerial: any(named: 'deviceSerial'),
          port: any(named: 'port'),
          maxFps: any(named: 'maxFps'),
          bitrateMbps: any(named: 'bitrateMbps'),
        ),
      ).thenAnswer((_) async => true);

      when(
        () => mockNativeService.startStream(
          host: any(named: 'host'),
          port: any(named: 'port'),
        ),
      ).thenAnswer((_) async => 42);

      when(() => mockNativeService.getDimensions())
          .thenAnswer((_) async => {'width': 1080, 'height': 2400});

      final session = await repository.startSession(testDevice);

      expect(session.deviceId, equals(testDevice.id));
      expect(session.deviceName, equals(testDevice.name));
      expect(session.fps, equals(60));
      expect(session.bitrateMbps, equals(8));
      expect(session.textureId, equals(42));
      expect(session.width, equals(1080));
      expect(session.height, equals(2400));

      verify(
        () => mockServerManager.startServerDaemon(
          deviceSerial: testDevice.id,
          maxFps: 60,
          bitrateMbps: 8,
        ),
      ).called(1);

      verify(
        () => mockNativeService.startStream(
          host: '127.0.0.1',
          port: any(named: 'port'),
        ),
      ).called(1);
    });

    test('startSession stops before the server when preflight fails', () async {
      when(() => mockPreflight.ensureReady(testDevice.id)).thenThrow(
        StreamStartException(
          StreamStartFailure.deviceUnauthorized,
          deviceSerial: testDevice.id,
        ),
      );

      await expectLater(
        repository.startSession(testDevice),
        throwsA(
          isA<StreamStartException>().having(
            (e) => e.failure,
            'failure',
            StreamStartFailure.deviceUnauthorized,
          ),
        ),
      );

      verifyNever(
        () => mockServerManager.startServerDaemon(
          deviceSerial: any(named: 'deviceSerial'),
          port: any(named: 'port'),
          maxFps: any(named: 'maxFps'),
          bitrateMbps: any(named: 'bitrateMbps'),
        ),
      );
      verifyNever(
        () => mockNativeService.startStream(
          host: any(named: 'host'),
          port: any(named: 'port'),
        ),
      );
    });

    test(
      'startSession throws serverStartFailed when the daemon fails',
      () async {
        when(
          () => mockServerManager.startServerDaemon(
            deviceSerial: any(named: 'deviceSerial'),
            port: any(named: 'port'),
            maxFps: any(named: 'maxFps'),
            bitrateMbps: any(named: 'bitrateMbps'),
          ),
        ).thenAnswer((_) async => false);

        await expectLater(
          repository.startSession(testDevice),
          throwsA(
            isA<StreamStartException>().having(
              (e) => e.failure,
              'failure',
              StreamStartFailure.serverStartFailed,
            ),
          ),
        );

        verifyNever(
          () => mockNativeService.startStream(
            host: any(named: 'host'),
            port: any(named: 'port'),
          ),
        );
      },
    );

    group('updateBitrate', () {
      void stubPipeline({bool serverStarts = true}) {
        when(
          () => mockServerManager.startServerDaemon(
            deviceSerial: any(named: 'deviceSerial'),
            port: any(named: 'port'),
            maxFps: any(named: 'maxFps'),
            bitrateMbps: any(named: 'bitrateMbps'),
          ),
        ).thenAnswer((_) async => serverStarts);
        when(() => mockNativeService.stopStream()).thenAnswer((_) async {});
        when(() => mockNativeService.getDimensions())
            .thenAnswer((_) async => {'width': 1080, 'height': 2400});
      }

      test('restarts the pipeline at the new bitrate', () async {
        stubPipeline();
        var nextTexture = 42;
        when(
          () => mockNativeService.startStream(
            host: any(named: 'host'),
            port: any(named: 'port'),
          ),
        ).thenAnswer((_) async => nextTexture++);
        final session = await repository.startSession(testDevice);

        final updated = await repository.updateBitrate(session.sessionId, 16);

        expect(updated.bitrateMbps, 16);
        expect(updated.textureId, 43);
        expect(updated.sessionId, session.sessionId);
        verify(() => mockNativeService.stopStream()).called(1);
        verify(
          () => mockServerManager.startServerDaemon(
            deviceSerial: testDevice.id,
            port: any(named: 'port'),
            maxFps: 60,
            bitrateMbps: 16,
          ),
        ).called(1);
      });

      test('keeps the pipeline when the bitrate is unchanged', () async {
        stubPipeline();
        when(
          () => mockNativeService.startStream(
            host: any(named: 'host'),
            port: any(named: 'port'),
          ),
        ).thenAnswer((_) async => 42);
        final session = await repository.startSession(testDevice);

        final updated = await repository.updateBitrate(session.sessionId, 8);

        expect(updated, session);
        verifyNever(() => mockNativeService.stopStream());
      });

      test(
        'throws serverStartFailed when the restarted server fails',
        () async {
          stubPipeline();
          when(
            () => mockNativeService.startStream(
              host: any(named: 'host'),
              port: any(named: 'port'),
            ),
          ).thenAnswer((_) async => 42);
          final session = await repository.startSession(testDevice);
          stubPipeline(serverStarts: false);

          await expectLater(
            repository.updateBitrate(session.sessionId, 4),
            throwsA(
              isA<StreamStartException>().having(
                (e) => e.failure,
                'failure',
                StreamStartFailure.serverStartFailed,
              ),
            ),
          );
        },
      );

      test('rejects an unknown session', () {
        expect(
          repository.updateBitrate('missing', 16),
          throwsA(isA<StateError>()),
        );
      });
    });

    test('stopSession stops native stream and stops server daemon', () async {
      when(
        () => mockServerManager.startServerDaemon(
          deviceSerial: any(named: 'deviceSerial'),
          port: any(named: 'port'),
          maxFps: any(named: 'maxFps'),
          bitrateMbps: any(named: 'bitrateMbps'),
        ),
      ).thenAnswer((_) async => true);

      when(
        () => mockNativeService.startStream(
          host: any(named: 'host'),
          port: any(named: 'port'),
        ),
      ).thenAnswer((_) async => 42);

      when(() => mockNativeService.getDimensions())
          .thenAnswer((_) async => {'width': 1080, 'height': 2400});

      when(() => mockNativeService.stopStream()).thenAnswer((_) async {});
      when(
        () => mockServerManager.stopServerDaemon(
          deviceSerial: any(named: 'deviceSerial'),
        ),
      ).thenAnswer((_) async {});

      final session = await repository.startSession(testDevice);
      await repository.stopSession(session.sessionId);

      verify(() => mockNativeService.stopStream()).called(1);
      verify(
        () => mockServerManager.stopServerDaemon(deviceSerial: testDevice.id),
      ).called(1);
    });

    test(
      'startSession fails with controlConnectFailed and cleans up',
      () async {
        when(
          () => mockServerManager.startServerDaemon(
            deviceSerial: any(named: 'deviceSerial'),
            port: any(named: 'port'),
            maxFps: any(named: 'maxFps'),
            bitrateMbps: any(named: 'bitrateMbps'),
          ),
        ).thenAnswer((_) async => true);
        when(
          () => mockNativeService.startStream(
            host: any(named: 'host'),
            port: any(named: 'port'),
          ),
        ).thenAnswer((_) async => 42);
        when(() => mockNativeService.stopStream()).thenAnswer((_) async {});
        when(
          () => mockServerManager.stopServerDaemon(
            deviceSerial: any(named: 'deviceSerial'),
          ),
        ).thenAnswer((_) async {});
        when(() => mockControl.waitForVideoSocket())
            .thenAnswer((_) async => true);
        when(
          () => mockControl.openControl(
            deviceSerial: any(named: 'deviceSerial'),
            port: any(named: 'port'),
          ),
        ).thenAnswer((_) async => false);

        await expectLater(
          repository.startSession(testDevice),
          throwsA(
            isA<StreamStartException>().having(
              (e) => e.failure,
              'failure',
              StreamStartFailure.controlConnectFailed,
            ),
          ),
        );
        verify(() => mockNativeService.stopStream()).called(1);
        verify(
          () => mockServerManager.stopServerDaemon(deviceSerial: testDevice.id),
        ).called(1);
      },
    );
  });
}
