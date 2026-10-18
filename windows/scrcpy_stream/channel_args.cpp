#include "channel_args.h"

#include <variant>

#include "stream_config.h"

namespace scrcpy_stream {

namespace {

using flutter::EncodableMap;
using flutter::EncodableValue;

constexpr char kHostKey[] = "host";
constexpr char kPortKey[] = "port";

const EncodableValue* Find(const EncodableMap* args, const char* key) {
  if (args == nullptr) return nullptr;
  const auto it = args->find(EncodableValue(key));
  return it == args->end() ? nullptr : &it->second;
}

}  // namespace

std::string ReadHost(const EncodableMap* args) {
  if (const auto* value = Find(args, kHostKey)) {
    if (const auto* host = std::get_if<std::string>(value)) return *host;
  }
  return kDefaultHost;
}

uint16_t ReadPort(const EncodableMap* args) {
  int64_t port = kDefaultPort;
  if (const auto* value = Find(args, kPortKey)) {
    // Dart ints arrive as int32 when they fit, int64 otherwise.
    // Avoid the name `small`: the Windows SDK defines it as a macro.
    if (const auto* port32 = std::get_if<int32_t>(value)) port = *port32;
    if (const auto* port64 = std::get_if<int64_t>(value)) port = *port64;
  }
  return (port > 0 && port <= UINT16_MAX) ? static_cast<uint16_t>(port)
                                          : static_cast<uint16_t>(kDefaultPort);
}

double ReadDouble(const EncodableMap* args, const char* key, double fallback) {
  if (const auto* value = Find(args, key)) {
    if (const auto* number = std::get_if<double>(value)) return *number;
  }
  return fallback;
}

bool ReadBool(const EncodableMap* args, const char* key, bool fallback) {
  if (const auto* value = Find(args, key)) {
    if (const auto* flag = std::get_if<bool>(value)) return *flag;
  }
  return fallback;
}

}  // namespace scrcpy_stream
