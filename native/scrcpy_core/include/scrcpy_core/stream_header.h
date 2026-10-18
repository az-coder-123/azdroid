// Video socket header sent once by scrcpy-server v4.0+ after the connection
// opens (v5.0.1 bundled).
//
// Layout (69 bytes, see docs/native-video-contract.md):
//   1 byte  dummy (0x00, forward-tunnel handshake)
//  64 bytes device name, UTF-8, NUL padded
//   4 bytes codec id, ASCII (for example "h264")
// The video size is not in the header: it arrives in the first session
// packet (packet_header.h), and again after every rotation.
#ifndef SCRCPY_CORE_STREAM_HEADER_H_
#define SCRCPY_CORE_STREAM_HEADER_H_

#include <cstddef>
#include <cstdint>
#include <optional>
#include <string>

namespace scrcpy_core {

inline constexpr size_t kDeviceNameSize = 64;
inline constexpr size_t kCodecIdSize = 4;
inline constexpr size_t kStreamHeaderSize = 1 + kDeviceNameSize + kCodecIdSize;

struct StreamHeader {
  std::string device_name;
  std::string codec;
};

// Parses a header from exactly kStreamHeaderSize bytes.
// Returns nullopt when [size] is too small.
std::optional<StreamHeader> ParseStreamHeader(const uint8_t* data, size_t size);

}  // namespace scrcpy_core

#endif  // SCRCPY_CORE_STREAM_HEADER_H_
