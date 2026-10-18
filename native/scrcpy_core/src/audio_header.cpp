#include "scrcpy_core/audio_header.h"

#include "scrcpy_core/big_endian.h"

namespace scrcpy_core {

std::optional<AudioHeader> ParseAudioHeader(const uint8_t* data, size_t size) {
  if (data == nullptr || size < kAudioHeaderSize) {
    return std::nullopt;
  }
  AudioHeader header;
  header.codec_id = ReadBigEndian32(data);
  switch (header.codec_id) {
    case kAudioCodecRaw:
      header.kind = AudioStreamKind::kRaw;
      break;
    case kAudioDisabledCode:
      header.kind = AudioStreamKind::kDisabled;
      break;
    case kAudioConfigErrorCode:
      header.kind = AudioStreamKind::kConfigError;
      break;
    default:
      header.kind = AudioStreamKind::kUnsupportedCodec;
      break;
  }
  return header;
}

const char* AudioStreamKindName(AudioStreamKind kind) {
  switch (kind) {
    case AudioStreamKind::kRaw:
      return "raw";
    case AudioStreamKind::kDisabled:
      return "disabled";
    case AudioStreamKind::kConfigError:
      return "config_error";
    case AudioStreamKind::kUnsupportedCodec:
      return "unsupported_codec";
  }
  return "unsupported_codec";
}

}  // namespace scrcpy_core
