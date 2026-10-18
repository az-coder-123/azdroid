import 'package:desk_droid/core/constants/audio_constants.dart';
import 'package:equatable/equatable.dart';

/// What the user hears from the mirrored device.
enum AudioPlaybackStatus {
  /// Mirroring is starting, or the audio header has not arrived yet.
  starting,
  playing,

  /// The device cannot share its audio (Android 10 or older).
  unavailableOnDevice,

  /// This computer build has no audio player.
  unavailableOnHost,
  failed,

  /// Audio stopped while mirroring continued (the device closed it).
  ended,
}

/// Current playback state and the user's volume choice.
class AudioPlayback extends Equatable {
  const AudioPlayback({
    this.status = AudioPlaybackStatus.starting,
    this.volume = AudioConstants.defaultVolume,
    this.isMuted = false,
    this.bufferedMs = 0,
    this.underruns = 0,
  });

  final AudioPlaybackStatus status;

  /// Playback volume, 0.0 – 1.0.
  final double volume;
  final bool isMuted;

  /// Audio waiting in the jitter buffer (about 50 ms when healthy).
  final int bufferedMs;

  /// Times the buffer ran dry since audio started (each is a short gap).
  final int underruns;

  AudioPlayback copyWith({
    AudioPlaybackStatus? status,
    double? volume,
    bool? isMuted,
    int? bufferedMs,
    int? underruns,
  }) => AudioPlayback(
    status: status ?? this.status,
    volume: volume ?? this.volume,
    isMuted: isMuted ?? this.isMuted,
    bufferedMs: bufferedMs ?? this.bufferedMs,
    underruns: underruns ?? this.underruns,
  );

  @override
  List<Object?> get props => [status, volume, isMuted, bufferedMs, underruns];
}
