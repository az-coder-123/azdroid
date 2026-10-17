// NV12 (Y plane + interleaved UV plane, 4:2:0) to 32-bit RGBA/BGRA conversion.
//
// Uses ITU-R BT.709 limited range (Y 16..235, UV 16..240), the colorimetry
// Android hardware encoders emit and the macOS pipeline tags on its buffers.
#ifndef SCRCPY_CORE_NV12_CONVERTER_H_
#define SCRCPY_CORE_NV12_CONVERTER_H_

#include <cstddef>
#include <cstdint>

namespace scrcpy_core {

struct Nv12Image {
  const uint8_t* y_plane = nullptr;
  size_t y_stride = 0;
  const uint8_t* uv_plane = nullptr;
  size_t uv_stride = 0;
  uint32_t width = 0;
  uint32_t height = 0;
};

// Byte order of one 32-bit output pixel.
//   kRgba: Flutter Windows pixel-buffer textures.
//   kBgra: CoreVideo / DXGI B8G8R8A8 surfaces.
enum class PixelOrder { kRgba, kBgra };

// Writes width x height pixels (alpha = 255) in [order] into [out], whose rows
// are [out_stride] bytes apart. [out_stride] must be at least width * 4.
void ConvertNv12(const Nv12Image& source, PixelOrder order, uint8_t* out,
                 size_t out_stride);

}  // namespace scrcpy_core

#endif  // SCRCPY_CORE_NV12_CONVERTER_H_
