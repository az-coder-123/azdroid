// Per-packet header of the scrcpy v4.0+ video and audio streams (12 bytes,
// see docs/native-video-contract.md). Two kinds share the size:
//
//   Session packet (bit 63 set; video only, at start and after every
//   capture change such as a rotation; no payload):
//     4 bytes flags, big-endian: bit 31 = session, bit 0 = client resize
//     4 bytes width, big-endian
//     4 bytes height, big-endian
//
//   Media packet (bit 63 clear):
//     8 bytes PTS, big-endian. Bit 62 = config packet (SPS/PPS),
//             bit 61 = key frame, bits 0..60 = presentation time in us.
//     4 bytes payload size, big-endian; the payload follows.
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
  // True for a session packet; only session_* fields are meaningful then.
  bool is_session = false;
  uint32_t session_width = 0;
  uint32_t session_height = 0;
  bool client_resized = false;

  // Media packet fields.
  uint64_t pts_us = 0;
  bool is_config = false;
  bool is_key_frame = false;
  uint32_t payload_size = 0;
};

// Parses kPacketHeaderSize bytes. Returns nullopt for short input, a media
// packet with an empty payload or one above kMaxPacketPayloadSize, or a
// session packet with a zero width or height.
std::optional<PacketHeader> ParsePacketHeader(const uint8_t* data, size_t size);

}  // namespace scrcpy_core

#endif  // SCRCPY_CORE_PACKET_HEADER_H_
