# Native Video Contract (macOS & Windows)

> The single source of truth for the native video pipeline. Both `macos/Runner/ScrcpyStreamPlugin.swift` and `windows/scrcpy_stream/` must follow it. Change this document first, then both implementations.

---

## 1. MethodChannel `com.deskdroid/video_stream`

Dart client: `lib/core/services/video_stream_native_service.dart`.

| Method | Arguments | Result | Behavior |
|:---|:---|:---|:---|
| `startStream` | `{host: String = "127.0.0.1", port: int = 27183}` | `int` texture id | Stops any previous stream, registers a new texture, connects in the background, returns immediately. Error `NO_REGISTRY` if textures are unavailable. |
| `stopStream` | none | `true` | Stops the connection and decoder, then unregisters the texture. Idempotent. |
| `getDimensions` | none | `{width: int, height: int}` | Latest known video size: the stream header first, then each decoded frame. `0x0` before connecting. |

---

## 2. Wire Format (scrcpy-server video socket)

All integers are big-endian.

**Stream header** (once, 77 bytes)

| Offset | Size | Field |
|:---|:---|:---|
| 0 | 1 | Dummy byte `0x00` (forward-tunnel handshake) |
| 1 | 64 | Device name, UTF-8, NUL padded |
| 65 | 4 | Codec id, ASCII (`h264`) |
| 69 | 4 | Width |
| 73 | 4 | Height |

**Packet** (repeated)

| Size | Field |
|:---|:---|
| 8 | PTS. Bit 63 = config (SPS/PPS), bit 62 = key frame, bits 0–61 = time in µs |
| 4 | Payload size (> 0, ≤ 32 MiB) |
| n | Payload: H.264 Annex B NAL units (`00 00 00 01` start codes) |

Config packets must be applied before the next media packet. Decoders that take Annex B input receive them **prepended** to that packet (`scrcpy_core::ConfigPacketMerger`), exactly like the official scrcpy client.

---

## 3. Behavioral Requirements

| Requirement | macOS | Windows |
|:---|:---|:---|
| Connect retries: 30 × 300 ms; header retry delay 400 ms | ✅ | ✅ `stream_config.h` |
| Socket read wakes every 1 s to honor `stopStream` | ✅ `SO_RCVTIMEO` | ✅ `SO_RCVTIMEO` |
| Decode on a background thread, never on the platform thread | ✅ | ✅ `StreamSession` |
| Resolution / rotation change mid-stream | ✅ new SPS → new session | ✅ `MF_E_TRANSFORM_STREAM_CHANGE` |
| Color: BT.709 limited range | ✅ buffer attachments | ✅ `scrcpy_core::ConvertNv12` |
| Texture pixel order | **BGRA** (`CVPixelBuffer`) | **RGBA** (`FlutterDesktopPixelBuffer`) |
| Stop order: producer first, then unregister texture | ✅ | ✅ texture kept alive by unregister callback |
| Diagnostic log | `/tmp/scrcpy_stream.log` | `%TEMP%\scrcpy_stream.log` |

---

## 4. Code Map

| Concern | macOS (Swift) | Windows (C++) |
|:---|:---|:---|
| Channel + texture | `ScrcpyStreamPlugin.swift` | `scrcpy_stream_plugin.cpp`, `frame_texture.cpp` |
| Socket | `runStreamLoop` / `readExact` | `winsock_connection.cpp` |
| Header / packet parsing | `runStreamLoop` | `native/scrcpy_core` (`stream_header`, `packet_header`) |
| Config handling | `parseConfigPacket` | `native/scrcpy_core/config_packet_merger` |
| Decoder | VideoToolbox | Media Foundation H.264 MFT (`mf_h264_decoder.cpp`) |
| Color conversion | VideoToolbox output (BGRA) | `native/scrcpy_core/nv12_converter` |
| Frame hand-off | `CVPixelBuffer` + lock | `native/scrcpy_core/latest_frame_buffer` (triple buffer) |

`native/scrcpy_core` is plain C++17 with no OS headers. It is the place for any new protocol logic, so both current and future platforms share one tested implementation. Moving the Swift parsing onto it (through a C ABI) is a planned follow-up.

---

## 5. Testing

| Layer | Command | Runs on |
|:---|:---|:---|
| `native/scrcpy_core` | `scripts/test_native_core.sh` (plain, ASan/UBSan, TSan) | macOS, Linux |
| `native/scrcpy_core` | `cmake -S native/scrcpy_core -B build/core -DSCRCPY_CORE_BUILD_TESTS=ON && ctest` | Windows (MSVC) |
| Windows plugin build | `flutter build windows` | Windows |
| End-to-end | Mirror a real device | Manual, both platforms |

There is no CI yet (planned in Phase 4 of [windows-port-plan.md](windows-port-plan.md)). Run the Windows rows on a Windows machine before merging changes to `windows/scrcpy_stream`.
