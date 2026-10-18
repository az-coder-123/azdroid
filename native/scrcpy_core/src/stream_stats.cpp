#include "scrcpy_core/stream_stats.h"

namespace scrcpy_core {

const char* StreamStateName(StreamState state) {
  switch (state) {
    case StreamState::kIdle:
      return "idle";
    case StreamState::kConnecting:
      return "connecting";
    case StreamState::kConnected:
      return "connected";
    case StreamState::kStreaming:
      return "streaming";
    case StreamState::kFailed:
      return "failed";
    case StreamState::kEnded:
      return "ended";
  }
  return "idle";
}

StreamStatsSnapshot StreamStats::Snapshot() const {
  StreamStatsSnapshot snapshot;
  snapshot.state = state_.load();
  snapshot.frames_decoded = frames_decoded_.load();
  snapshot.bytes_received = bytes_received_.load();
  snapshot.processing_time_us = processing_time_us_.load();
  return snapshot;
}

}  // namespace scrcpy_core
