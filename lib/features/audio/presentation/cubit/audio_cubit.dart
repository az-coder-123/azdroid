import 'package:desk_droid/core/services/app_logger.dart';
import 'package:desk_droid/features/audio/domain/repositories/audio_repository.dart';
import 'package:desk_droid/features/audio/presentation/cubit/audio_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Cubit managing audio forwarding lifecycle, volume attenuation, and mute states.
class AudioCubit extends Cubit<AudioState> {
  AudioCubit({required this.repository}) : super(const AudioInitial());

  final AudioRepository repository;

  /// Starts audio capture and streaming from target device.
  Future<void> startAudio(String deviceSerial) async {
    emit(const AudioStarting());

    try {
      final stream = await repository.startAudioStream(deviceSerial);
      if (!isClosed) {
        emit(AudioActive(audioStream: stream));
      }
    } catch (e) {
      if (!isClosed) {
        emit(AudioError(errorMessage: 'Failed to initialize audio: $e'));
      }
    }
  }

  /// Terminates audio forwarding.
  Future<void> stopAudio(String deviceSerial) async {
    try {
      await repository.stopAudioStream(deviceSerial);
    } catch (e, stack) {
      AppLogger.warning(
        'Failed to stop audio stream for $deviceSerial',
        error: e,
        stackTrace: stack,
      );
    }

    if (!isClosed) {
      emit(const AudioInitial());
    }
  }

  /// Sets audio playback volume (0.0 to 1.0).
  Future<void> setVolume(double volume) async {
    final current = state;
    if (current is AudioActive) {
      await repository.setVolume(volume);
      final updated = current.audioStream.copyWith(volume: volume);
      if (!isClosed) {
        emit(AudioActive(audioStream: updated));
      }
    }
  }

  /// Toggles mute status on or off.
  Future<void> toggleMute() async {
    final current = state;
    if (current is AudioActive) {
      final isMuted = await repository.toggleMute();
      final updated = current.audioStream.copyWith(isMuted: isMuted);
      if (!isClosed) {
        emit(AudioActive(audioStream: updated));
      }
    }
  }

  @override
  Future<void> close() {
    final current = state;
    if (current is AudioActive) {
      repository.stopAudioStream(current.audioStream.deviceId);
    }
    return super.close();
  }
}
