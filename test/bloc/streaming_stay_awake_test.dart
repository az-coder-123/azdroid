import 'package:bloc_test/bloc_test.dart';
import 'package:desk_droid/core/models/device_entity.dart';
import 'package:desk_droid/features/streaming/domain/entities/mirroring_preferences.dart';
import 'package:desk_droid/features/streaming/domain/entities/stream_session_entity.dart';
import 'package:desk_droid/features/streaming/domain/errors/stream_start_exception.dart';
import 'package:desk_droid/features/streaming/domain/repositories/streaming_repository.dart';
import 'package:desk_droid/features/streaming/presentation/cubit/pending_stream_change.dart';
import 'package:desk_droid/features/streaming/presentation/cubit/stream_start_failure_message.dart';
import 'package:desk_droid/features/streaming/presentation/cubit/streaming_cubit.dart';
import 'package:desk_droid/features/streaming/presentation/cubit/streaming_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/fake_mirroring_preferences_repository.dart';

class _MockStreamingRepository extends Mock implements StreamingRepository {}

void main() {
  const device = DeviceEntity(
    id: '192.168.1.3:5555',
    name: 'Redmi 9',
    ipAddress: '192.168.1.3',
    port: 5555,
    connectionType: DeviceConnectionType.wireless,
  );
  const awakeSession = StreamSessionEntity(
    sessionId: 'session_1',
    deviceId: '192.168.1.3:5555',
    deviceName: 'Redmi 9',
    width: 1080,
    height: 2336,
    fps: 60,
    bitrateMbps: 8,
    stayAwake: true,
  );

  late _MockStreamingRepository repository;
  late FakeMirroringPreferencesRepository preferences;

  setUp(() {
    repository = _MockStreamingRepository();
    preferences = FakeMirroringPreferencesRepository();
    when(() => repository.watchTelemetry())
        .thenAnswer((_) => const Stream.empty());
    when(() => repository.stopSession(any())).thenAnswer((_) async {});
  });

  StreamingCubit build() =>
      StreamingCubit(repository: repository, preferences: preferences);

  blocTest<StreamingCubit, StreamingState>(
    'startSession uses the saved stay-awake choice',
    setUp: () {
      preferences.stored = const MirroringPreferences(stayAwake: false);
      when(() => repository.startSession(device, stayAwake: false))
          .thenAnswer((_) async => awakeSession.copyWith(stayAwake: false));
    },
    build: build,
    act: (cubit) => cubit.startSession(device),
    verify: (_) =>
        verify(() => repository.startSession(device, stayAwake: false))
            .called(1),
  );

  blocTest<StreamingCubit, StreamingState>(
    'toggleStayAwake saves the choice and restarts with it',
    setUp: () =>
        when(() => repository.updateStayAwake(awakeSession.sessionId, false))
            .thenAnswer((_) async => awakeSession.copyWith(stayAwake: false)),
    build: build,
    seed: () => const StreamingActive(session: awakeSession),
    act: (cubit) => cubit.toggleStayAwake(),
    expect: () => [
      const StreamingActive(
        session: awakeSession,
        pendingChange: StayAwakeChange(enabled: false),
      ),
      StreamingActive(session: awakeSession.copyWith(stayAwake: false)),
    ],
    verify: (_) => expect(preferences.saved, [
      const MirroringPreferences(stayAwake: false),
    ]),
  );

  blocTest<StreamingCubit, StreamingState>(
    'toggleStayAwake is ignored while another change applies',
    build: build,
    seed: () => const StreamingActive(
      session: awakeSession,
      pendingChange: BitrateChange(16),
    ),
    act: (cubit) => cubit.toggleStayAwake(),
    expect: () => const <StreamingState>[],
    verify: (_) {
      expect(preferences.saved, isEmpty);
      verifyNever(() => repository.updateStayAwake(any(), any()));
    },
  );

  blocTest<StreamingCubit, StreamingState>(
    'toggleStayAwake ends the session with guidance when the restart fails',
    setUp: () => when(() => repository.updateStayAwake(any(), any())).thenThrow(
      StreamStartException(
        StreamStartFailure.serverStartFailed,
        deviceSerial: awakeSession.deviceId,
      ),
    ),
    build: build,
    seed: () => const StreamingActive(session: awakeSession),
    act: (cubit) => cubit.toggleStayAwake(),
    expect: () => [
      const StreamingActive(
        session: awakeSession,
        pendingChange: StayAwakeChange(enabled: false),
      ),
      StreamingError(
        message: StreamStartFailure.serverStartFailed.messageFor('Redmi 9'),
      ),
    ],
  );
}
