#include "scrcpy_core/packet_header.h"

#include "scrcpy_core/big_endian.h"

namespace scrcpy_core {

namespace {

constexpr uint64_t kConfigFlag = uint64_t{1} << 63;
constexpr uint64_t kKeyFrameFlag = uint64_t{1} << 62;
constexpr uint64_t kPtsMask = kKeyFrameFlag - 1;

}  // namespace

std::optional<PacketHeader> ParsePacketHeader(const uint8_t* data, size_t size) {
  if (data == nullptr || size < kPacketHeaderSize) {
    return std::nullopt;
  }
  const uint64_t raw_pts = ReadBigEndian64(data);
  const uint32_t payload_size = ReadBigEndian32(data + 8);
  if (payload_size == 0 || payload_size > kMaxPacketPayloadSize) {
    return std::nullopt;
  }
  PacketHeader header;
  header.pts_us = raw_pts & kPtsMask;
  header.is_config = (raw_pts & kConfigFlag) != 0;
  header.is_key_frame = (raw_pts & kKeyFrameFlag) != 0;
  header.payload_size = payload_size;
  return header;
}

}  // namespace scrcpy_core
