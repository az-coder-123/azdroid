# Layout Math Assumed a Widget Width: 2-Pixel Overflow Beside the Phone

## 1. Context & Symptoms

Mirroring a landscape device (rk3566 board, 1920×1080) on macOS showed the debug overflow stripes and `RIGHT OVERFLOWED BY 2.0 PIXELS` over the side tools dock. The dock was drawn over the right edge of the video. Portrait phones looked fine, because they are limited by height and leave spare width.

## 2. Diagnostic Traces & Evidence

`MirroringActiveView._buildCentralViewport` sized the phone display by hand:

```dart
const sidebarWidth = 44.0; // assumed toolbar width
const gap = 16.0;
final availableW = maxW - (sidebarWidth + gap) - 8.0;
// Row(min): [phone (availableW wide), gap, SideControlsToolbar]
```

For a width-limited (landscape) stream the row needs `(maxW - 68) + 16 + T`. With the real toolbar width `T = 54` that is `maxW + 2`: exactly the reported overflow. The real width is 6 + 40 + 6 padding plus a 1 px border on each side. The 40 px comes from `IconButton` in **compact** visual density, which Flutter uses on desktop. With standard density (Android, default tests), it is 48 px, so the toolbar is 62 px wide and the overflow would be 10 px.

## 3. Root Cause Analysis

The layout duplicated a widget's size as a constant instead of letting the framework measure it. The toolbar's width depends on its padding, border, and the platform's visual density, none of which the constant tracked. The only margin was an unexplained `8.0`, so any width above 52 px overflowed. Tests never exercised a width-limited stream, so it went unnoticed until a landscape device was mirrored.

## 4. Architectural Solution

- `MirroringCentralViewport` (new widget) uses `Row([Expanded(display area), gap, toolbar])`. The toolbar keeps its natural width and the display gets what is left, so the row cannot overflow for any toolbar width.
- `placePhoneDisplay` (pure function) fits the display to the stream aspect ratio inside that area. It centers the display in the whole window when there is room, and otherwise shifts it only as far as needed. The display box keeps the exact aspect ratio, which input mapping (normalized 0–1 positions) depends on.
- Tests: unit tests for `placePhoneDisplay`, and a widget test grid of toolbar widths (44, 54, 62) × window sizes (including 420 px wide) × aspect ratios (landscape, portrait, square) that asserts no overflow exception and the display/toolbar bounds.

## 5. Prevention & Reusability Checklist

- [ ] Never copy a widget's rendered size into a constant for layout math. Use `Expanded`/`Flexible`, or measure with `LayoutBuilder`.
- [ ] Remember that Material control sizes change with `VisualDensity` (compact on desktop, standard on mobile and in default tests).
- [ ] Test layouts with both landscape and portrait content: they hit different limits (width vs height).
- [ ] Test layout widgets over a grid of sizes, including widths of the neighbors, and assert `tester.takeException()` is null.
- [ ] A magic margin (like a bare `8.0`) that "makes it fit" is a sign the math is missing a term.
