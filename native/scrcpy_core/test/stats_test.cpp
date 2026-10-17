#include <string>
#include <thread>
#include <vector>

#include "scrcpy_core/stream_stats.h"
#include "test_harness.h"

using namespace scrcpy_core;

SCRCPY_TEST(StreamStatsStartsIdleAndEmpty) {
  const StreamStats stats;
  const StreamStatsSnapshot snapshot = stats.Snapshot();
  EXPECT_TRUE(snapshot.state == StreamState::kIdle);
  EXPECT_EQ(snapshot.frames_decoded, 0u);
  EXPECT_EQ(snapshot.bytes_received, 0u);
  EXPECT_EQ(snapshot.processing_time_us, 0u);
}

SCRCPY_TEST(StreamStatsAccumulatesCounters) {
  StreamStats stats;
  stats.SetState(StreamState::kStreaming);
  stats.AddBytes(1200);
  stats.AddBytes(300);
  stats.AddFrame(4000);
  stats.AddFrame(6000);

  const StreamStatsSnapshot snapshot = stats.Snapshot();
  EXPECT_TRUE(snapshot.state == StreamState::kStreaming);
  EXPECT_EQ(snapshot.bytes_received, 1500u);
  EXPECT_EQ(snapshot.frames_decoded, 2u);
  EXPECT_EQ(snapshot.processing_time_us, 10000u);
}

SCRCPY_TEST(StreamStateNamesMatchChannelContract) {
  EXPECT_EQ(std::string(StreamStateName(StreamState::kIdle)), "idle");
  EXPECT_EQ(std::string(StreamStateName(StreamState::kConnecting)), "connecting");
  EXPECT_EQ(std::string(StreamStateName(StreamState::kStreaming)), "streaming");
  EXPECT_EQ(std::string(StreamStateName(StreamState::kFailed)), "failed");
  EXPECT_EQ(std::string(StreamStateName(StreamState::kEnded)), "ended");
}

// Namespace scope: MSVC requires capturing local constants used in lambdas.
namespace {
constexpr int kThreads = 4;
constexpr int kFramesPerThread = 1000;
}  // namespace

SCRCPY_TEST(StreamStatsCountsFromConcurrentWriters) {
  StreamStats stats;
  std::vector<std::thread> writers;
  for (int t = 0; t < kThreads; ++t) {
    writers.emplace_back([&stats] {
      for (int i = 0; i < kFramesPerThread; ++i) {
        stats.AddFrame(1);
        stats.AddBytes(2);
      }
    });
  }
  for (auto& writer : writers) writer.join();

  const StreamStatsSnapshot snapshot = stats.Snapshot();
  EXPECT_EQ(snapshot.frames_decoded, 4000u);
  EXPECT_EQ(snapshot.bytes_received, 8000u);
  EXPECT_EQ(snapshot.processing_time_us, 4000u);
}
