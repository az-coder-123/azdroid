#include <atomic>
#include <thread>
#include <vector>

#include "scrcpy_core/latest_frame_buffer.h"
#include "scrcpy_core/nv12_converter.h"
#include "test_harness.h"

using namespace scrcpy_core;

namespace {

// Converts a uniform 2x2 NV12 image and returns the first output pixel.
std::vector<uint8_t> ConvertUniform(uint8_t y, uint8_t u, uint8_t v,
                                    PixelOrder order = PixelOrder::kBgra) {
  const uint8_t y_plane[4] = {y, y, y, y};
  const uint8_t uv_plane[2] = {u, v};
  Nv12Image image{y_plane, 2, uv_plane, 2, 2, 2};
  std::vector<uint8_t> bgra(16, 0);
  ConvertNv12(image, order, bgra.data(), 8);
  return {bgra[0], bgra[1], bgra[2], bgra[3]};
}

bool Near(uint8_t actual, int expected) {
  const int diff = static_cast<int>(actual) - expected;
  return diff >= -1 && diff <= 1;
}

}  // namespace

SCRCPY_TEST(Nv12LimitedRangeBlackAndWhite) {
  const auto black = ConvertUniform(16, 128, 128);
  EXPECT_EQ(black, (std::vector<uint8_t>{0, 0, 0, 255}));
  const auto white = ConvertUniform(235, 128, 128);
  EXPECT_EQ(white, (std::vector<uint8_t>{255, 255, 255, 255}));
}

SCRCPY_TEST(Nv12Bt709PrimaryRed) {
  // BT.709 limited-range red: Y=63, U=102, V=240 -> BGRA ~ (0, 0, 255).
  const auto red = ConvertUniform(63, 102, 240);
  EXPECT_TRUE(Near(red[0], 0));
  EXPECT_TRUE(Near(red[1], 0));
  EXPECT_TRUE(red[2] >= 253);
}

SCRCPY_TEST(Nv12RgbaOrderPutsRedFirst) {
  const auto red = ConvertUniform(63, 102, 240, PixelOrder::kRgba);
  EXPECT_TRUE(red[0] >= 253);
  EXPECT_TRUE(Near(red[2], 0));
  EXPECT_EQ(red[3], 255);
}

SCRCPY_TEST(Nv12HonorsStridesAndOddWidth) {
  // 3x1 image with padded rows: the padding bytes must be ignored.
  const uint8_t y_plane[8] = {16, 126, 235, 99, 99, 99, 99, 99};
  const uint8_t uv_plane[8] = {128, 128, 128, 128, 7, 7, 7, 7};
  Nv12Image image{y_plane, 8, uv_plane, 8, 3, 1};
  std::vector<uint8_t> bgra(3 * 4 + 4, 0xEE);
  ConvertNv12(image, PixelOrder::kBgra, bgra.data(), 3 * 4 + 4);
  EXPECT_EQ(bgra[0], 0);
  EXPECT_EQ(bgra[8], 255);
  EXPECT_EQ(bgra[12], 0xEE);  // Row padding untouched.
}

SCRCPY_TEST(FrameBufferReturnsNullBeforeFirstPublish) {
  LatestFrameBuffer buffer;
  EXPECT_TRUE(buffer.Acquire() == nullptr);
}

SCRCPY_TEST(FrameBufferHandsOutNewestFrame) {
  LatestFrameBuffer buffer;
  for (uint8_t value = 1; value <= 3; ++value) {
    PixelFrame& frame = buffer.BeginWrite(2, 1);
    frame.pixels.assign(frame.pixels.size(), value);
    buffer.Publish();
  }
  const PixelFrame* frame = buffer.Acquire();
  EXPECT_TRUE(frame != nullptr);
  EXPECT_EQ(frame->pixels[0], 3);
  EXPECT_EQ(frame->stride(), size_t{8});
  // Without a new publish the same frame is returned again.
  EXPECT_EQ(buffer.Acquire(), frame);
}

SCRCPY_TEST(FrameBufferClearForgetsFrames) {
  LatestFrameBuffer buffer;
  buffer.BeginWrite(1, 1);
  buffer.Publish();
  buffer.Clear();
  EXPECT_TRUE(buffer.Acquire() == nullptr);
}

SCRCPY_TEST(FrameBufferNeverExposesTornFrames) {
  // The producer fills each frame with one value; any mixed frame the
  // consumer sees would mean it read a frame while it was being written.
  LatestFrameBuffer buffer;
  std::atomic<bool> done{false};
  std::atomic<int> torn{0};

  std::thread producer([&] {
    for (int i = 0; i < 20000; ++i) {
      PixelFrame& frame = buffer.BeginWrite(64, 16);
      frame.pixels.assign(frame.pixels.size(), static_cast<uint8_t>(i));
      buffer.Publish();
    }
    done = true;
  });

  while (!done) {
    if (const PixelFrame* frame = buffer.Acquire()) {
      const uint8_t first = frame->pixels.front();
      for (uint8_t value : frame->pixels) {
        if (value != first) {
          ++torn;
          break;
        }
      }
    }
  }
  producer.join();
  EXPECT_EQ(torn.load(), 0);
}
