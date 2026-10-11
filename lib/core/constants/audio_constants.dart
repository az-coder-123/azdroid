/// Configuration parameters for Android 10+ low-latency audio capture and streaming.
class AudioConstants {
  const AudioConstants._();

  /// Default audio capture sample rate in Hz.
  static const int defaultSampleRate = 48000;

  /// Default channel count (2 for stereo, 1 for mono).
  static const int defaultChannels = 2;

  /// Default Opus/AAC audio bitrate in kilobits per second.
  static const int defaultAudioBitrateKbps = 128;

  /// Standard audio codec used by scrcpy (opus, aac, or raw).
  static const String defaultAudioCodec = 'opus';

  /// Default initial playback volume (1.0 = 100%).
  static const double defaultVolume = 1.0;

  /// Minimum volume bound.
  static const double minVolume = 0.0;

  /// Maximum volume bound.
  static const double maxVolume = 1.0;
}
