// Lock-light triple buffer that always hands the consumer the newest
// complete 32-bit-per-pixel frame (RGBA or BGRA, chosen by the producer).
//
// One producer (the decoder thread) writes into a private "back" frame and
// publishes it. One consumer (the Flutter raster thread) acquires the newest
// published frame and may read it until its next Acquire call. Neither side
// waits for the other beyond a short index swap, and a frame is never read
// while it is being written.
#ifndef SCRCPY_CORE_LATEST_FRAME_BUFFER_H_
#define SCRCPY_CORE_LATEST_FRAME_BUFFER_H_

#include <array>
#include <cstddef>
#include <cstdint>
#include <mutex>
#include <vector>

namespace scrcpy_core {

struct PixelFrame {
  std::vector<uint8_t> pixels;
  uint32_t width = 0;
  uint32_t height = 0;

  size_t stride() const { return static_cast<size_t>(width) * 4; }
  bool empty() const { return width == 0 || height == 0; }
};

class LatestFrameBuffer {
 public:
  LatestFrameBuffer() = default;
  LatestFrameBuffer(const LatestFrameBuffer&) = delete;
  LatestFrameBuffer& operator=(const LatestFrameBuffer&) = delete;

  // Producer: returns the back frame resized to width x height. Only the
  // producer thread may touch it until Publish(). No lock is needed because
  // only Publish() (also producer-only) changes which slot is "back".
  PixelFrame& BeginWrite(uint32_t width, uint32_t height);

  // Producer: makes the back frame the newest available frame.
  void Publish();

  // Consumer: returns the newest published frame, or nullptr before the
  // first Publish(). The frame stays valid until the next Acquire().
  const PixelFrame* Acquire();

  // Drops all frames. Call only after the producer thread has stopped.
  void Clear();

 private:
  std::mutex mutex_;
  std::array<PixelFrame, 3> frames_;
  size_t back_ = 0;
  size_t ready_ = 1;
  size_t front_ = 2;
  bool has_new_frame_ = false;
  bool has_any_frame_ = false;
};

}  // namespace scrcpy_core

#endif  // SCRCPY_CORE_LATEST_FRAME_BUFFER_H_
