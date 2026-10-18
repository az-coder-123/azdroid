// One audio connection: socket -> scrcpy audio header and packets -> shared
// jitter buffer -> WASAPI output. Runs on its own thread. Contract:
// docs/native-audio-contract.md. Counterpart of macOS ScrcpyAudioSession.
#ifndef SCRCPY_STREAM_AUDIO_SESSION_H_
#define SCRCPY_STREAM_AUDIO_SESSION_H_

#include <atomic>
#include <cstdint>
#include <memory>
#include <mutex>
#include <string>
#include <thread>

#include "scrcpy_core/audio_state.h"
#include "scrcpy_core/pcm_jitter_buffer.h"
#include "wasapi_audio_output.h"
#include "winsock_connection.h"

namespace scrcpy_stream {

class AudioSession {
 public:
  explicit AudioSession(std::shared_ptr<scrcpy_core::PcmJitterBuffer> buffer);
  ~AudioSession();
  AudioSession(const AudioSession&) = delete;
  AudioSession& operator=(const AudioSession&) = delete;

  // Connects to the forwarded port; returns true once connected, then reads
  // and plays on the session thread.
  bool Start(const std::string& host, uint16_t port);

  // After this returns, the session no longer touches the buffer.
  void Stop();

  scrcpy_core::AudioState state() const { return state_; }
  uint64_t bytes_received() const { return bytes_received_; }

 private:
  void Run();
  void Report(scrcpy_core::AudioState state);
  // Pushes under push_mutex_, so nothing lands after Stop().
  void Push(const uint8_t* data, size_t size);

  const std::shared_ptr<scrcpy_core::PcmJitterBuffer> buffer_;
  std::atomic<bool> running_{false};
  std::atomic<scrcpy_core::AudioState> state_{scrcpy_core::AudioState::kIdle};
  std::atomic<uint64_t> bytes_received_{0};
  std::mutex push_mutex_;
  WinsockScope winsock_;
  WinsockConnection connection_;
  std::unique_ptr<WasapiAudioOutput> output_;  // Session thread only.
  std::thread thread_;
};

}  // namespace scrcpy_stream

#endif  // SCRCPY_STREAM_AUDIO_SESSION_H_
