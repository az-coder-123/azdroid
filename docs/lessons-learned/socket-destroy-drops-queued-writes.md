# `Socket.destroy()` Dropped the Last Control Message

## 1. Context & Symptoms

Stopping a mirroring session with Screen Off active must send "display on" and then close the control socket. `SocketScrcpyControlChannel.close()` called `socket.destroy()` right after the message was queued, so the message could be lost. The phone would then stay dark until the server's restore process noticed the exit.

## 2. Diagnostic Traces & Evidence

- `Socket.add` only queues bytes; `destroy()` closes both directions at once and discards what is not yet written.
- A loopback test queued 4 MiB and then closed. With `destroy()` only, the peer received **1,118,872** of 4,194,304 bytes. With `await socket.flush()` first, it received all of them.

## 3. Root Cause Analysis

The channel was written for a stream of small input events, where losing the tail on close does not matter. A command that must arrive **because** the session ends (display on) changes that. Small messages usually arrive anyway on loopback, which hides the bug.

## 4. Architectural Solution

- `close()` now awaits `socket.flush()` with a 500 ms bound, logs (never throws) when the flush fails, then destroys the socket.
- The test above stays in `test/unit/scrcpy_control_channel_test.dart`, and it was checked to fail without the flush.
- `cleanup=true` remains the safety net when Azdroid cannot send at all (crash, disconnect).

## 5. Prevention & Reusability Checklist

- [ ] Before `destroy()`, ask whether queued data must arrive; if so, `flush()` (with a timeout) first.
- [ ] Test socket shutdown with a payload larger than the socket buffer; tiny payloads hide data loss.
- [ ] Keep a server-side or out-of-band fallback for "must happen on exit" actions.
