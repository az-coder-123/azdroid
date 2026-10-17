#include "frame_texture.h"

namespace scrcpy_stream {

FrameTexture::FrameTexture()
    : frames_(std::make_shared<scrcpy_core::LatestFrameBuffer>()) {
  variant_ = std::make_unique<flutter::TextureVariant>(flutter::PixelBufferTexture(
      [this](size_t width, size_t height) { return CopyPixelBuffer(width, height); }));
}

const FlutterDesktopPixelBuffer* FrameTexture::CopyPixelBuffer(size_t /*width*/,
                                                              size_t /*height*/) {
  // The frame stays valid until the next Acquire(), which only this raster
  // callback performs, so no release callback is needed.
  const scrcpy_core::PixelFrame* frame = frames_->Acquire();
  if (frame == nullptr || frame->empty()) {
    return nullptr;
  }
  descriptor_.buffer = frame->pixels.data();
  descriptor_.width = frame->width;
  descriptor_.height = frame->height;
  descriptor_.release_callback = nullptr;
  descriptor_.release_context = nullptr;
  return &descriptor_;
}

}  // namespace scrcpy_stream
