import 'package:desk_droid/features/audio/domain/entities/audio_playback.dart';

/// Tooltip text for audio that is not playing.
extension AudioStatusLabel on AudioPlaybackStatus {
  String get label => switch (this) {
    AudioPlaybackStatus.starting => 'Audio Starting…',
    AudioPlaybackStatus.playing => 'Audio Playing',
    AudioPlaybackStatus.unavailableOnDevice =>
      'No Audio: the phone needs Android 11 or newer',
    AudioPlaybackStatus.unavailableOnHost =>
      'No Audio: not supported on this computer yet',
    AudioPlaybackStatus.failed => 'Audio Failed (see the app log)',
    AudioPlaybackStatus.ended => 'Audio Stopped by the Phone',
  };
}
