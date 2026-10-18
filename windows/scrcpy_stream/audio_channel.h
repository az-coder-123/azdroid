// Windows implementation of the `com.deskdroid/audio_stream` MethodChannel.
// Contract: docs/native-audio-contract.md (shared with macOS
// ScrcpyAudioPlugin). Owns the jitter buffer, so volume and mute survive
// sessions, and the current AudioSession.
#ifndef SCRCPY_STREAM_AUDIO_CHANNEL_H_
#define SCRCPY_STREAM_AUDIO_CHANNEL_H_

#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>

#include <memory>

#include "audio_session.h"
#include "scrcpy_core/audio_state.h"
#include "scrcpy_core/pcm_jitter_buffer.h"

namespace scrcpy_stream {

class AudioChannel {
 public:
  explicit AudioChannel(flutter::BinaryMessenger* messenger);
  ~AudioChannel();
  AudioChannel(const AudioChannel&) = delete;
  AudioChannel& operator=(const AudioChannel&) = delete;

 private:
  using MethodResult = flutter::MethodResult<flutter::EncodableValue>;

  void HandleMethodCall(const flutter::MethodCall<flutter::EncodableValue>& call,
                        std::unique_ptr<MethodResult> result);
  bool StartAudio(const flutter::EncodableMap* args);
  void StopAudio();
  flutter::EncodableValue Stats() const;

  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
  const std::shared_ptr<scrcpy_core::PcmJitterBuffer> buffer_;
  std::unique_ptr<AudioSession> session_;
  // Reported when no session exists (for example after a failed connect).
  scrcpy_core::AudioState idle_state_ = scrcpy_core::AudioState::kIdle;
};

}  // namespace scrcpy_stream

#endif  // SCRCPY_STREAM_AUDIO_CHANNEL_H_
