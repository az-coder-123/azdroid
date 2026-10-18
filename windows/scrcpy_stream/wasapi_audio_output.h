// Plays a scrcpy_core::PcmJitterBuffer on the default Windows output device
// through WASAPI (shared mode, event driven). Contract:
// docs/native-audio-contract.md. Counterpart of macOS ScrcpyAudioOutput.
#ifndef SCRCPY_STREAM_WASAPI_AUDIO_OUTPUT_H_
#define SCRCPY_STREAM_WASAPI_AUDIO_OUTPUT_H_

#include <windows.h>

#include <atomic>
#include <future>
#include <memory>
#include <thread>

#include "scrcpy_core/pcm_jitter_buffer.h"

namespace scrcpy_stream {

class WasapiAudioOutput {
 public:
  explicit WasapiAudioOutput(std::shared_ptr<scrcpy_core::PcmJitterBuffer> buffer);
  ~WasapiAudioOutput();
  WasapiAudioOutput(const WasapiAudioOutput&) = delete;
  WasapiAudioOutput& operator=(const WasapiAudioOutput&) = delete;

  // Opens the default device on the render thread. Returns false when no
  // device could be opened; the thread then ends on its own.
  bool Start();

  // Stops rendering and waits for the render thread. Safe to call twice.
  void Stop();

 private:
  void Run(std::promise<bool> opened);

  // Opens the default device and renders until Stop() or a device error
  // (for example the device was removed). Returns false on an open or device
  // error, so Run() reopens. Fulfils [opened] once, after the first open.
  bool RenderOnce(HANDLE ready_event, std::promise<bool>& opened, bool& reported);

  const std::shared_ptr<scrcpy_core::PcmJitterBuffer> buffer_;
  std::atomic<bool> running_{false};
  HANDLE stop_event_ = nullptr;
  std::thread thread_;
};

}  // namespace scrcpy_stream

#endif  // SCRCPY_STREAM_WASAPI_AUDIO_OUTPUT_H_
