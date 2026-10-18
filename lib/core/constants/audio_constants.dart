/// Host-side audio playback settings (docs/native-audio-contract.md).
class AudioConstants {
  const AudioConstants._();

  /// Initial playback volume (1.0 = 100%).
  static const double defaultVolume = 1.0;

  /// Minimum volume bound.
  static const double minVolume = 0.0;

  /// Maximum volume bound.
  static const double maxVolume = 1.0;

  /// How often the playback state is read from the native player.
  static const Duration playbackPollInterval = Duration(seconds: 1);
}
