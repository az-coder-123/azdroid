import 'package:equatable/equatable.dart';
import 'package:wifi_desk/features/audio/domain/entities/audio_stream_entity.dart';

/// Base state for audio forwarding.
sealed class AudioState extends Equatable {
  const AudioState();

  @override
  List<Object?> get props => [];
}

/// Initial uninitialized state.
class AudioInitial extends AudioState {
  const AudioInitial();
}

/// State emitted while audio tunnel is establishing.
class AudioStarting extends AudioState {
  const AudioStarting();
}

/// State emitted when audio forwarding is active.
class AudioActive extends AudioState {
  const AudioActive({required this.audioStream});

  final AudioStreamEntity audioStream;

  @override
  List<Object?> get props => [audioStream];
}

/// State emitted upon audio forwarding error.
class AudioError extends AudioState {
  const AudioError({required this.errorMessage});

  final String errorMessage;

  @override
  List<Object?> get props => [errorMessage];
}
