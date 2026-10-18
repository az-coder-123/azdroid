import 'package:desk_droid/core/models/native_audio_stats.dart';
import 'package:desk_droid/features/audio/domain/entities/audio_playback.dart';

/// Maps the native player's state to what the user is told.
extension AudioPlaybackStatusMapper on NativeAudioStats? {
  /// `null` stats mean the platform has no audio player.
  AudioPlaybackStatus toPlaybackStatus() => switch (this?.state) {
    null => AudioPlaybackStatus.unavailableOnHost,
    NativeAudioState.playing => AudioPlaybackStatus.playing,
    NativeAudioState.disabled => AudioPlaybackStatus.unavailableOnDevice,
    NativeAudioState.failed => AudioPlaybackStatus.failed,
    NativeAudioState.ended => AudioPlaybackStatus.ended,
    NativeAudioState.idle ||
    NativeAudioState.connecting ||
    NativeAudioState.unknown => AudioPlaybackStatus.starting,
  };
}
