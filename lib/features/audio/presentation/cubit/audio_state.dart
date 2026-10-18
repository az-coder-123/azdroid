import 'package:desk_droid/features/audio/domain/entities/audio_playback.dart';
import 'package:equatable/equatable.dart';

/// Base state for audio playback.
sealed class AudioState extends Equatable {
  const AudioState();

  @override
  List<Object?> get props => [];
}

/// Before the first playback sample.
final class AudioInitial extends AudioState {
  const AudioInitial();
}

/// Latest playback sample; its status covers starting, playing,
/// unavailable, failed, and ended.
final class AudioActive extends AudioState {
  const AudioActive({required this.playback});

  final AudioPlayback playback;

  @override
  List<Object?> get props => [playback];
}
