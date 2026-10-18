# Documentation Described Features the Code Did Not Have

## 1. Context & Symptoms

Several feature descriptions in `README.md` and `docs/` promised behavior that no code implemented. Users and contributors could not tell planned features from shipped ones.

| Claim in the docs | What the code did |
|:---|:---|
| Adaptive resolution presets (720p, 1080p, 2K, Native) | No `max_size` was ever sent; the stream is always the phone's native resolution. |
| 60 / 90 / 120 FPS | `max_fps=60` always; no caller passes another value. |
| Optional H.265/HEVC | Only `h264` is decoded on both platforms. |
| Automatic bitrate scaling (2–20 Mbps by jitter) | Three manual presets (4 / 8 / 16 Mbps). |
| Sub-30 ms ("20–35 ms") glass-to-glass latency | Never measured; the app measures host processing time only. |
| Earlier, fixed in their own changes | Screen Off with display power ([lesson](screen-off-power-key-slept-device.md)), audio on Android 10+ with lip-sync ([lesson](scrcpy-audio-socket-order.md)), multi-touch, `Cmd`+`O` and `Cmd`+`R` ([lesson](documented-shortcut-not-wired.md)). |

The dead `AppSettingsEntity` (frame rate, bitrate, screen off, auto reconnect, audio) matched these claims: it looked like a settings model, but nothing read it and no settings screen existed.

## 2. Diagnostic Traces & Evidence

- `grep -rn "max_size" lib` returned nothing; `ScrcpyServerCommand` builds every server option.
- `StreamingCubit.startSession(device)` is called without `maxFps`, so `StreamingRepositoryImpl` uses 60.
- `grep -rn AppSettingsEntity lib test` found only its own file.

## 3. Root Cause Analysis

The docs were written as a product vision, then kept as if they described the product. Nothing checked a claim against the code, and placeholder types (the settings entity) made the claims look backed.

## 4. Architectural Solution

- The claims now state what the code does (native resolution, up to 60 FPS, H.264, manual bitrate presets, measured host processing time) and name missing options as not implemented.
- The unused `settings` feature was deleted, and the architecture tree updated.
- Feature-specific fixes each came with a test or an on-device check, recorded in their own lessons.

## 5. Prevention & Reusability Checklist

- [ ] Every capability in user docs points to the code or server option that provides it.
- [ ] Mark planned work as planned (backlog), never in the present tense in feature docs.
- [ ] Numbers in docs (latency, FPS, battery) are either measured, with how, or left out.
- [ ] Delete placeholder models that nothing reads; they make unbuilt features look real.
