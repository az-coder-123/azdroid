// Audio player state reported by `getAudioStats` on every platform
// (docs/native-audio-contract.md). The macOS Swift plugin mirrors these names.
#ifndef SCRCPY_CORE_AUDIO_STATE_H_
#define SCRCPY_CORE_AUDIO_STATE_H_

namespace scrcpy_core {

enum class AudioState {
  kIdle,        // No audio, or stopped by the caller.
  kConnecting,  // Socket open, waiting for the audio header.
  kPlaying,     // Raw PCM header received; output running.
  kDisabled,    // The device cannot capture audio (Android 10 or older).
  kFailed,      // Configuration error, unsupported codec, or no output.
  kEnded,       // The device closed the socket after playback started.
};

// Stable lowercase name used by the channel contract.
const char* AudioStateName(AudioState state);

}  // namespace scrcpy_core

#endif  // SCRCPY_CORE_AUDIO_STATE_H_
