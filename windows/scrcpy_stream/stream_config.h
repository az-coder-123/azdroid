// Tuning constants for the Windows scrcpy video pipeline. Values mirror the
// macOS ScrcpyStreamPlugin so both platforms behave the same.
#ifndef SCRCPY_STREAM_STREAM_CONFIG_H_
#define SCRCPY_STREAM_STREAM_CONFIG_H_

#include <chrono>
#include <cstdint>

namespace scrcpy_stream {

// MethodChannel shared with lib/core/services/video_stream_native_service.dart.
inline constexpr char kChannelName[] = "com.azdroid/video_stream";

// MethodChannel shared with lib/core/services/audio_stream_native_service.dart.
inline constexpr char kAudioChannelName[] = "com.azdroid/audio_stream";

inline constexpr char kDefaultHost[] = "127.0.0.1";
inline constexpr int32_t kDefaultPort = 27183;

// The server may need a moment to open its socket after `adb forward`.
inline constexpr int kConnectAttempts = 30;
inline constexpr std::chrono::milliseconds kConnectRetryDelay{300};
inline constexpr std::chrono::milliseconds kHeaderRetryDelay{400};

// recv() wakes up this often to check whether the session was stopped.
inline constexpr uint32_t kReceiveTimeoutMs = 1000;

// Log the first few packets/frames, then every Nth one.
inline constexpr int kVerboseLogCount = 5;
inline constexpr int kPeriodicLogInterval = 60;

// Media Foundation timestamps are in 100-nanosecond units.
inline constexpr int64_t kHundredNsPerMicrosecond = 10;

}  // namespace scrcpy_stream

#endif  // SCRCPY_STREAM_STREAM_CONFIG_H_
