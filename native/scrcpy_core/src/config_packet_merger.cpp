#include "scrcpy_core/config_packet_merger.h"

namespace scrcpy_core {

bool ConfigPacketMerger::Push(const uint8_t* payload, size_t size,
                              bool is_config, std::vector<uint8_t>& out) {
  if (is_config) {
    // A newer config replaces an older one that was never consumed.
    pending_config_.assign(payload, payload + size);
    return false;
  }
  out.clear();
  out.reserve(pending_config_.size() + size);
  out.insert(out.end(), pending_config_.begin(), pending_config_.end());
  out.insert(out.end(), payload, payload + size);
  pending_config_.clear();
  return true;
}

void ConfigPacketMerger::Reset() { pending_config_.clear(); }

}  // namespace scrcpy_core
