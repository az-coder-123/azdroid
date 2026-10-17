// Flutter pixel-buffer texture that shows the newest frame from a
// LatestFrameBuffer.
//
// Owned through std::shared_ptr: the plugin hands its last reference to
// TextureRegistrar::UnregisterTexture's callback, so the engine can never
// read the buffer after it is freed.
#ifndef SCRCPY_STREAM_FRAME_TEXTURE_H_
#define SCRCPY_STREAM_FRAME_TEXTURE_H_

#include <flutter/texture_registrar.h>

#include <memory>

#include "scrcpy_core/latest_frame_buffer.h"

namespace scrcpy_stream {

class FrameTexture {
 public:
  FrameTexture();
  FrameTexture(const FrameTexture&) = delete;
  FrameTexture& operator=(const FrameTexture&) = delete;

  flutter::TextureVariant* variant() { return variant_.get(); }
  const std::shared_ptr<scrcpy_core::LatestFrameBuffer>& frames() const {
    return frames_;
  }

 private:
  // Raster-thread callback: returns the newest frame, or nullptr before the
  // first decoded frame (the engine then keeps the previous contents).
  const FlutterDesktopPixelBuffer* CopyPixelBuffer(size_t width, size_t height);

  std::shared_ptr<scrcpy_core::LatestFrameBuffer> frames_;
  FlutterDesktopPixelBuffer descriptor_ = {};
  std::unique_ptr<flutter::TextureVariant> variant_;
};

}  // namespace scrcpy_stream

#endif  // SCRCPY_STREAM_FRAME_TEXTURE_H_
