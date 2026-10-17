import 'package:bloc_test/bloc_test.dart';
import 'package:desk_droid/features/audio/domain/entities/audio_stream_entity.dart';
import 'package:desk_droid/features/audio/domain/repositories/audio_repository.dart';
import 'package:desk_droid/features/audio/presentation/cubit/audio_cubit.dart';
import 'package:desk_droid/features/audio/presentation/cubit/audio_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAudioRepository extends Mock implements AudioRepository {}

void main() {
  late MockAudioRepository mockRepository;
  const testSerial = '192.168.1.100:5555';

  const testStream = AudioStreamEntity(
    deviceId: testSerial,
    isEnabled: true,
    volume: 1.0,
    isMuted: false,
    latencyMs: 12,
  );

  setUp(() {
    mockRepository = MockAudioRepository();
    when(() => mockRepository.stopAudioStream(any())).thenAnswer((_) async {});
  });

  group('AudioCubit', () {
    test('initial state is AudioInitial', () {
      final cubit = AudioCubit(repository: mockRepository);
      expect(cubit.state, isA<AudioInitial>());
      cubit.close();
    });

    blocTest<AudioCubit, AudioState>(
      'startAudio emits [AudioStarting, AudioActive] on success',
      build: () {
        when(() => mockRepository.startAudioStream(testSerial))
            .thenAnswer((_) async => testStream);
        return AudioCubit(repository: mockRepository);
      },
      act: (cubit) => cubit.startAudio(testSerial),
      expect: () => [
        const AudioStarting(),
        const AudioActive(audioStream: testStream),
      ],
    );

    blocTest<AudioCubit, AudioState>(
      'startAudio emits [AudioStarting, AudioError] on failure',
      build: () {
        when(() => mockRepository.startAudioStream(testSerial))
            .thenThrow(Exception('Socket connection timeout'));
        return AudioCubit(repository: mockRepository);
      },
      act: (cubit) => cubit.startAudio(testSerial),
      expect: () => [const AudioStarting(), isA<AudioError>()],
    );

    blocTest<AudioCubit, AudioState>(
      'stopAudio emits AudioInitial',
      build: () {
        when(() => mockRepository.stopAudioStream(testSerial))
            .thenAnswer((_) async {});
        return AudioCubit(repository: mockRepository);
      },
      act: (cubit) => cubit.stopAudio(testSerial),
      expect: () => [const AudioInitial()],
    );

    blocTest<AudioCubit, AudioState>(
      'toggleMute updates audio stream entity state',
      build: () {
        when(() => mockRepository.toggleMute()).thenAnswer((_) async => true);
        final cubit = AudioCubit(repository: mockRepository);
        cubit.emit(const AudioActive(audioStream: testStream));
        return cubit;
      },
      act: (cubit) => cubit.toggleMute(),
      expect: () => [
        isA<AudioActive>().having(
          (s) => s.audioStream.isMuted,
          'isMuted',
          isTrue,
        ),
      ],
    );

    blocTest<AudioCubit, AudioState>(
      'setVolume updates volume on active stream',
      build: () {
        when(() => mockRepository.setVolume(0.5)).thenAnswer((_) async {});
        final cubit = AudioCubit(repository: mockRepository);
        cubit.emit(const AudioActive(audioStream: testStream));
        return cubit;
      },
      act: (cubit) => cubit.setVolume(0.5),
      expect: () => [
        isA<AudioActive>().having(
          (s) => s.audioStream.volume,
          'volume',
          equals(0.5),
        ),
      ],
    );
  });
}
