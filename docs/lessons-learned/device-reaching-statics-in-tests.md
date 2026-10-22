# Code That Reaches a Device Needs a Test Seam, Not Luck

## 1. Context & Symptoms

On 2026-10-22, taps and swipes were routed through the scrcpy touch session (`McpFastTouch`), with adb as the fallback. The whole suite still passed on the first run, but for the wrong reason: every mocked `McpAdbClient` threw a `TypeError` when the session asked it for `resolveAdb()` (an unstubbed method returning `null` for a `Future`), the fast path caught it as "unavailable", and the adb fallback ran.

## 2. Diagnostic Traces & Evidence

- The fast path catches any start failure (`on Object`) so production always falls back to adb.
- Mocktail returns `null` from unstubbed methods; for a `Future` return type that is a `TypeError`.
- A test that built a real `McpAdbClient` and tapped would have started a real scrcpy server on whatever phone was connected.

## 3. Root Cause Analysis

The session is reached through a static entry point, invisible to the tests' constructor injection. Passing tests proved only that some failure happened before any device work, not which one.

## 4. Architectural Solution

`McpFastTouch.opener` is the single seam for opening a session. `test/flutter_test_config.dart` sets it, for every test file, to an opener that reports "scrcpy is off in tests", so unit tests always take the adb path deliberately. `test/unit/mcp_fast_touch_test.dart` installs a recording opener and checks the bytes sent for a tap, a double tap, and a swipe, plus the fallback and its one-minute retry pause (`McpFastTouch.reset()` clears it between tests).

## 5. Prevention & Reusability Checklist

- [ ] Give any static path that can reach a device or network a replaceable entry point, and switch it off globally in tests.
- [ ] When a broad `catch` turns failures into a fallback, test the fallback with an explicit failure, not with whatever a mock happens to throw.
- [ ] Reset static caches (failure memory, sessions) in `setUp`.
