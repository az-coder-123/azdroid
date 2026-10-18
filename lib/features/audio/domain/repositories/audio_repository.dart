import 'package:desk_droid/features/audio/domain/entities/audio_playback.dart';

/// Playback controls and state of the mirrored device's audio.
///
/// The audio socket itself is opened and closed by the streaming session,
/// because it must connect between the video and control sockets.
abstract class AudioRepository {
  /// Last volume set, 0.0 – 1.0. Kept for the app's lifetime.
  double get volume;

  /// Last mute choice. Kept for the app's lifetime.
  bool get isMuted;

  /// Emits the playback state about once per second while listened to.
  Stream<AudioPlayback> watch();

  Future<void> setVolume(double volume);

  Future<void> setMuted(bool muted);
}
