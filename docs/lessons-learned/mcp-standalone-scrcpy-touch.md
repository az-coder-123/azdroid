# The MCP Server's scrcpy Touch Path Never Ran

## 1. Context & Symptoms

`android_pinch_gesture` and `android_rotate_gesture` were documented as "true multi-touch over scrcpy when mirroring is active", with a one-finger adb fallback. On 2026-10-22, while adding timed multi-finger input for games, it turned out that the standalone `azdroid-mcp` process had never taken the scrcpy path: every pinch had been the fallback (double-tap, then drag), and every device test of it had passed on that fallback.

## 2. Diagnostic Traces & Evidence

```dart
// McpAdbGestureOps.pinchGesture
if (GetIt.I.isRegistered<ControlDatasource>()) { … _streamPinch … }
```

`ControlDatasource` is registered only by the Flutter app (`lib/core/di/modules/control_di.dart`). `bin/azdroid_mcp.dart` builds a `McpProtocolHandler` and never touches GetIt; the MCP server is a separate process from the app, so it cannot reach the app's socket anyway.

## 3. Root Cause Analysis

The feature was written as if the MCP server lived inside the app. The branch compiled, the fallback produced a plausible success message ("Injected pinch gesture"), and nothing reported which path ran.

## 4. Architectural Solution

`McpScrcpyTouchSession` starts a control-only scrcpy server owned by the MCP process: `video=false`, `audio=false`, its own jar path (`/data/local/tmp/azdroid-mcp-scrcpy.jar`), a random non-zero `scid` (the app uses 0), `cleanup=false`, `power_on=false`. With no video the server injects raw coordinates, so no frame size has to match. The session is reused per device, closed after 2 idle minutes and when the client disconnects. Strokes (`McpTouchTimeline`) become DOWN/MOVE/UP events per finger, sent on schedule by `McpTouchPlayer`. Pinch and rotate are strokes too; their results now say "Two-finger … (scrcpy)" or "One-finger approximation …" with the reason.

Verified on a Moto g play (Android 13) beside Azdroid's own mirroring session: Pointer location showed "P: 2 / 2"; events left within 4–6 ms of schedule; on a Redmi 9 (Android 10) the session started and played with 6 ms lag.

## 5. Prevention & Reusability Checklist

- [ ] For each process entry point (`bin/`), check which services it registers before relying on a lookup.
- [ ] A fallback must say in its result that it was used.
- [ ] Verify a "real" path by an observable effect (Pointer location's pointer count), not by the tool's success message.
