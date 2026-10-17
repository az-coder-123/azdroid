import 'package:bloc_test/bloc_test.dart';
import 'package:desk_droid/core/models/device_entity.dart';
import 'package:desk_droid/features/streaming/domain/entities/stream_session_entity.dart';
import 'package:desk_droid/features/streaming/domain/entities/stream_telemetry.dart';
import 'package:desk_droid/features/streaming/domain/errors/stream_start_exception.dart';
import 'package:desk_droid/features/streaming/domain/repositories/streaming_repository.dart';
import 'package:desk_droid/features/streaming/presentation/cubit/stream_health_message.dart';
import 'package:desk_droid/features/streaming/presentation/cubit/stream_start_failure_message.dart';
import 'package:desk_droid/features/streaming/presentation/cubit/streaming_cubit.dart';
import 'package:desk_droid/features/streaming/presentation/cubit/streaming_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockStreamingRepository extends Mock implements StreamingRepository {}

void main() {
  late MockStreamingRepository mockRepository;
  late StreamingCubit streamingCubit;

  setUp(() {
    mockRepository = MockStreamingRepository();
    when(() => mockRepository.watchTelemetry())
        .thenAnswer((_) => const Stream.empty());
    streamingCubit = StreamingCubit(repository: mockRepository);
  });

  tearDown(() {
    streamingCubit.close();
  });

  group('StreamingCubit', () {
    const testDevice = DeviceEntity(
      id: '192.168.1.100:5555',
      name: 'Google Pixel 8',
      ipAddress: '192.168.1.100',
      port: 5555,
      connectionType: DeviceConnectionType.wireless,
    );

    const testSession = StreamSessionEntity(
      sessionId: 'session_123',
      deviceId: '192.168.1.100:5555',
      deviceName: 'Google Pixel 8',
      width: 1080,
      height: 2400,
      fps: 60,
      bitrateMbps: 8,
    );

    test('initial state should be StreamingInitial', () {
      expect(streamingCubit.state, equals(const StreamingInitial()));
    });

    blocTest<StreamingCubit, StreamingState>(
      'emits [StreamingStarting, StreamingActive] when startSession succeeds',
      build: () {
        when(() => mockRepository.startSession(testDevice))
            .thenAnswer((_) async => testSession);
        return streamingCubit;
      },
      act: (cubit) => cubit.startSession(testDevice),
      expect: () => [
        const StreamingStarting(device: testDevice),
        const StreamingActive(session: testSession),
      ],
      verify: (_) {
        verify(() => mockRepository.startSession(testDevice)).called(1);
      },
    );

    blocTest<StreamingCubit, StreamingState>(
      'adds measured telemetry to the active state',
      build: () {
        when(() => mockRepository.startSession(testDevice))
            .thenAnswer((_) async => testSession);
        when(() => mockRepository.watchTelemetry()).thenAnswer(
          (_) => Stream.value(
            const StreamTelemetry(health: StreamHealth.live, fps: 58),
          ),
        );
        return streamingCubit;
      },
      act: (cubit) => cubit.startSession(testDevice),
      expect: () => [
        const StreamingStarting(device: testDevice),
        const StreamingActive(session: testSession),
        const StreamingActive(
          session: testSession,
          telemetry: StreamTelemetry(health: StreamHealth.live, fps: 58),
        ),
      ],
    );

    blocTest<StreamingCubit, StreamingState>(
      'resizes the session to the decoded video size (e.g. rotation)',
      build: () {
        when(() => mockRepository.watchTelemetry()).thenAnswer(
          (_) => Stream.value(
            const StreamTelemetry(
              health: StreamHealth.live,
              videoWidth: 2400,
              videoHeight: 1080,
            ),
          ),
        );
        return streamingCubit;
      },
      seed: () => const StreamingActive(session: testSession),
      act: (cubit) => cubit.startTelemetry(),
      expect: () => [
        StreamingActive(
          session: testSession.copyWith(width: 2400, height: 1080),
          telemetry: const StreamTelemetry(
            health: StreamHealth.live,
            videoWidth: 2400,
            videoHeight: 1080,
          ),
        ),
      ],
    );

    blocTest<StreamingCubit, StreamingState>(
      'shows the pending bitrate, then the restarted session',
      build: () {
        when(() => mockRepository.updateBitrate(testSession.sessionId, 16))
            .thenAnswer(
              (_) async => testSession.copyWith(bitrateMbps: 16, textureId: 7),
            );
        return streamingCubit;
      },
      seed: () => const StreamingActive(session: testSession),
      act: (cubit) => cubit.updateBitrate(16),
      expect: () => [
        const StreamingActive(session: testSession, pendingBitrateMbps: 16),
        StreamingActive(
          session: testSession.copyWith(bitrateMbps: 16, textureId: 7),
        ),
      ],
    );

    blocTest<StreamingCubit, StreamingState>(
      'ignores a bitrate that is already active',
      build: () => streamingCubit,
      seed: () => const StreamingActive(session: testSession),
      act: (cubit) => cubit.updateBitrate(testSession.bitrateMbps),
      expect: () => const <StreamingState>[],
    );

    blocTest<StreamingCubit, StreamingState>(
      'ends the session with guidance when the restart fails',
      build: () {
        when(() => mockRepository.updateBitrate(any(), any())).thenThrow(
          StreamStartException(
            StreamStartFailure.serverStartFailed,
            deviceSerial: testSession.deviceId,
          ),
        );
        when(() => mockRepository.stopSession(any())).thenAnswer((_) async {});
        return streamingCubit;
      },
      seed: () => const StreamingActive(session: testSession),
      act: (cubit) => cubit.updateBitrate(16),
      expect: () => [
        const StreamingActive(session: testSession, pendingBitrateMbps: 16),
        StreamingError(
          message: StreamStartFailure.serverStartFailed.messageFor(
            testSession.deviceName,
          ),
        ),
      ],
      verify: (_) {
        verify(() => mockRepository.stopSession(testSession.sessionId))
            .called(1);
      },
    );

    blocTest<StreamingCubit, StreamingState>(
      'stops the session and explains when the video stream ends',
      build: () {
        when(() => mockRepository.startSession(testDevice))
            .thenAnswer((_) async => testSession);
        when(() => mockRepository.stopSession(testSession.sessionId))
            .thenAnswer((_) async {});
        when(() => mockRepository.watchTelemetry()).thenAnswer(
          (_) =>
              Stream.value(const StreamTelemetry(health: StreamHealth.ended)),
        );
        return streamingCubit;
      },
      act: (cubit) => cubit.startSession(testDevice),
      expect: () => [
        const StreamingStarting(device: testDevice),
        const StreamingActive(session: testSession),
        StreamingError(
          message: StreamHealth.ended.messageFor(testSession.deviceName)!,
        ),
      ],
      verify: (_) {
        verify(() => mockRepository.stopSession(testSession.sessionId))
            .called(1);
      },
    );

    blocTest<StreamingCubit, StreamingState>(
      'emits [StreamingStarting, StreamingError] when startSession fails',
      build: () {
        when(() => mockRepository.startSession(testDevice))
            .thenThrow(Exception('Socket connection failed'));
        return streamingCubit;
      },
      act: (cubit) => cubit.startSession(testDevice),
      expect: () => [
        const StreamingStarting(device: testDevice),
        const StreamingError(
          message: 'Failed to start mirroring session: Exception: Socket connection failed',
        ),
      ],
    );

    blocTest<StreamingCubit, StreamingState>(
      'emits actionable guidance when the device is unauthorized',
      build: () {
        when(() => mockRepository.startSession(testDevice)).thenThrow(
          StreamStartException(
            StreamStartFailure.deviceUnauthorized,
            deviceSerial: testDevice.id,
          ),
        );
        return streamingCubit;
      },
      act: (cubit) => cubit.startSession(testDevice),
      expect: () => [
        const StreamingStarting(device: testDevice),
        StreamingError(
          message: StreamStartFailure.deviceUnauthorized.messageFor(
            testDevice.name,
          ),
        ),
      ],
    );

    blocTest<StreamingCubit, StreamingState>(
      'stopSession terminates session and emits StreamingInitial',
      build: () {
        when(() => mockRepository.startSession(testDevice))
            .thenAnswer((_) async => testSession);
        when(() => mockRepository.stopSession('session_123'))
            .thenAnswer((_) async {});
        return streamingCubit;
      },
      seed: () => const StreamingActive(session: testSession),
      act: (cubit) => cubit.stopSession(),
      expect: () => [const StreamingInitial()],
      verify: (_) {
        verify(() => mockRepository.stopSession('session_123')).called(1);
      },
    );

    blocTest<StreamingCubit, StreamingState>(
      'rotateScreen increments rotation by 90 degrees',
      build: () => streamingCubit,
      seed: () => const StreamingActive(session: testSession),
      act: (cubit) => cubit.rotateScreen(),
      expect: () => [
        const StreamingActive(session: testSession, rotationDegrees: 90),
      ],
    );

    blocTest<StreamingCubit, StreamingState>(
      'toggleScreenOff updates session screen-off state',
      build: () {
        when(() => mockRepository.toggleScreenOff('session_123', true))
            .thenAnswer((_) async {});
        return streamingCubit;
      },
      seed: () => const StreamingActive(session: testSession),
      act: (cubit) => cubit.toggleScreenOff(),
      expect: () => [
        StreamingActive(session: testSession.copyWith(isScreenOff: true)),
      ],
    );
  });
}
