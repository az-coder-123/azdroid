# Lesson Learned: Scrcpy Video Stream Protocol & Packet Framing De-encapsulation

> **Category:** Video Decoding / Low-Level Protocols / VideoToolbox Hardware Acceleration  
> **Impact:** Apple VideoToolbox decoder errors (`kVTVideoDecoderBadDataErr -12909`) and corrupted frames.

---

## 1. Context & Symptoms

When establishing a low-latency screen mirroring pipeline from Android via `scrcpy-server` over a local ADB socket forward:
- Attempting to pass the incoming raw socket byte stream directly to the macOS native hardware video decoder (Apple VideoToolbox / `AVSampleBufferDisplayLayer`) resulted in decoding failure:
  ```text
  VideoToolbox decodeFrame failed: kVTVideoDecoderBadDataErr (-12909)
  ```
- No video rendered in the Flutter texture viewport, or the stream stuttered with distorted macroblocks.
- Video stream inspection scripts (`scratch/dump_raw_bytes.dart`, `scratch/inspect_packets.dart`) confirmed valid H.264 NAL units existed, but decoding aborted immediately.

---

## 2. Diagnostic Traces & Evidence

Inspecting raw socket bytes received from `scrcpy-server v2.x`:

1. **Initial Connection Handshake:**
   - Byte 0-63 (64 bytes): Device model string (null-padded UTF-8).
   - Byte 64-67 (4 bytes): Codec fourCC (`h264` = `0x68323634`).
   - Byte 68-71 (4 bytes): Initial display width (big-endian integer).
   - Byte 72-75 (4 bytes): Initial display height (big-endian integer).

2. **Subsequent Media Stream Framing:**
   The stream is **not** raw Annex-B H.264 byte stream directly. Every media packet is framed by a 12-byte binary header:
   - **8 bytes (int64):** Presentation Time Stamp (PTS) in microseconds. The most significant bit (MSB) flags whether the packet is a configuration packet (SPS/PPS) or keyframe.
   - **4 bytes (uint32):** Big-endian payload size (number of bytes following in this frame).
   - **N bytes:** The actual H.264 NAL unit payload (`0x00000001` prefixed).

---

## 3. Root Cause Analysis

### A. Protocol Framing vs Raw Annex-B Stream
Apple VideoToolbox and hardware NAL unit parsers expect standard Annex-B H.264 (`0x00000001` or `0x000001` start-code delimiters) or AVCC length-prefixed formats. When the 12-byte `scrcpy` protocol framing header (PTS + packet length) was fed directly into the decoder, VideoToolbox treated the timestamp bytes as invalid slice headers or corrupted NAL units, triggering `OSStatus -12909`.

### B. SPS/PPS Parameter Set Extraction
VideoToolbox requires an explicit `CMVideoFormatDescriptionRef` created from Sequence Parameter Sets (SPS - NAL type 7) and Picture Parameter Sets (PPS - NAL type 8) before it can decode standard video slices (NAL type 1 and type 5 IDR frames). If the initial configuration packet is stripped or unparsed, the hardware decoder cannot initialize.

---

## 4. Architectural Solution

### A. Dedicated Socket Framing De-encapsulator
Implemented a streaming packet reader in the native macOS bridge and Dart isolate packet inspector:
1. **Read Stream Header (First 76 bytes):** Consume device name, codec ID, width, and height.
2. **Read 12-Byte Frame Header:** Read 8-byte PTS and 4-byte packet length $L$.
3. **Slice Packet Payload:** Read exactly $L$ bytes into a dedicated buffer.

```dart
// Conceptual packet framing extraction
final ptsBytes = socketStream.readBytes(8);
final pts = ptsBytes.buffer.asByteData().getInt64(0, Endian.big);
final sizeBytes = socketStream.readBytes(4);
final packetLength = sizeBytes.buffer.asByteData().getUint32(0, Endian.big);

final rawPayload = socketStream.readBytes(packetLength);
// Pass rawPayload to VideoToolbox decoder
```

### B. Dynamic SPS/PPS Registration
In the native macOS engine, parse `rawPayload` for NAL types 7 and 8. Call `CMVideoFormatDescriptionCreateFromH264ParameterSets` to initialize the decoder format description before wrapping subsequent IDR and non-IDR frames in `CMSampleBuffer`.

---

## 5. Prevention & Reusability Checklist

- [ ] **Never Treat Protocol Streams as Raw Codec Streams:** Server utilities like `scrcpy`, `vlc`, or `gstreamer` wrap raw video frames in proprietary framing headers containing timestamps and lengths.
- [ ] **Inspect Socket Packets with Isolated Dump Scripts:** Before writing native decoder bindings, always capture raw socket bytes (`scratch/dump_raw_bytes.dart`) and hex-dump the first 256 bytes to verify the framing contract.
- [ ] **Handle Parameter Sets (SPS/PPS) Prior to Frame Injection:** Hardware-accelerated decoders (VideoToolbox on Apple Silicon/Intel) will fail immediately if video slices arrive before SPS/PPS format descriptions are registered.
