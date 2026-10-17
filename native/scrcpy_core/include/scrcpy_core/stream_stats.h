// Lifecycle state and cumulative counters for one video stream.
//
// The stream thread records events; the platform thread reads a snapshot for
// the `getStats` channel method. Counters only grow, so the Dart side derives
// rates (FPS, bitrate, latency) from the difference between two snapshots.
// Contract: docs/native-video-contract.md.
#ifndef SCRCPY_CORE_STREAM_STATS_H_
#define SCRCPY_CORE_STREAM_STATS_H_

#include <atomic>
#include <cstdint>

namespace scrcpy_core {

enum class StreamState : uint8_t {
  kIdle,        // No stream, or stopped by the caller.
  kConnecting,  // Waiting for the socket and the stream header.
  kStreaming,   // Header received; packets are flowing.
  kFailed,      // Gave up before streaming (no server, bad header, decoder).
  kEnded,       // The stream closed by itself after it had started.
};

// Wire name used by the MethodChannel: "idle", "connecting", ...
const char* StreamStateName(StreamState state);

struct StreamStatsSnapshot {
  StreamState state = StreamState::kIdle;
  uint64_t frames_decoded = 0;
  uint64_t bytes_received = 0;
  // Sum over all frames of the time from "packet fully received" to
  // "frame published", in microseconds.
  uint64_t processing_time_us = 0;
};

class StreamStats {
 public:
  void SetState(StreamState state) { state_.store(state); }
  StreamState state() const { return state_.load(); }

  void AddBytes(uint64_t bytes) { bytes_received_ += bytes; }

  // Records one published frame and its host processing time.
  void AddFrame(uint64_t processing_time_us) {
    processing_time_us_ += processing_time_us;
    ++frames_decoded_;
  }

  StreamStatsSnapshot Snapshot() const;

 private:
  std::atomic<StreamState> state_{StreamState::kIdle};
  std::atomic<uint64_t> frames_decoded_{0};
  std::atomic<uint64_t> bytes_received_{0};
  std::atomic<uint64_t> processing_time_us_{0};
};

}  // namespace scrcpy_core

#endif  // SCRCPY_CORE_STREAM_STATS_H_
