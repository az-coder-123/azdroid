// Reads MethodChannel arguments shared by the video and audio channels.
#ifndef SCRCPY_STREAM_CHANNEL_ARGS_H_
#define SCRCPY_STREAM_CHANNEL_ARGS_H_

#include <flutter/encodable_value.h>

#include <cstdint>
#include <string>

namespace scrcpy_stream {

// `host` argument, or kDefaultHost.
std::string ReadHost(const flutter::EncodableMap* args);

// `port` argument when it is a valid TCP port, or kDefaultPort.
uint16_t ReadPort(const flutter::EncodableMap* args);

// Double argument [key], or [fallback].
double ReadDouble(const flutter::EncodableMap* args, const char* key,
                  double fallback);

// Bool argument [key], or [fallback].
bool ReadBool(const flutter::EncodableMap* args, const char* key, bool fallback);

}  // namespace scrcpy_stream

#endif  // SCRCPY_STREAM_CHANNEL_ARGS_H_
