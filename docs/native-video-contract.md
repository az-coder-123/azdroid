# Native Video Contract (macOS & Windows)

> The single source of truth for the native video pipeline. Both `macos/Runner/ScrcpyStreamPlugin.swift` and `windows/scrcpy_stream/` must follow it. Change this document first, then both implementations.

---

## 1. MethodChannel `com.deskdroid/video_stream`

Dart client: `lib/core/services/video_stream_native_service.dart`.

| Method | Arguments | Result | Behavior |
|:---|:---|:---|:---|
| `startStream` | `{host: String = "127.0.0.1", port: int = 27183}` | `int` texture id | Stops any previous stream, registers a new texture, connects in the background, returns immediately. Error `NO_REGISTRY` if textures are unavailable. |
| `stopStream` | none | `true` | Stops the connection and decoder, then unregisters the texture. Idempotent. |
| `getDimensions` | none | `{width: int, height: int}` | Latest known video size: each session packet, then each decoded frame. `0x0` before connecting. |
| `getStats` | none | `{state: String, framesDecoded: int, bytesReceived: int, processingTimeUs: int}` | Stream state and cumulative counters (see below). `idle` with zeros when no stream exists. |

**`getStats` states**

| `state` | Meaning |
|:---|:---|
| `idle` | No stream, or stopped by the caller. |
| `connecting` | Waiting for the server to accept the video socket. |
| `connected` | Dummy byte read: the server accepted the video socket and now waits for the control socket. Dart opens control in this state (see below). |
| `streaming` | Header received; packets are flowing. |
| `failed` | Gave up before streaming: no server after all retries, bad header, unsupported codec, or decoder setup failure. |
| `ended` | The stream had started, then the device closed the socket. |

Counters only grow during one stream, so the Dart client (`StreamTelemetrySampler`) polls once per second and derives FPS, bitrate, and average latency from the difference between two snapshots. `processingTimeUs` sums, over all frames, the time from "packet fully received" to "frame published". Counting and thread safety live in `scrcpy_core::StreamStats` (Windows) and its Swift twin `ScrcpyStreamStats` (macOS). Dart treats a missing `getStats` (`MissingPluginException`) as "telemetry unknown".

---

## 2. Wire Format (scrcpy-server video socket)

Server: bundled `assets/scrcpy-server.jar`, **v5.0.1** (version in `lib/core/constants/scrcpy_server_constants.dart`). The client passes it as the first argument, and the server refuses to start on a mismatch, which the app detects and logs (`ScrcpyServerOutput`). `test/unit/scrcpy_server_version_test.dart` reads the version from the jar's `classes.dex`, and `scrcpy_server_command_test.dart` checks that every option key exists in the jar. To upgrade, follow [scrcpy-upgrade-assessment.md](scrcpy-upgrade-assessment.md#5-upgrade-procedure); this wire format is valid from v4.0 (session packets) through v5.0.x.

All integers are big-endian.

**Stream header** (once, 69 bytes)

| Offset | Size | Field |
|:---|:---|:---|
| 0 | 1 | Dummy byte `0x00` (forward-tunnel handshake) |
| 1 | 64 | Device name, UTF-8, NUL padded |
| 65 | 4 | Codec id, ASCII (`h264`) |

The header no longer carries the video size; the first packet does.

**Session packet** (12 bytes, no payload): first after the header, and again on each capture change (rotation, fold)

| Size | Field |
|:---|:---|
| 4 | Flags. Bit 31 = session packet (bit 63 of the 8-byte field below), bit 0 = resized by the client |
| 4 | Width (> 0) |
| 4 | Height (> 0) |

**Media packet** (repeated)

| Size | Field |
|:---|:---|
| 8 | PTS and flags. Bit 63 = 0 (not a session packet), bit 62 = config (SPS/PPS), bit 61 = key frame, bits 0–60 = time in µs |
| 4 | Payload size (> 0, ≤ 32 MiB) |
| n | Payload: H.264 Annex B NAL units (`00 00 00 01` start codes) |

The first packet must be a session packet; native closes the stream otherwise, like the official client. `scrcpy_core::ParsePacketHeader` decodes both kinds.

Config packets must be applied before the next media packet. Decoders that take Annex B input receive them **prepended** to that packet (`scrcpy_core::ConfigPacketMerger`), exactly like the official scrcpy client.

**Socket order with control (`control=true`)**

The server runs with control enabled (and audio where the platform has a player), so it accepts the sockets on the same forwarded port in a fixed order: video, audio, control. Audio is described in [native-audio-contract.md](native-audio-contract.md); with or without it, the video steps are:

1. Native connects the video socket and reads the dummy byte, then sets `getStats` to `connected`.
2. Dart (`ScrcpyControlConnector`) sees `connected`, opens the audio socket when audio is on (`startAudio`), then the control socket on the same port (`ScrcpyControlChannel`).
3. Only then does the server send the device name and codec id. Native reads the rest of the header, then the first session packet.

Reading the full header before control connects would deadlock. Native must also keep reading video for the whole session: all `adb forward` sockets share one adb transport, so an unread video socket stalls control messages too. Control message bytes are in `lib/core/services/scrcpy_control_message.dart`, checked against scrcpy's own serializer tests.

---

## 3. Behavioral Requirements

| Requirement | macOS | Windows |
|:---|:---|:---|
| Connect retries: 30 × 300 ms; header retry delay 400 ms | ✅ | ✅ `stream_config.h` |
| `connected` after the dummy byte, before the rest of the header | ✅ | ✅ `ConnectAndReadHeader` |
| `getDimensions` equals the size the server checks touch events against | ✅ SPS presentation size (clean aperture) | ✅ header, then MFT output |
| Socket read wakes every 1 s to honor `stopStream` | ✅ `SO_RCVTIMEO` | ✅ `SO_RCVTIMEO` |
| Decode on a background thread, never on the platform thread | ✅ | ✅ `StreamSession` |
| Resolution / rotation change mid-stream | ✅ new SPS → new session | ✅ `MF_E_TRANSFORM_STREAM_CHANGE` |
| Color: BT.709 limited range | ✅ buffer attachments | ✅ `scrcpy_core::ConvertNv12` |
| Texture pixel order | **BGRA** (`CVPixelBuffer`) | **RGBA** (`FlutterDesktopPixelBuffer`) |
| Stop order: producer first, then unregister texture | ✅ no frame after `ScrcpyVideoSession.stop()`; socket interrupted at once | ✅ texture kept alive by unregister callback |
| Only the reader thread closes the socket and decoder | ✅ | ✅ `StreamSession::Stop` joins the thread |
| `getStats` states and counters; `failed` / `ended` set only while not stopped | ✅ `ScrcpyStreamStats.swift` | ✅ `scrcpy_core::StreamStats` |
| Per-frame latency start point | Packet receive time passed as the VideoToolbox frame refcon | `packet_received_at_` (decode is synchronous) |
| Diagnostic log | `/tmp/scrcpy_stream.log` | `%TEMP%\scrcpy_stream.log` |

---

## 4. Code Map

| Concern | macOS (Swift) | Windows (C++) |
|:---|:---|:---|
| Channel + texture | `ScrcpyStreamPlugin.swift` | `scrcpy_stream_plugin.cpp`, `frame_texture.cpp` |
| Session (reader thread, retries, stop) | `ScrcpyVideoSession.swift` | `stream_session.cpp` |
| Socket | `ScrcpySocket.swift` (shared with audio) | `winsock_connection.cpp` |
| Header / packet parsing | `ScrcpyVideoSession.swift` | `native/scrcpy_core` (`stream_header`, `packet_header`) |
| Config handling | `ScrcpyH264Decoder.applyConfig`, `ScrcpyAnnexB.swift` | `native/scrcpy_core/config_packet_merger` |
| Decoder | VideoToolbox (`ScrcpyH264Decoder.swift`) | Media Foundation H.264 MFT (`mf_h264_decoder.cpp`) |
| Color conversion | VideoToolbox output (BGRA) | `native/scrcpy_core/nv12_converter` |
| Frame hand-off | `CVPixelBuffer` + lock | `native/scrcpy_core/latest_frame_buffer` (triple buffer) |
| Stats (`getStats`) | `ScrcpyStreamStats.swift` | `native/scrcpy_core/stream_stats` |
| Control socket (shared, Dart) | `lib/core/services/scrcpy_control_channel.dart`, `scrcpy_control_connector.dart` | same |

`native/scrcpy_core` is plain C++17 with no OS headers. It is the place for any new protocol logic, so both current and future platforms share one tested implementation. Moving the Swift parsing onto it (through a C ABI) is a planned follow-up.

---

## 5. Testing

| Layer | Command | Runs on |
|:---|:---|:---|
| `native/scrcpy_core` | `scripts/test_native_core.sh` (plain, ASan/UBSan, TSan) | macOS, Linux |
| `native/scrcpy_core` | `cmake -S native/scrcpy_core -B build/core -DSCRCPY_CORE_BUILD_TESTS=ON && ctest` | Windows (MSVC) |
| Windows plugin build | `flutter build windows` | Windows |
| macOS session + decoder on a device | `scripts/check_macos_native.sh <serial> video` (frames decoded, real size, none after stop) | macOS |
| End-to-end | Mirror a real device | Manual, both platforms |

There is no CI yet (planned in Phase 4 of [windows-port-plan.md](windows-port-plan.md)). Run the Windows rows on a Windows machine before merging changes to `windows/scrcpy_stream`.
