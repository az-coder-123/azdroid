import 'dart:async';

import 'package:desk_droid/core/services/app_logger.dart';
import 'package:desk_droid/features/audio/domain/entities/audio_playback.dart';
import 'package:desk_droid/features/audio/domain/repositories/audio_repository.dart';
import 'package:desk_droid/features/audio/presentation/cubit/audio_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Shows the mirrored device's audio state and applies volume and mute.
///
/// Audio starts and stops with the mirroring session; this cubit only
/// watches it.
class AudioCubit extends Cubit<AudioState> {
  AudioCubit({required this.repository}) : super(const AudioInitial());

  final AudioRepository repository;
  StreamSubscription<AudioPlayback>? _subscription;

  /// Starts following the playback state.
  void watchPlayback() {
    unawaited(_subscription?.cancel());
    _subscription = repository.watch().listen(
      (playback) {
        if (!isClosed) emit(AudioActive(playback: playback));
      },
      onError: (Object error, StackTrace stack) => AppLogger.warning(
        'Audio playback state failed',
        error: error,
        stackTrace: stack,
      ),
    );
  }

  /// Sets the playback volume (0.0 – 1.0).
  Future<void> setVolume(double volume) async {
    await repository.setVolume(volume);
    _emitChoice();
  }

  /// Toggles mute.
  Future<void> toggleMute() async {
    await repository.setMuted(!repository.isMuted);
    _emitChoice();
  }

  /// Shows the user's choice at once, without waiting for the next sample.
  void _emitChoice() {
    final current = state;
    if (isClosed || current is! AudioActive) return;
    emit(
      AudioActive(
        playback: current.playback.copyWith(
          volume: repository.volume,
          isMuted: repository.isMuted,
        ),
      ),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
