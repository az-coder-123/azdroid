# Native Audio Contract (macOS & Windows)

> The single source of truth for the native audio player. `macos/Runner/ScrcpyAudioPlugin.swift` and the audio part of `windows/scrcpy_stream/` must follow it. Change this document first, then both implementations. The video side is in [native-video-contract.md](native-video-contract.md).

---

## 1. MethodChannel `com.deskdroid/audio_stream`

Dart client: `lib/core/services/audio_stream_native_service.dart`.

| Method | Arguments | Result | Behavior |
|:---|:---|:---|:---|
| `isAvailable` | none | `true` | Present only where a player exists. Dart treats `MissingPluginException` as "no audio" and then starts the server with `audio=false`. |
| `startAudio` | `{host: String = "127.0.0.1", port: int = 27183}` | `bool` | Stops any previous audio, opens the TCP socket, and returns `true` once it is connected locally. Header, packets, and playback continue in the background. |
| `stopAudio` | none | `true` | Stops reading and playback, closes the socket. Idempotent. |
| `setVolume` | `{volume: double}` (0.0 – 1.0) | `true` | Gain on the decoded samples. Kept across sessions. |
| `setMuted` | `{muted: bool}` | `true` | Silences output; audio keeps draining. Kept across sessions. |
| `getAudioStats` | none | map (below) | Current state and cumulative counters; `idle` with zeros when no audio runs. |

**`getAudioStats`**: `{state: String, bytesReceived: int, bufferedFrames: int, playedFrames: int, droppedFrames: int, underruns: int}`.

| `state` | Meaning |
|:---|:---|
| `idle` | No audio, or stopped by the caller. |
| `connecting` | Socket open, waiting for the 4-byte audio header. |
| `playing` | Raw PCM header received; packets feed the jitter buffer and the output device runs. |
| `disabled` | The device cannot capture audio (code `0`, Android 10 or older). Video continues. |
| `failed` | Configuration error (code `1`), an unsupported codec, or the output device could not start. |
| `ended` | The device closed the audio socket after playback had started. |

---

## 2. Wire Format (scrcpy-server audio socket)

Server options: `audio=true`, `audio_codec=raw` (built by `ScrcpyServerCommand`). The audio source is the default `output`: the whole device output is captured, and the phone itself goes quiet while mirroring. Android 11+ only; Android 11 also needs the screen unlocked when mirroring starts.

| Step | Bytes |
|:---|:---|
| Header (once) | 4: codec id, big-endian. `0x00726177` ("\0raw") = raw; `0` = disabled; `1` = configuration error; anything else = unsupported. |
| Packet (repeated) | 12-byte header as for video (8 PTS/flags, 4 size), then the payload: PCM 16-bit little-endian, stereo interleaved, 48 kHz. |

Parsing lives in `native/scrcpy_core` (`audio_header`, `packet_header`). With `0` the server closes the audio socket and mirroring continues.

**Socket order.** In forward-tunnel mode the server accepts **video, then audio, then control** on the same port. Dart (`ScrcpyControlConnector`) waits for the video state `connected`, calls `startAudio` (which returns after the local connect), and only then opens control. If the server runs with `audio=true` and no audio socket connects, it never accepts control, so Dart must check `isAvailable` before starting the server.

---

## 3. Behavioral Requirements

| Requirement | macOS | Windows |
|:---|:---|:---|
| Jitter buffer: 50 ms target, 200 ms maximum, prime after underrun | `scrcpy_core` via `audio_c_api.h` | `scrcpy_core::PcmJitterBuffer` |
| Read on a background thread; never block the platform thread | ✅ | ✅ |
| Keep reading until stopped (the socket shares the adb transport with control) | ✅ | ✅ |
| Output device | `AVAudioEngine` + `AVAudioSourceNode` (planar float) | WASAPI shared mode, event driven (interleaved float) |
| Volume and mute applied in the jitter buffer read | ✅ | ✅ |
| Stop order: socket reader first, then output, then clear the buffer | ✅ | ✅ |
| Diagnostic log | `/tmp/scrcpy_stream.log` (`[audio]` prefix) | `%TEMP%\scrcpy_stream.log` (`[audio]` prefix) |

Clock drift between the phone and the computer is handled only by the buffer policy: a faster phone eventually hits 200 ms and drops to 50 ms; a faster computer underruns and primes 50 ms of silence. Both are rare, short glitches; resampling-based drift correction is a possible follow-up.

---

## 4. Code Map

| Concern | macOS (Swift) | Windows (C++) |
|:---|:---|:---|
| Channel | `ScrcpyAudioPlugin.swift` | `scrcpy_stream_plugin.cpp` (second channel) |
| Socket | `ScrcpyAudioPlugin` reader thread | `winsock_connection.cpp` |
| Header / packets | `scrcpy_core` C API, packet header in Swift | `scrcpy_core` (`audio_header`, `packet_header`) |
| Jitter buffer | `scrcpy_core` C API | `scrcpy_core::PcmJitterBuffer` |
| Output | `AVAudioEngine` | `wasapi_audio_output.cpp` |

---

## 5. Testing

| Layer | Command | Runs on |
|:---|:---|:---|
| `native/scrcpy_core` (audio tests included) | `scripts/test_native_core.sh` | macOS, Linux |
| Dart contract, ordering, state mapping | `flutter test` | any |
| On-device server check | `dart run tool/verify_scrcpy_server.dart --serial=<serial>` | Android 11+ for audio; Android 10 reports `disabled` |
| End-to-end | Mirror a device and play media | Manual, both platforms |
