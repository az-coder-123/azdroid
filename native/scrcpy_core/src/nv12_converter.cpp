#include "scrcpy_core/nv12_converter.h"

namespace scrcpy_core {

namespace {

// BT.709 limited-range coefficients in 8.8 fixed point:
//   R = 1.164 (Y-16)                 + 1.793 (V-128)
//   G = 1.164 (Y-16) - 0.213 (U-128) - 0.533 (V-128)
//   B = 1.164 (Y-16) + 2.112 (U-128)
constexpr int kYScale = 298;
constexpr int kVToR = 459;
constexpr int kUToG = 55;
constexpr int kVToG = 136;
constexpr int kUToB = 541;
constexpr int kRound = 128;
constexpr int kShift = 8;

uint8_t ClampToByte(int value) {
  if (value < 0) return 0;
  if (value > 255) return 255;
  return static_cast<uint8_t>(value);
}

}  // namespace

void ConvertNv12(const Nv12Image& source, PixelOrder order, uint8_t* out_base,
                 size_t out_stride) {
  // Byte offsets of red and blue inside one output pixel.
  const size_t red = order == PixelOrder::kRgba ? 0 : 2;
  const size_t blue = 2 - red;

  for (uint32_t row = 0; row < source.height; ++row) {
    const uint8_t* y_row = source.y_plane + row * source.y_stride;
    const uint8_t* uv_row = source.uv_plane + (row / 2) * source.uv_stride;
    uint8_t* out = out_base + row * out_stride;

    for (uint32_t col = 0; col < source.width; ++col) {
      const int y = kYScale * (static_cast<int>(y_row[col]) - 16);
      const size_t uv_index = (col / 2) * 2;
      const int u = static_cast<int>(uv_row[uv_index]) - 128;
      const int v = static_cast<int>(uv_row[uv_index + 1]) - 128;

      out[blue] = ClampToByte((y + kUToB * u + kRound) >> kShift);
      out[1] = ClampToByte((y - kUToG * u - kVToG * v + kRound) >> kShift);
      out[red] = ClampToByte((y + kVToR * v + kRound) >> kShift);
      out[3] = 255;
      out += 4;
    }
  }
}

}  // namespace scrcpy_core
