# scrcpy Control Socket: Connect Between the Dummy Byte and the Header

## 1. Context & Symptoms

Azdroid ran scrcpy-server with `control=false` and read the 77-byte stream header in one call. Switching to `control=true` with the same native code would hang: the native plugin waits for the header, and the server never sends it.

## 2. Diagnostic Traces & Evidence

- scrcpy v3.3.4 source, `DesktopConnection.open()` in forward-tunnel mode: it accepts the video socket and writes the dummy byte, then accepts the control socket, and only after that does the caller send the device name and codec meta.
- The verification tool confirmed the order on a Redmi 9 and an Android 16 emulator: the header arrived only after the control socket connected.

## 3. Root Cause Analysis

With control enabled, the server needs every socket before it sends any metadata. The native plugin owns the video socket, while the control socket belongs to Dart (input is a Dart feature). Reading the whole header first blocks the plugin forever, and Dart has no signal to tell when the server is ready for control.

Connecting control too early is also wrong: on the forward tunnel, the first accepted socket becomes the video socket.

## 4. Architectural Solution

- Native code reads the dummy byte, sets the new `getStats` state `connected`, then reads the rest of the header (`ScrcpyStreamPlugin.swift`, `stream_session.cpp`, `scrcpy_core::StreamState::kConnected`).
- `ScrcpyControlConnector` polls `getStats` until `connected`, then opens `ScrcpyControlChannel` on the same port. It gives up on `failed`, `ended`, or a timeout.
- `StreamingRepositoryImpl` fails the start with `controlConnectFailed`, stops the stream and the server, and shows a clear message. A mirror that silently ignores input is worse than a clear error.
- The order is part of [native-video-contract.md](../native-video-contract.md), so both platforms follow it.

## 5. Prevention & Reusability Checklist

- [ ] When enabling a scrcpy option that adds a socket (control, audio), re-read `DesktopConnection` for the accept and send order.
- [ ] Expose handshake progress as an explicit state when two layers own different sockets of one session.
- [ ] Keep the socket order in the shared native contract, not only in code comments.
- [ ] Clean up the whole session (stream and server) when any one socket fails to open.
