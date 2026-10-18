#include <atomic>
#include <cmath>
#include <cstdint>
#include <string>
#include <thread>
#include <vector>

#include "scrcpy_core/audio_c_api.h"
#include "scrcpy_core/audio_header.h"
#include "scrcpy_core/audio_state.h"
#include "scrcpy_core/pcm_jitter_buffer.h"
#include "test_harness.h"

using namespace scrcpy_core;

namespace {

// 1 kHz keeps the numbers readable: 50 ms target = 50 frames, 200 ms max =
// 200 frames.
constexpr uint32_t kRate = 1000;
constexpr uint32_t kStereo = 2;

// Little-endian bytes of interleaved stereo frames whose left sample is
// [first + i] and right sample is -(first + i).
std::vector<uint8_t> Frames(int first, int count) {
  std::vector<uint8_t> bytes;
  for (int i = 0; i < count; ++i) {
    for (const int value : {first + i, -(first + i)}) {
      const auto sample = static_cast<uint16_t>(static_cast<int16_t>(value));
      bytes.push_back(static_cast<uint8_t>(sample & 0xFF));
      bytes.push_back(static_cast<uint8_t>(sample >> 8));
    }
  }
  return bytes;
}

float Pcm(int value) { return static_cast<float>(value) / 32768.0f; }

bool AllZero(const std::vector<float>& values) {
  for (const float v : values) {
    if (v != 0.0f) return false;
  }
  return true;
}

}  // namespace

SCRCPY_TEST(AudioHeaderRecognizesEveryStreamKind) {
  const uint8_t raw[] = {0x00, 'r', 'a', 'w'};
  const uint8_t disabled[] = {0, 0, 0, 0};
  const uint8_t error[] = {0, 0, 0, 1};
  const uint8_t opus[] = {'o', 'p', 'u', 's'};
  EXPECT_TRUE(ParseAudioHeader(raw, 4)->kind == AudioStreamKind::kRaw);
  EXPECT_TRUE(ParseAudioHeader(disabled, 4)->kind == AudioStreamKind::kDisabled);
  EXPECT_TRUE(ParseAudioHeader(error, 4)->kind == AudioStreamKind::kConfigError);
  EXPECT_TRUE(ParseAudioHeader(opus, 4)->kind ==
              AudioStreamKind::kUnsupportedCodec);
  EXPECT_EQ(ParseAudioHeader(opus, 4)->codec_id, 0x6f707573u);
  EXPECT_TRUE(!ParseAudioHeader(raw, 3).has_value());
  EXPECT_EQ(std::string(AudioStreamKindName(AudioStreamKind::kDisabled)),
            "disabled");
}

SCRCPY_TEST(JitterBufferStaysSilentUntilTargetIsBuffered) {
  PcmJitterBuffer buffer(kRate, kStereo, 50, 200);
  const auto bytes = Frames(1, 49);
  buffer.Push(bytes.data(), bytes.size());
  std::vector<float> out(10 * kStereo, 1.0f);
  buffer.ReadInterleaved(out.data(), 10);
  EXPECT_TRUE(AllZero(out));
  EXPECT_EQ(buffer.Stats().played_frames, 0u);
  EXPECT_EQ(buffer.Stats().buffered_frames, 49u);
}

SCRCPY_TEST(JitterBufferPlaysInOrderOnceTargetIsReached) {
  PcmJitterBuffer buffer(kRate, kStereo, 50, 200);
  const auto bytes = Frames(1, 50);
  buffer.Push(bytes.data(), bytes.size());
  std::vector<float> out(3 * kStereo);
  buffer.ReadInterleaved(out.data(), 3);
  EXPECT_EQ(out[0], Pcm(1));
  EXPECT_EQ(out[1], Pcm(-1));
  EXPECT_EQ(out[4], Pcm(3));
  EXPECT_EQ(out[5], Pcm(-3));
  EXPECT_EQ(buffer.Stats().played_frames, 3u);
  EXPECT_EQ(buffer.Stats().buffered_frames, 47u);
}

SCRCPY_TEST(JitterBufferJoinsSamplesSplitAcrossPushes) {
  PcmJitterBuffer buffer(kRate, kStereo, 1, 200);
  const auto bytes = Frames(300, 2);  // 8 bytes: split after 3 and 5.
  buffer.Push(bytes.data(), 3);
  buffer.Push(bytes.data() + 3, 2);
  buffer.Push(bytes.data() + 5, 3);
  EXPECT_EQ(buffer.Stats().pushed_frames, 2u);
  std::vector<float> out(2 * kStereo);
  buffer.ReadInterleaved(out.data(), 2);
  EXPECT_EQ(out[0], Pcm(300));
  EXPECT_EQ(out[1], Pcm(-300));
  EXPECT_EQ(out[2], Pcm(301));
  EXPECT_EQ(out[3], Pcm(-301));
}

SCRCPY_TEST(JitterBufferCountsUnderrunAndPrimesAgain) {
  PcmJitterBuffer buffer(kRate, kStereo, 50, 200);
  const auto first = Frames(1, 50);
  buffer.Push(first.data(), first.size());
  std::vector<float> out(60 * kStereo);
  buffer.ReadInterleaved(out.data(), 60);
  EXPECT_EQ(buffer.Stats().underruns, 1u);
  EXPECT_EQ(out[49 * kStereo], Pcm(50));
  EXPECT_EQ(out[50 * kStereo], 0.0f);  // Silence after the last frame.

  // Priming again: 10 frames are not enough to resume.
  const auto little = Frames(100, 10);
  buffer.Push(little.data(), little.size());
  std::vector<float> next(5 * kStereo, 1.0f);
  buffer.ReadInterleaved(next.data(), 5);
  EXPECT_TRUE(AllZero(next));
  EXPECT_EQ(buffer.Stats().underruns, 1u);
}

SCRCPY_TEST(JitterBufferDropsOldestAudioDownToTargetOnOverflow) {
  PcmJitterBuffer buffer(kRate, kStereo, 50, 200);
  const auto bytes = Frames(1, 201);
  buffer.Push(bytes.data(), bytes.size());
  const PcmJitterStats stats = buffer.Stats();
  EXPECT_EQ(stats.buffered_frames, 50u);
  EXPECT_EQ(stats.dropped_frames, 151u);
  std::vector<float> out(1 * kStereo);
  buffer.ReadInterleaved(out.data(), 1);
  EXPECT_EQ(out[0], Pcm(152));  // The newest 50 frames remain.
}

SCRCPY_TEST(JitterBufferTrimsLatencyThatStaysAboveTarget) {
  // 1 kHz: target 50 frames, tolerance 20 ms = 20 frames, window 1000.
  PcmJitterBuffer buffer(kRate, kStereo, 50, 200);
  const auto start = Frames(1, 150);  // 150 ms queued, below the 200 max.
  buffer.Push(start.data(), start.size());
  std::vector<float> out(10 * kStereo);
  // Steady flow: 10 in, 10 out. The fill stays at about 150 frames.
  for (int i = 0; i < 100; ++i) {
    const auto chunk = Frames(1000, 10);
    buffer.Push(chunk.data(), chunk.size());
    buffer.ReadInterleaved(out.data(), 10);
  }
  const PcmJitterStats stats = buffer.Stats();
  EXPECT_EQ(stats.underruns, 0u);
  EXPECT_EQ(stats.buffered_frames, 50u);  // Back at the target.
  EXPECT_EQ(stats.dropped_frames, 100u);
}

SCRCPY_TEST(JitterBufferKeepsLatencyWhenOnlyJitterIsAbove) {
  PcmJitterBuffer buffer(kRate, kStereo, 50, 200);
  const auto start = Frames(1, 60);
  buffer.Push(start.data(), start.size());
  std::vector<float> out(40 * kStereo);
  // Bursty arrival: 40 frames every 4th read of 10. The minimum fill dips
  // near the target, so nothing is trimmed.
  for (int i = 0; i < 100; ++i) {
    if (i % 4 == 0) {
      const auto chunk = Frames(1000, 40);
      buffer.Push(chunk.data(), chunk.size());
    }
    buffer.ReadInterleaved(out.data(), 10);
  }
  EXPECT_EQ(buffer.Stats().dropped_frames, 0u);
}

SCRCPY_TEST(JitterBufferAppliesGainAndMute) {
  PcmJitterBuffer buffer(kRate, kStereo, 1, 200);
  const auto bytes = Frames(1000, 4);
  buffer.Push(bytes.data(), bytes.size());
  buffer.SetGain(0.5f);
  std::vector<float> out(1 * kStereo);
  buffer.ReadInterleaved(out.data(), 1);
  EXPECT_EQ(out[0], Pcm(1000) * 0.5f);
  buffer.SetGain(3.0f);  // Clamped to 1.
  buffer.ReadInterleaved(out.data(), 1);
  EXPECT_EQ(out[0], Pcm(1001));
  buffer.SetMuted(true);
  buffer.ReadInterleaved(out.data(), 1);
  EXPECT_EQ(out[0], 0.0f);
  EXPECT_EQ(buffer.Stats().played_frames, 3u);  // Muted audio still drains.
}

SCRCPY_TEST(JitterBufferWritesPlanarChannels) {
  PcmJitterBuffer buffer(kRate, kStereo, 1, 200);
  const auto bytes = Frames(7, 2);
  buffer.Push(bytes.data(), bytes.size());
  std::vector<float> left(2), right(2);
  float* const channels[] = {left.data(), right.data()};
  buffer.ReadPlanar(channels, 2, 2);
  EXPECT_EQ(left[0], Pcm(7));
  EXPECT_EQ(left[1], Pcm(8));
  EXPECT_EQ(right[0], Pcm(-7));
  EXPECT_EQ(right[1], Pcm(-8));
}

SCRCPY_TEST(JitterBufferClearDropsAudioAndPrimes) {
  PcmJitterBuffer buffer(kRate, kStereo, 50, 200);
  const auto bytes = Frames(1, 60);
  buffer.Push(bytes.data(), bytes.size());
  buffer.Clear();
  EXPECT_EQ(buffer.Stats().buffered_frames, 0u);
  std::vector<float> out(5 * kStereo, 1.0f);
  buffer.ReadInterleaved(out.data(), 5);
  EXPECT_TRUE(AllZero(out));
}

SCRCPY_TEST(JitterBufferSurvivesConcurrentProducerAndConsumer) {
  PcmJitterBuffer buffer(48000, kStereo, 50, 200);
  std::atomic<bool> done{false};
  std::thread producer([&] {
    const auto chunk = Frames(1, 1024);
    for (int i = 0; i < 200; ++i) {
      buffer.Push(chunk.data(), chunk.size());
    }
    done = true;
  });
  std::vector<float> out(512 * kStereo);
  uint64_t reads = 0;
  while (!done) {
    buffer.ReadInterleaved(out.data(), 512);
    ++reads;
  }
  producer.join();
  const PcmJitterStats stats = buffer.Stats();
  EXPECT_EQ(stats.pushed_frames, 200u * 1024u);
  EXPECT_EQ(stats.pushed_frames,
            stats.played_frames + stats.dropped_frames + stats.buffered_frames);
  EXPECT_TRUE(reads > 0);
}

SCRCPY_TEST(AudioCApiParsesHeaderAndRoundTripsAudio) {
  const uint8_t raw[] = {0x00, 'r', 'a', 'w'};
  EXPECT_TRUE(sc_audio_parse_header(raw, 4) == SC_AUDIO_STREAM_RAW);
  EXPECT_TRUE(sc_audio_parse_header(raw, 2) == SC_AUDIO_STREAM_INVALID);
  EXPECT_EQ(sc_audio_sample_rate(), 48000u);
  EXPECT_EQ(sc_audio_channels(), 2u);

  ScAudioBuffer* buffer = sc_audio_buffer_create();
  const auto bytes = Frames(5, 2400);  // 50 ms at 48 kHz.
  sc_audio_buffer_push(buffer, bytes.data(), bytes.size());
  std::vector<float> left(1), right(1);
  float* const channels[] = {left.data(), right.data()};
  sc_audio_buffer_read_planar(buffer, channels, 2, 1);
  EXPECT_EQ(left[0], Pcm(5));
  EXPECT_EQ(right[0], Pcm(-5));
  EXPECT_EQ(sc_audio_buffer_stats(buffer).played_frames, 1u);
  sc_audio_buffer_destroy(buffer);
  sc_audio_buffer_destroy(nullptr);  // Safe.
}

SCRCPY_TEST(AudioStateNamesMatchChannelContract) {
  EXPECT_EQ(std::string(AudioStateName(AudioState::kIdle)), "idle");
  EXPECT_EQ(std::string(AudioStateName(AudioState::kConnecting)), "connecting");
  EXPECT_EQ(std::string(AudioStateName(AudioState::kPlaying)), "playing");
  EXPECT_EQ(std::string(AudioStateName(AudioState::kDisabled)), "disabled");
  EXPECT_EQ(std::string(AudioStateName(AudioState::kFailed)), "failed");
  EXPECT_EQ(std::string(AudioStateName(AudioState::kEnded)), "ended");
}
