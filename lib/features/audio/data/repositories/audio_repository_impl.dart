import 'dart:async';

import 'package:desk_droid/core/constants/audio_constants.dart';
import 'package:desk_droid/core/services/audio_stream_native_service.dart';
import 'package:desk_droid/features/audio/data/services/audio_playback_status_mapper.dart';
import 'package:desk_droid/features/audio/domain/entities/audio_playback.dart';
import 'package:desk_droid/features/audio/domain/repositories/audio_repository.dart';

/// [AudioRepository] over the native audio player.
class AudioRepositoryImpl implements AudioRepository {
  AudioRepositoryImpl({
    required this._native,
    this.pollInterval = AudioConstants.playbackPollInterval,
  });

  final IAudioStreamNativeService _native;
  final Duration pollInterval;

  double _volume = AudioConstants.defaultVolume;
  bool _isMuted = false;

  @override
  double get volume => _volume;

  @override
  bool get isMuted => _isMuted;

  @override
  Stream<AudioPlayback> watch() async* {
    if (!await _native.isAvailable()) {
      yield _playback(AudioPlaybackStatus.unavailableOnHost);
      return;
    }
    while (true) {
      final stats = await _native.getStats();
      yield _playback(
        stats.toPlaybackStatus(),
        bufferedMs: stats?.bufferedMs ?? 0,
        underruns: stats?.underruns ?? 0,
      );
      await Future<void>.delayed(pollInterval);
    }
  }

  @override
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(AudioConstants.minVolume, AudioConstants.maxVolume);
    await _native.setVolume(_volume);
  }

  @override
  Future<void> setMuted(bool muted) async {
    _isMuted = muted;
    await _native.setMuted(muted);
  }

  AudioPlayback _playback(
    AudioPlaybackStatus status, {
    int bufferedMs = 0,
    int underruns = 0,
  }) => AudioPlayback(
    status: status,
    volume: _volume,
    isMuted: _isMuted,
    bufferedMs: bufferedMs,
    underruns: underruns,
  );
}
