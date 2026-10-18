#include <cstring>
#include <vector>

#include "scrcpy_core/config_packet_merger.h"
#include "scrcpy_core/packet_header.h"
#include "scrcpy_core/stream_header.h"
#include "test_harness.h"

using namespace scrcpy_core;

namespace {

std::vector<uint8_t> BuildStreamHeader(const char* name, const char* codec) {
  std::vector<uint8_t> bytes(kStreamHeaderSize, 0);
  std::memcpy(&bytes[1], name, std::strlen(name));
  std::memcpy(&bytes[1 + kDeviceNameSize], codec, kCodecIdSize);
  return bytes;
}

void PutBigEndian32(std::vector<uint8_t>& bytes, size_t at, uint32_t value) {
  for (int i = 0; i < 4; ++i) {
    bytes[at + static_cast<size_t>(i)] =
        static_cast<uint8_t>(value >> (24 - 8 * i));
  }
}

// Same layout as scrcpy v5.0.1 Streamer.writeSessionMeta().
std::vector<uint8_t> BuildSessionPacket(uint32_t width, uint32_t height,
                                        bool client_resized) {
  std::vector<uint8_t> bytes(kPacketHeaderSize, 0);
  PutBigEndian32(bytes, 0, 0x80000000u | (client_resized ? 1u : 0u));
  PutBigEndian32(bytes, 4, width);
  PutBigEndian32(bytes, 8, height);
  return bytes;
}

std::vector<uint8_t> BuildPacketHeader(uint64_t raw_pts, uint32_t size) {
  std::vector<uint8_t> bytes(kPacketHeaderSize, 0);
  for (int i = 0; i < 8; ++i) {
    bytes[static_cast<size_t>(i)] =
        static_cast<uint8_t>(raw_pts >> (56 - 8 * i));
  }
  for (int i = 0; i < 4; ++i) {
    bytes[8 + static_cast<size_t>(i)] =
        static_cast<uint8_t>(size >> (24 - 8 * i));
  }
  return bytes;
}

}  // namespace

SCRCPY_TEST(StreamHeaderParsesNameAndCodec) {
  const auto bytes = BuildStreamHeader("Pixel 8", "h264");
  EXPECT_EQ(kStreamHeaderSize, size_t{69});
  const auto header = ParseStreamHeader(bytes.data(), bytes.size());
  EXPECT_TRUE(header.has_value());
  EXPECT_EQ(header->device_name, std::string("Pixel 8"));
  EXPECT_EQ(header->codec, std::string("h264"));
}

SCRCPY_TEST(StreamHeaderKeepsFullLengthNameWithoutNul) {
  std::string long_name(kDeviceNameSize, 'A');
  const auto bytes = BuildStreamHeader(long_name.c_str(), "h265");
  const auto header = ParseStreamHeader(bytes.data(), bytes.size());
  EXPECT_EQ(header->device_name.size(), kDeviceNameSize);
}

SCRCPY_TEST(StreamHeaderRejectsShortInput) {
  const auto bytes = BuildStreamHeader("x", "h264");
  EXPECT_TRUE(!ParseStreamHeader(bytes.data(), bytes.size() - 1).has_value());
  EXPECT_TRUE(!ParseStreamHeader(nullptr, kStreamHeaderSize).has_value());
}

SCRCPY_TEST(PacketHeaderDecodesKeyFrameAndPts) {
  const uint64_t raw = (uint64_t{1} << 61) | 123456u;
  const auto bytes = BuildPacketHeader(raw, 4096);
  const auto header = ParsePacketHeader(bytes.data(), bytes.size());
  EXPECT_TRUE(header.has_value());
  EXPECT_TRUE(!header->is_session);
  EXPECT_TRUE(header->is_key_frame);
  EXPECT_TRUE(!header->is_config);
  EXPECT_EQ(header->pts_us, uint64_t{123456});
  EXPECT_EQ(header->payload_size, 4096u);
}

SCRCPY_TEST(PacketHeaderDecodesConfigFlag) {
  const auto bytes = BuildPacketHeader(uint64_t{1} << 62, 30);
  const auto header = ParsePacketHeader(bytes.data(), bytes.size());
  EXPECT_TRUE(header->is_config);
  EXPECT_TRUE(!header->is_key_frame);
  EXPECT_EQ(header->pts_us, uint64_t{0});
}

SCRCPY_TEST(PacketHeaderPtsUsesSixtyOneBits) {
  const uint64_t pts = (uint64_t{1} << 61) - 1;  // Largest PTS value.
  const auto bytes = BuildPacketHeader(pts, 1);
  const auto header = ParsePacketHeader(bytes.data(), bytes.size());
  EXPECT_EQ(header->pts_us, pts);
  EXPECT_TRUE(!header->is_key_frame && !header->is_config);
}

SCRCPY_TEST(PacketHeaderDecodesSessionPacket) {
  const auto bytes = BuildSessionPacket(1080, 2336, false);
  const auto header = ParsePacketHeader(bytes.data(), bytes.size());
  EXPECT_TRUE(header.has_value());
  EXPECT_TRUE(header->is_session);
  EXPECT_EQ(header->session_width, 1080u);
  EXPECT_EQ(header->session_height, 2336u);
  EXPECT_TRUE(!header->client_resized);
  EXPECT_EQ(header->payload_size, 0u);  // A session packet has no payload.

  const auto resized = BuildSessionPacket(2336, 1080, true);
  EXPECT_TRUE(ParsePacketHeader(resized.data(), resized.size())->client_resized);
}

SCRCPY_TEST(PacketHeaderRejectsInvalidPackets) {
  const auto empty = BuildPacketHeader(0, 0);
  EXPECT_TRUE(!ParsePacketHeader(empty.data(), empty.size()).has_value());
  const auto huge = BuildPacketHeader(0, kMaxPacketPayloadSize + 1);
  EXPECT_TRUE(!ParsePacketHeader(huge.data(), huge.size()).has_value());
  EXPECT_TRUE(!ParsePacketHeader(empty.data(), 11).has_value());
  const auto no_size = BuildSessionPacket(0, 2336, false);
  EXPECT_TRUE(!ParsePacketHeader(no_size.data(), no_size.size()).has_value());
}

SCRCPY_TEST(MergerPrependsConfigToNextMediaPacketOnce) {
  ConfigPacketMerger merger;
  std::vector<uint8_t> out;
  const uint8_t config[] = {0, 0, 0, 1, 0x67, 0, 0, 0, 1, 0x68};
  const uint8_t frame1[] = {0, 0, 0, 1, 0x65};
  const uint8_t frame2[] = {0, 0, 0, 1, 0x41};

  EXPECT_TRUE(!merger.Push(config, sizeof(config), true, out));
  EXPECT_TRUE(merger.has_pending_config());

  EXPECT_TRUE(merger.Push(frame1, sizeof(frame1), false, out));
  EXPECT_EQ(out.size(), sizeof(config) + sizeof(frame1));
  EXPECT_EQ(out[4], 0x67);
  EXPECT_EQ(out.back(), 0x65);

  EXPECT_TRUE(merger.Push(frame2, sizeof(frame2), false, out));
  EXPECT_EQ(out.size(), sizeof(frame2));
}

SCRCPY_TEST(MergerKeepsOnlyTheNewestConfig) {
  ConfigPacketMerger merger;
  std::vector<uint8_t> out;
  const uint8_t old_config[] = {0xAA, 0xAA};
  const uint8_t new_config[] = {0xBB};
  const uint8_t frame[] = {0x01};

  merger.Push(old_config, sizeof(old_config), true, out);
  merger.Push(new_config, sizeof(new_config), true, out);
  merger.Push(frame, sizeof(frame), false, out);

  EXPECT_EQ(out.size(), size_t{2});
  EXPECT_EQ(out[0], 0xBB);
}

SCRCPY_TEST(MergerResetDropsPendingConfig) {
  ConfigPacketMerger merger;
  std::vector<uint8_t> out;
  const uint8_t config[] = {0x67};
  merger.Push(config, sizeof(config), true, out);
  merger.Reset();
  EXPECT_TRUE(!merger.has_pending_config());
}
