# Touch Mapping Used a Hard-Coded Frame Size

## 1. Context & Symptoms

Before the control socket, taps were mapped from normalized positions (0.0 – 1.0) to pixels with `ControlConstants` defaults of 1080×2400 on **every** device, because `ControlBloc` never passed the real size. `adb shell input` hid the error on 1080×2400 phones. On other sizes, taps landed off target. With the scrcpy control socket, a wrong size is worse: the server **ignores** the event.

## 2. Diagnostic Traces & Evidence

- `ControlRepositoryImpl` accepted optional `width`/`height`, and every caller left them null.
- Redmi 9: display 1080×2340, but the video stream header says 1080×2336. With `log_level=verbose`, the server logs an `Ignore positional event …` line for every event whose size differs from the current video size.
- The verification tool sends one tap with the stream size and one with width + 8. Only the second produces the two "Ignore" lines (DOWN and UP).

## 3. Root Cause Analysis

The input layer had no source of truth for the size it maps to. Defaults made the code look complete, and the old adb path accepted any coordinates without a size check, so nothing failed loudly. The correct size is the **video frame** size, which can differ from the display size and changes on rotation.

## 4. Architectural Solution

- Domain contract `VideoFrameSizeSource` (`Future<FrameSize?> current()`), implemented by `NativeVideoFrameSizeSource` with the plugin's `getDimensions`; `0x0` means unknown.
- `ControlRepositoryImpl` uses an explicit size, else the frame source. The same `FrameSize` is sent with the touch message, so the mapped position and the size check always agree.
- With no known size, `ScrcpyControlDatasource` declines and the adb fallback handles the event.
- macOS reads the size from the SPS presentation dimensions (clean aperture), which matched the header (1080×2336) on real SPS bytes.

## 5. Prevention & Reusability Checklist

- [ ] Never default a device-specific value (resolution, density) in mapping code; make "unknown" explicit and handle it.
- [ ] Map coordinates against the frame the user sees, not the device display.
- [ ] Add a test with a non-default size (for example landscape 1920×1080) so a hidden default fails.
- [ ] When a protocol validates input against a value, send the same value that was used to compute the input.
