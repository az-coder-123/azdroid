#include "scrcpy_core/audio_state.h"

namespace scrcpy_core {

const char* AudioStateName(AudioState state) {
  switch (state) {
    case AudioState::kIdle:
      return "idle";
    case AudioState::kConnecting:
      return "connecting";
    case AudioState::kPlaying:
      return "playing";
    case AudioState::kDisabled:
      return "disabled";
    case AudioState::kFailed:
      return "failed";
    case AudioState::kEnded:
      return "ended";
  }
  return "idle";
}

}  // namespace scrcpy_core
