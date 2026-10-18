# scrcpy Audio Is a Socket in the Session, Not a Separate Port

## 1. Context & Symptoms

DeskDroid had an audio feature that never played anything. `AudioRepositoryImpl` ran `adb forward tcp:27185 localabstract:scrcpy_<scid>` and opened its own socket on port 27185, while the server ran with `audio=false`. The UI showed an audio button with a fake 15 ms latency.

## 2. Diagnostic Traces & Evidence

- scrcpy v3.3.4 `DesktopConnection.open()`: in forward-tunnel mode one `LocalServerSocket` accepts **video, then audio, then control**. There is no separate audio port; a second forward to the same abstract socket only adds another connection to the same queue.
- `Streamer.writeAudioHeader()` sends a 4-byte codec id; `writeDisableStream()` sends `0` (no capture on Android 10 or older, continue with video) or `1` (configuration error).
- With `audio=true`, the server blocks in `accept()` for the audio socket before it accepts control. A client that never connects audio never gets control, and the session hangs.
- On a Redmi 9 (Android 10) the header is `0`; on an Android 16 emulator it is `\0raw`, followed by PCM packets.

## 3. Root Cause Analysis

The audio feature was designed from the Dart side as an independent stream, without reading how the server opens its sockets. Because the server ran with `audio=false`, the wrong design never met the protocol, so it failed silently instead of loudly.

## 4. Architectural Solution

- The native player is a core service (`IAudioStreamNativeService`), opened by streaming because only streaming knows the socket order. `VideoPipelineLauncher` waits for the video `connected` state, calls `startAudio`, then opens control; a failed audio socket stops everything with `audioConnectFailed`.
- Before the server starts, `isAvailable()` decides `audio=true` or `audio=false`: a platform without a player (`MissingPluginException`) must not start the server with audio, or the session would hang.
- The audio feature now only shows state and sets volume and mute. The separate port, `AudioSocketDatasource`, `AdbPortForwarder`, and the fake entity fields were removed.
- `video_pipeline_launcher_test.dart` checks the order (video, audio, control), the no-player case, and cleanup on failure.

## 5. Prevention & Reusability Checklist

- [ ] Before adding a stream from a server, read how the server accepts its sockets (order, blocking, handshake bytes).
- [ ] A feature that depends on an option being on must be tested with the option on; `audio=false` hid the design error.
- [ ] When a server blocks until a client step happens, decide that step before starting the server, and fail the whole session if it cannot happen.
- [ ] Remove placeholder values (such as a fixed latency) instead of displaying them.
