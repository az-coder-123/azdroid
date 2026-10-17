// Per-packet header of the scrcpy video stream.
//
// Layout (12 bytes):
//   8 bytes PTS, big-endian. Bit 63 = config packet (SPS/PPS),
//           bit 62 = key frame, bits 0..61 = presentation time in microseconds.
//   4 bytes payload size, big-endian.
#ifndef SCRCPY_CORE_PACKET_HEADER_H_
#define SCRCPY_CORE_PACKET_HEADER_H_

#include <cstddef>
#include <cstdint>
#include <optional>

namespace scrcpy_core {

inline constexpr size_t kPacketHeaderSize = 12;

// Upper bound on one payload; larger values mean a corrupt stream.
inline constexpr uint32_t kMaxPacketPayloadSize = 32u * 1024u * 1024u;

struct PacketHeader {
  uint64_t pts_us = 0;
  bool is_config = false;
  bool is_key_frame = false;
  uint32_t payload_size = 0;
};

// Parses kPacketHeaderSize bytes. Returns nullopt for short input, an empty
// payload, or a payload above kMaxPacketPayloadSize.
std::optional<PacketHeader> ParsePacketHeader(const uint8_t* data, size_t size);

}  // namespace scrcpy_core

#endif  // SCRCPY_CORE_PACKET_HEADER_H_
