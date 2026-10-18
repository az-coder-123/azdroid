#include "scrcpy_core/packet_header.h"

#include "scrcpy_core/big_endian.h"

namespace scrcpy_core {

namespace {

constexpr uint64_t kSessionFlag = uint64_t{1} << 63;
constexpr uint64_t kConfigFlag = uint64_t{1} << 62;
constexpr uint64_t kKeyFrameFlag = uint64_t{1} << 61;
constexpr uint64_t kPtsMask = kKeyFrameFlag - 1;
constexpr uint32_t kClientResizeFlag = 1;

}  // namespace

std::optional<PacketHeader> ParsePacketHeader(const uint8_t* data, size_t size) {
  if (data == nullptr || size < kPacketHeaderSize) {
    return std::nullopt;
  }
  const uint64_t raw = ReadBigEndian64(data);
  PacketHeader header;
  if ((raw & kSessionFlag) != 0) {
    const uint32_t flags = ReadBigEndian32(data);
    header.is_session = true;
    header.client_resized = (flags & kClientResizeFlag) != 0;
    header.session_width = ReadBigEndian32(data + 4);
    header.session_height = ReadBigEndian32(data + 8);
    if (header.session_width == 0 || header.session_height == 0) {
      return std::nullopt;
    }
    return header;
  }
  const uint32_t payload_size = ReadBigEndian32(data + 8);
  if (payload_size == 0 || payload_size > kMaxPacketPayloadSize) {
    return std::nullopt;
  }
  header.pts_us = raw & kPtsMask;
  header.is_config = (raw & kConfigFlag) != 0;
  header.is_key_frame = (raw & kKeyFrameFlag) != 0;
  header.payload_size = payload_size;
  return header;
}

}  // namespace scrcpy_core
