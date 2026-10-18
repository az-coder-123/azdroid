# Trackpad Scrolling Did Nothing: Trackpads Send PanZoom, Not Scroll

## 1. Context & Symptoms

The docs promised that two-finger trackpad scrolling scrolls the phone. With a mouse wheel it did; with a MacBook or Windows precision trackpad, nothing reached the phone. The issue surfaced while adding pinch-to-zoom, which also comes from the trackpad.

## 2. Diagnostic Traces & Evidence

- `InputGestureViewportOverlay` handled `onPointerSignal` and scrolled on `PointerScrollEvent` only.
- Flutter 3.47 source: the down, move, and scroll event constructors assert `kind != PointerDeviceKind.trackpad`; trackpads produce only `PointerPanZoomStartEvent`, `PointerPanZoomUpdateEvent` (with `pan`, `scale`, `rotation`), and `PointerPanZoomEndEvent`. Since Flutter 3.3, trackpad scrolling no longer arrives as `PointerScrollEvent`.
- `flutter_test` can produce these events (`TestPointer(…, PointerDeviceKind.trackpad).panZoomStart/Update/End`); the new widget test failed before the handlers existed.

## 3. Root Cause Analysis

The overlay was written against the pre-3.3 model, where the engine turned trackpad gestures into scroll events. Flutter's own `Scrollable` handles pan/zoom internally, so ordinary lists kept working in the app and hid the change. A custom `Listener` gets nothing unless it registers the pan/zoom callbacks.

## 4. Architectural Solution

- The overlay registers `onPointerPanZoomStart/Update/End` and hands them to `TouchGestureTracker`.
- A pan becomes one **live** finger on the phone (DOWN, MOVE, UP), so lists follow the fingers and fling natively; a scale or rotation change becomes a two-finger pinch.
- `multi_touch_gesture_test.dart` sends real trackpad pan/zoom events and checks the stream (and that no `sendScroll` happens for a trackpad).

## 5. Prevention & Reusability Checklist

- [ ] A raw `Listener` that should react to trackpads must handle `onPointerPanZoom*`; `onPointerSignal` sees mouse wheels only.
- [ ] Test input code with every device kind it claims (mouse, trackpad, touch), using `TestPointer` with the right `PointerDeviceKind`.
- [ ] Re-check custom input handling after Flutter upgrades that mention gestures or pointer events.
