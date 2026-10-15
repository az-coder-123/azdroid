import 'package:desk_droid/features/audio/domain/entities/audio_stream_entity.dart';

/// Abstract contract managing audio stream lifecycle, volume, and playback state.
abstract class AudioRepository {
  /// Initiates audio capture daemon tunneling and socket connection.
  Future<AudioStreamEntity> startAudioStream(
    String deviceSerial, {
    int? sampleRate,
    int? channels,
    String? codec,
  });

  /// Terminates audio capture and disposes local audio socket handles.
  Future<void> stopAudioStream(String deviceSerial);

  /// Sets audio playback volume output (0.0 to 1.0).
  Future<void> setVolume(double volume);

  /// Toggles host mute state.
  Future<bool> toggleMute();
}
