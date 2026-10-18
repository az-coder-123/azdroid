import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:desk_droid/features/audio/domain/entities/audio_playback.dart';
import 'package:desk_droid/features/audio/domain/repositories/audio_repository.dart';
import 'package:desk_droid/features/audio/presentation/cubit/audio_cubit.dart';
import 'package:desk_droid/features/audio/presentation/cubit/audio_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAudioRepository extends Mock implements AudioRepository {}

void main() {
  const playing = AudioPlayback(status: AudioPlaybackStatus.playing);
  late _MockAudioRepository repository;
  var volume = 1.0;
  var muted = false;

  setUp(() {
    repository = _MockAudioRepository();
    volume = 1.0;
    muted = false;
    when(() => repository.volume).thenAnswer((_) => volume);
    when(() => repository.isMuted).thenAnswer((_) => muted);
    when(() => repository.setVolume(any())).thenAnswer((invocation) async {
      volume = invocation.positionalArguments.first as double;
    });
    when(() => repository.setMuted(any())).thenAnswer((invocation) async {
      muted = invocation.positionalArguments.first as bool;
    });
  });

  test('starts in AudioInitial', () {
    expect(AudioCubit(repository: repository).state, const AudioInitial());
  });

  blocTest<AudioCubit, AudioState>(
    'watchPlayback emits each playback sample',
    setUp: () => when(() => repository.watch()).thenAnswer(
      (_) => Stream.fromIterable(const [
        AudioPlayback(),
        playing,
        AudioPlayback(status: AudioPlaybackStatus.unavailableOnDevice),
      ]),
    ),
    build: () => AudioCubit(repository: repository),
    act: (cubit) => cubit.watchPlayback(),
    expect: () => const [
      AudioActive(playback: AudioPlayback()),
      AudioActive(playback: playing),
      AudioActive(
        playback: AudioPlayback(
          status: AudioPlaybackStatus.unavailableOnDevice,
        ),
      ),
    ],
  );

  blocTest<AudioCubit, AudioState>(
    'setVolume applies it and shows it at once',
    build: () => AudioCubit(repository: repository),
    seed: () => const AudioActive(playback: playing),
    act: (cubit) => cubit.setVolume(0.4),
    expect: () => [AudioActive(playback: playing.copyWith(volume: 0.4))],
    verify: (_) => verify(() => repository.setVolume(0.4)).called(1),
  );

  blocTest<AudioCubit, AudioState>(
    'toggleMute flips the repository choice',
    build: () => AudioCubit(repository: repository),
    seed: () => const AudioActive(playback: playing),
    act: (cubit) async {
      await cubit.toggleMute();
      await cubit.toggleMute();
    },
    expect: () => [
      AudioActive(playback: playing.copyWith(isMuted: true)),
      const AudioActive(playback: playing),
    ],
  );

  test('close stops watching', () async {
    final controller = StreamController<AudioPlayback>();
    when(() => repository.watch()).thenAnswer((_) => controller.stream);
    final cubit = AudioCubit(repository: repository)..watchPlayback();
    await Future<void>.delayed(Duration.zero);
    expect(controller.hasListener, isTrue);

    await cubit.close();

    expect(controller.hasListener, isFalse);
    await controller.close();
  });
}
