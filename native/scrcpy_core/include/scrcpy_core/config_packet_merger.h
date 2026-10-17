// Prepends codec config packets (SPS/PPS) to the next media packet.
//
// scrcpy sends SPS/PPS as a separate "config" packet. Decoders that consume
// Annex B byte streams (Media Foundation, FFmpeg) expect them in front of the
// next frame, which is what the official scrcpy client does as well.
#ifndef SCRCPY_CORE_CONFIG_PACKET_MERGER_H_
#define SCRCPY_CORE_CONFIG_PACKET_MERGER_H_

#include <cstddef>
#include <cstdint>
#include <vector>

namespace scrcpy_core {

class ConfigPacketMerger {
 public:
  // Feeds one packet payload.
  //
  // Config packets are stored and produce no output (returns false).
  // Media packets are written to [out], prefixed with any pending config,
  // and the call returns true.
  bool Push(const uint8_t* payload, size_t size, bool is_config,
            std::vector<uint8_t>& out);

  // Drops any pending config, for example when a stream restarts.
  void Reset();

  bool has_pending_config() const { return !pending_config_.empty(); }

 private:
  std::vector<uint8_t> pending_config_;
};

}  // namespace scrcpy_core

#endif  // SCRCPY_CORE_CONFIG_PACKET_MERGER_H_
