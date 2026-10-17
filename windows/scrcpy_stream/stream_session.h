// One live video stream: socket -> scrcpy framing -> H.264 decode -> RGBA
// frames in a LatestFrameBuffer. Runs on its own thread.
#ifndef SCRCPY_STREAM_STREAM_SESSION_H_
#define SCRCPY_STREAM_STREAM_SESSION_H_

#include <atomic>
#include <chrono>
#include <condition_variable>
#include <cstdint>
#include <functional>
#include <memory>
#include <mutex>
#include <optional>
#include <string>
#include <thread>

#include "scrcpy_core/latest_frame_buffer.h"
#include "scrcpy_core/nv12_converter.h"
#include "scrcpy_core/stream_header.h"
#include "scrcpy_core/stream_stats.h"
#include "winsock_connection.h"

namespace scrcpy_stream {

class StreamSession {
 public:
  // Called on the session thread after each frame is published.
  using FrameReadyCallback = std::function<void()>;

  StreamSession(std::string host, uint16_t port,
                std::shared_ptr<scrcpy_core::LatestFrameBuffer> frames,
                FrameReadyCallback on_frame_ready);
  ~StreamSession();
  StreamSession(const StreamSession&) = delete;
  StreamSession& operator=(const StreamSession&) = delete;

  void Start();

  // Stops the thread and waits for it. Safe to call more than once.
  void Stop();

  // Latest known video size (stream header, then decoded frames).
  uint32_t width() const { return width_; }
  uint32_t height() const { return height_; }

  // Lifecycle state and cumulative counters; safe to read from any thread.
  scrcpy_core::StreamStatsSnapshot stats() const { return stats_.Snapshot(); }

 private:
  void Run();
  std::optional<scrcpy_core::StreamHeader> ConnectAndReadHeader();
  // Returns false when streaming cannot start (codec or decoder failure).
  bool PumpPackets(const scrcpy_core::StreamHeader& header);
  void PublishFrame(const scrcpy_core::Nv12Image& image);

  // Sleeps up to [delay]; returns false early when the session stops.
  bool SleepWhileRunning(std::chrono::milliseconds delay);

  const std::string host_;
  const uint16_t port_;
  const std::shared_ptr<scrcpy_core::LatestFrameBuffer> frames_;
  const FrameReadyCallback on_frame_ready_;

  std::atomic<bool> running_{false};
  std::atomic<uint32_t> width_{0};
  std::atomic<uint32_t> height_{0};
  scrcpy_core::StreamStats stats_;
  // Session-thread only: when the packet being decoded was fully received.
  std::chrono::steady_clock::time_point packet_received_at_;
  WinsockConnection connection_;
  std::mutex wake_mutex_;
  std::condition_variable wake_;
  std::thread thread_;
};

}  // namespace scrcpy_stream

#endif  // SCRCPY_STREAM_STREAM_SESSION_H_
