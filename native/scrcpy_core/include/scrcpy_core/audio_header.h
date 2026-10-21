// Audio socket header sent once by scrcpy-server (v2.0 - v3.3.x).
//
// Layout (4 bytes, see docs/native-audio-contract.md):
//   4 bytes codec id, big-endian ASCII ("\0raw", "opus", ...), or
//           0 = audio disabled on the device (keep mirroring video only),
//           1 = configuration error (the session must stop).
// Packets follow with the same 12-byte header as video (packet_header.h).
#ifndef SCRCPY_CORE_AUDIO_HEADER_H_
#define SCRCPY_CORE_AUDIO_HEADER_H_

#include <cstddef>
#include <cstdint>
#include <optional>

namespace scrcpy_core {

inline constexpr size_t kAudioHeaderSize = 4;

// "\0raw": uncompressed PCM, 16-bit little-endian, interleaved.
inline constexpr uint32_t kAudioCodecRaw = 0x00726177;
inline constexpr uint32_t kAudioDisabledCode = 0;
inline constexpr uint32_t kAudioConfigErrorCode = 1;

enum class AudioStreamKind {
  kRaw,               // Playable by Azdroid.
  kDisabled,          // The device cannot capture audio (Android 10 or older).
  kConfigError,       // The server rejected the audio configuration.
  kUnsupportedCodec,  // A codec Azdroid does not decode.
};

struct AudioHeader {
  AudioStreamKind kind = AudioStreamKind::kUnsupportedCodec;
  uint32_t codec_id = 0;
};

// Parses the header from at least kAudioHeaderSize bytes.
// Returns nullopt when [size] is too small.
std::optional<AudioHeader> ParseAudioHeader(const uint8_t* data, size_t size);

// Stable lowercase name of [kind], used in the audio stats channel contract.
const char* AudioStreamKindName(AudioStreamKind kind);

}  // namespace scrcpy_core

#endif  // SCRCPY_CORE_AUDIO_HEADER_H_
