# Texture Pixel Order: BGRA on macOS, RGBA on Windows

## 1. Context & Symptoms

While porting the video pipeline to Windows (Phase 1a), the first version of the shared converter was `ConvertNv12ToBgra`, copied from what the macOS pipeline produces. Had it shipped, the Windows viewport would have shown every frame with **red and blue swapped**: skin looks blue and the Android status bar color is wrong. No test or crash would have pointed at the cause.

## 2. Diagnostic Traces & Evidence

| Platform | Texture type | Expected bytes per pixel |
|:---|:---|:---|
| macOS | `CVPixelBuffer` from VideoToolbox, `kCVPixelFormatType_32BGRA` | B, G, R, A |
| Windows | `flutter::PixelBufferTexture` → `FlutterDesktopPixelBuffer` | **R, G, B, A** |
| Windows (Phase 1b) | DXGI shared texture, `DXGI_FORMAT_B8G8R8A8_UNORM` | B, G, R, A |

The mismatch was found by reading the Flutter Windows texture API while writing `frame_texture.cpp`, before any Windows build existed.

## 3. Root Cause Analysis

The converter encoded one platform's convention as a hidden assumption in its **name and body**. "32-bit pixel" is not a format: the byte order belongs to the consumer, and the two Flutter embedders disagree. Even on Windows the right order changes between the CPU path (1a) and the GPU path (1b).

## 4. Architectural Solution

- `scrcpy_core::ConvertNv12(image, PixelOrder order, out, stride)` takes the order explicitly (`kRgba`, `kBgra`).
- The frame type is the neutral `PixelFrame`; the producer chooses the order.
- `StreamSession::PublishFrame` passes `PixelOrder::kRgba` with a comment naming the Flutter requirement.
- Tests check BT.709 red in both orders (`Nv12Bt709PrimaryRed`, `Nv12RgbaOrderPutsRedFirst`).
- `docs/native-video-contract.md` lists the pixel order per platform.

## 5. Prevention & Reusability Checklist

- [ ] Never name a pixel buffer "BGRA" or "RGBA" in shared code without a parameter; make the order an argument.
- [ ] For every new texture path, look up the consumer's required format before writing the producer.
- [ ] Test color conversion with a saturated primary (pure red), not only black and white, which hide channel swaps.
- [ ] Record per-platform pixel formats in the native contract document.
