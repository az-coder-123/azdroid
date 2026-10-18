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

**Full audit of the docs and the in-app text (second pass).** Each claim was checked against the code; the ones below were wrong and are now corrected:

| Where | Claim | What the code does |
|:---|:---|:---|
| Feature docs, user guide, shortcuts, in-app guide | Quick Text Injector types Vietnamese, CJK, emoji "flawlessly" | `adb shell input text` only, which types ASCII. A lesson even described a clipboard-paste path as implemented; only the MCP server had it. **Fixed afterwards in code** (scrcpy `SET_CLIPBOARD` with paste), verified on a Redmi 9. |
| Docs, in-app catalog | Logcat streams "at 60 FPS" | Batches every 100 ms. |
| Docs, in-app catalog | "Lossless" MP4, 4–24 Mbps and resolution presets | `screenrecord` H.264 at 8 Mbps, at most 180 s; no recording options in the UI. |
| Docs | Area crop by "hardware SurfaceFlinger sub-region crop" | Full `screencap`, cropped on the computer. |
| Docs, in-app catalog | Multi-touch emulation | One pointer. |
| Docs, in-app guide | <kbd>Cmd</kbd>+<kbd>Tab</kbd> opens the app switcher on macOS | macOS keeps Cmd+Tab for its own app switcher; use the toolbar button (Ctrl+Tab works on Windows). |
| Docs, in-app guide | <kbd>Cmd</kbd>+<kbd>R</kbd> rotates the device display | Rotates the mirror view on the computer. |
| Docs | Automatic session recovery with heartbeats | A failed stream stops with a Retry button; no automatic reconnect. |
| Docs | Discovery: 150 ms probes, ports 37000–44000, latency badges, marketing model names | 400 ms probes; 5555, plus 5554/5556/5558 for known addresses; full /24 sweep; status badges; the ADB model name (`M2004J19C`). |
| Docs, in-app catalog | Save 70 % battery, reduce heat by 70 % | Never measured. |
| Docs, in-app catalog | Real-time / instant clipboard sync | Every 2 seconds. |
| README, docs index | Clipboard shortcuts Cmd+C / Cmd+V | Automatic, or Cmd+Shift+C / Cmd+Shift+V. |
| In-app catalog | H.265 option in Settings; "Keyboard Capture" toggle; dual-pane file manager; APK permission preview; Cmd+B for Back; "< 30 ms" | None exists (no Settings screen, no toggle, one pane, no permission list, Back is Cmd+Backspace, latency not measured). |
| In-app catalog | Menu bar companion as a working feature | Planned; now labelled as such. |
| MCP doc | "40 tools", "100 % precision" | 58 tools; taps the center of the matching element. |

Checked and **correct**: zero telemetry (no network calls besides example URLs), 5,000-line logcat buffer, ARP and mDNS discovery, APK flags `-r -g -t -d` and failure diagnoses, 58 MCP tools, screenshot destinations (default: file and clipboard), clipboard loop prevention and `clipper` fallback, button labels named in the user guide.

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
- [ ] Audit the in-app copy (feature catalog, guide) with the docs; users read it first.
- [ ] When a check uses `grep … | head -1`, a missing hit in the first file proves nothing; search every file before concluding a label or feature is absent.
