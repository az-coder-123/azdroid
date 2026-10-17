// Big-endian integer decoding used by the scrcpy wire format.
#ifndef SCRCPY_CORE_BIG_ENDIAN_H_
#define SCRCPY_CORE_BIG_ENDIAN_H_

#include <cstdint>

namespace scrcpy_core {

// Reads a 32-bit unsigned big-endian integer from four bytes.
inline uint32_t ReadBigEndian32(const uint8_t* bytes) {
  return (static_cast<uint32_t>(bytes[0]) << 24) |
         (static_cast<uint32_t>(bytes[1]) << 16) |
         (static_cast<uint32_t>(bytes[2]) << 8) |
         static_cast<uint32_t>(bytes[3]);
}

// Reads a 64-bit unsigned big-endian integer from eight bytes.
inline uint64_t ReadBigEndian64(const uint8_t* bytes) {
  return (static_cast<uint64_t>(ReadBigEndian32(bytes)) << 32) |
         static_cast<uint64_t>(ReadBigEndian32(bytes + 4));
}

}  // namespace scrcpy_core

#endif  // SCRCPY_CORE_BIG_ENDIAN_H_
