import 'package:desk_droid/core/models/native_audio_stats.dart';
import 'package:desk_droid/core/services/audio_stream_native_service.dart';
import 'package:desk_droid/features/audio/data/repositories/audio_repository_impl.dart';
import 'package:desk_droid/features/audio/domain/entities/audio_playback.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockNative extends Mock implements IAudioStreamNativeService {}

void main() {
  late _MockNative native;
  late AudioRepositoryImpl repository;

  setUp(() {
    native = _MockNative();
    when(() => native.isAvailable()).thenAnswer((_) async => true);
    when(() => native.setVolume(any())).thenAnswer((_) async {});
    when(() => native.setMuted(any())).thenAnswer((_) async {});
    repository = AudioRepositoryImpl(
      native: native,
      pollInterval: Duration.zero,
    );
  });

  Future<AudioPlayback> firstFor(NativeAudioStats? stats) async {
    when(() => native.getStats()).thenAnswer((_) async => stats);
    return repository.watch().first;
  }

  test('maps every native state to what the user is told', () async {
    final cases = {
      NativeAudioState.connecting: AudioPlaybackStatus.starting,
      NativeAudioState.idle: AudioPlaybackStatus.starting,
      NativeAudioState.playing: AudioPlaybackStatus.playing,
      NativeAudioState.disabled: AudioPlaybackStatus.unavailableOnDevice,
      NativeAudioState.failed: AudioPlaybackStatus.failed,
      NativeAudioState.ended: AudioPlaybackStatus.ended,
      NativeAudioState.unknown: AudioPlaybackStatus.starting,
    };
    for (final entry in cases.entries) {
      final playback = await firstFor(NativeAudioStats(state: entry.key));
      expect(playback.status, entry.value, reason: '${entry.key}');
    }
  });

  test('reports buffering and underruns from the native counters', () async {
    final playback = await firstFor(
      const NativeAudioStats(
        state: NativeAudioState.playing,
        bufferedFrames: 2400,
        underruns: 3,
      ),
    );

    expect(playback.bufferedMs, 50);
    expect(playback.underruns, 3);
  });

  test('says the host has no player when the platform lacks one', () async {
    when(() => native.isAvailable()).thenAnswer((_) async => false);

    final all = await repository.watch().toList();

    expect(all.single.status, AudioPlaybackStatus.unavailableOnHost);
    verifyNever(() => native.getStats());
  });

  test('keeps polling while listened to', () async {
    when(() => native.getStats()).thenAnswer(
      (_) async => const NativeAudioStats(state: NativeAudioState.playing),
    );

    final samples = await repository.watch().take(3).toList();

    expect(samples, hasLength(3));
    verify(() => native.getStats()).called(3);
  });

  test('volume is clamped, applied natively, and reported', () async {
    await repository.setVolume(1.7);
    expect(repository.volume, 1.0);
    verify(() => native.setVolume(1.0)).called(1);

    await repository.setVolume(0.25);
    final playback = await firstFor(
      const NativeAudioStats(state: NativeAudioState.playing),
    );
    expect(playback.volume, 0.25);
  });

  test('mute is applied natively and reported', () async {
    await repository.setMuted(true);

    verify(() => native.setMuted(true)).called(1);
    expect(repository.isMuted, isTrue);
    final playback = await firstFor(
      const NativeAudioStats(state: NativeAudioState.playing),
    );
    expect(playback.isMuted, isTrue);
  });
}
