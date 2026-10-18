# A Stopped Reader Thread Could Feed the Next Session

## 1. Context & Symptoms

The first macOS audio plugin kept one `running` flag and one socket for all sessions. Review of the restart path (bitrate or keep-awake change: `stopAudio` then `startAudio`) found two defects before any device run:

| Defect | Effect |
|:---|:---|
| `stop()` closed the socket from the platform thread while the reader thread used it | Data race on the descriptor (undefined behavior, would show under Thread Sanitizer). |
| The old reader checked the shared `running` flag, which the next `start()` set to `true` again | The old reader could keep reading its old socket and push stale audio into the buffer the new session had just cleared. |

## 2. Diagnostic Traces & Evidence

- The reader blocks in `recv()` for up to one second (`SO_RCVTIMEO`) before it looks at the flag; `start()` runs well within that second during a pipeline restart.
- Both defects follow from shared mutable state between "the session that is ending" and "the session that is starting".

## 3. Root Cause Analysis

Lifecycle state was owned by the plugin, which outlives sessions, instead of by each session. A first fix with a generation counter worked but spread the session check over many call sites.

## 4. Architectural Solution

- `ScrcpyAudioSession` (macOS) and `AudioSession` (Windows) own their socket, stop flag, state, and output. The plugin or channel only holds the current session and the jitter buffer (so volume and mute survive restarts).
- The reader thread closes its own socket when it exits. `stop()` only sets the session's flag and stops its output.
- Pushes into the shared buffer happen under the session lock and re-check the flag, so nothing lands after `stop()` returns. Windows joins the thread in `Stop()`.

## 5. Prevention & Reusability Checklist

- [ ] Give each connection its own object with its own stop flag; never let a long-lived owner's flag decide whether an old thread continues.
- [ ] A thread that uses a resource closes it; other threads only signal.
- [ ] Shared resources (here the jitter buffer) are touched under a lock that `stop()` also takes.
- [ ] Review every stop-then-start path, not only first start and final stop.
