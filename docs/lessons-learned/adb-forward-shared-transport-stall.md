# An Unread Video Socket Stalls the Control Socket

## 1. Context & Symptoms

While adding the scrcpy control socket, the verification tool sent HOME and BACK through control on an Android 16 emulator. The server accepted the socket, but the keys had no visible effect, and the "Ignore positional event" log lines for the size check arrived late or never. The same messages worked on a real phone in an earlier run.

## 2. Diagnostic Traces & Evidence

- The tool read 30 video packets, then stopped reading the video socket while it kept the socket open.
- A minimal Python client that **kept draining video** in a background thread sent the same control bytes: BACK closed Settings, and both expected "Ignore positional event" lines appeared at once.
- Changing only the drain behavior in the Dart tool (`StreamProbe` keeps a background `drain()` until `close()`) made the emulator run pass.

## 3. Root Cause Analysis

`adb forward` multiplexes every forwarded socket of a device over **one adb transport**. When the client stops reading one stream, adb's buffers for that stream fill, flow control pauses the shared transport, and other streams on the same device (here the control socket) stop moving too. The server was fine; the client starved its own control channel by leaving video unread.

A fast real phone with a short run can hide this, because the stall only starts once the buffers fill.

## 4. Architectural Solution

- The contract now states that native code must read video for the whole session ([native-video-contract.md](../native-video-contract.md)). Both native plugins already do this: they decode every packet until `stopStream`.
- `tool/scrcpy_verify/stream_probe.dart` drains video in the background after its packet check, and stops only in `close()`.
- `ScrcpyControlChannel` also drains incoming device messages, so the reverse direction cannot fill up either.

## 5. Prevention & Reusability Checklist

- [ ] Every socket forwarded through adb must be read until it is closed, even when its data is not needed.
- [ ] A test client that stops reading early must close the socket, not leave it open.
- [ ] When one adb-forwarded channel stops working, check whether another channel to the same device is unread before blaming the device.
- [ ] Reproduce on a slow target (emulator) as well; buffer-related stalls appear later on fast devices.
