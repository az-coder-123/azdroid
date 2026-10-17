import 'package:bloc_test/bloc_test.dart';
import 'package:desk_droid/core/models/device_entity.dart';
import 'package:desk_droid/features/streaming/domain/entities/stream_session_entity.dart';
import 'package:desk_droid/features/streaming/domain/errors/stream_start_exception.dart';
import 'package:desk_droid/features/streaming/domain/repositories/streaming_repository.dart';
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
