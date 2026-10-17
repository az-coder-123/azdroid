#include "scrcpy_core/latest_frame_buffer.h"

#include <utility>

namespace scrcpy_core {

PixelFrame& LatestFrameBuffer::BeginWrite(uint32_t width, uint32_t height) {
  PixelFrame& frame = frames_[back_];
  frame.width = width;
  frame.height = height;
  frame.pixels.resize(static_cast<size_t>(width) * height * 4);
  return frame;
}

void LatestFrameBuffer::Publish() {
  std::lock_guard<std::mutex> lock(mutex_);
  std::swap(back_, ready_);
  has_new_frame_ = true;
  has_any_frame_ = true;
}

const PixelFrame* LatestFrameBuffer::Acquire() {
  std::lock_guard<std::mutex> lock(mutex_);
  if (has_new_frame_) {
    std::swap(front_, ready_);
    has_new_frame_ = false;
  }
  return has_any_frame_ ? &frames_[front_] : nullptr;
}

void LatestFrameBuffer::Clear() {
  std::lock_guard<std::mutex> lock(mutex_);
  for (PixelFrame& frame : frames_) {
    frame = PixelFrame{};
  }
  has_new_frame_ = false;
  has_any_frame_ = false;
}

}  // namespace scrcpy_core
