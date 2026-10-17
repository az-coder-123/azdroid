#include "scrcpy_core/stream_header.h"

#include <cstring>

#include "scrcpy_core/big_endian.h"

namespace scrcpy_core {

namespace {

// Copies [length] bytes as text, stopping at the first NUL byte.
std::string ReadPaddedText(const uint8_t* bytes, size_t length) {
  const void* nul = std::memchr(bytes, 0, length);
  const size_t text_length =
      nul == nullptr
          ? length
          : static_cast<size_t>(static_cast<const uint8_t*>(nul) - bytes);
  return std::string(reinterpret_cast<const char*>(bytes), text_length);
}

}  // namespace

std::optional<StreamHeader> ParseStreamHeader(const uint8_t* data, size_t size) {
  if (data == nullptr || size < kStreamHeaderSize) {
    return std::nullopt;
  }
  const uint8_t* cursor = data + 1;  // Skip the dummy byte.
  StreamHeader header;
  header.device_name = ReadPaddedText(cursor, kDeviceNameSize);
  cursor += kDeviceNameSize;
  header.codec = ReadPaddedText(cursor, kCodecIdSize);
  cursor += kCodecIdSize;
  header.width = ReadBigEndian32(cursor);
  header.height = ReadBigEndian32(cursor + 4);
  return header;
}

}  // namespace scrcpy_core
