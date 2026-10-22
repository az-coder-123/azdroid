import 'package:equatable/equatable.dart';

/// How a coordinate value was given.
enum McpUnit {
  /// A fraction of the screen (0.0 to 1.0): `xRatio`, `xPercent`.
  ratio,

  /// Physical pixels: `xPixel`, `xPx`.
  pixel,

  /// A raw value (`x`) whose unit is inferred, see [McpPoint.toPixels].
  auto,
}

/// One coordinate value and its unit.
class McpAxis extends Equatable {
  const McpAxis(this.value, this.unit);

  final double value;
  final McpUnit unit;

  @override
  List<Object?> get props => [value, unit];
}

/// A screen point as an MCP client gave it, resolved to pixels in exactly
/// one place ([toPixels]) so every tool reads coordinates the same way.
///
/// Rules:
/// - An explicit unit always wins, per axis: `xRatio` is a fraction and
///   `xPixel` is pixels, whatever the value (`xPixel: 1` is pixel 1).
/// - Raw values (`x`, `y`) are fractions when **both** are within 0.0–1.0
///   (inclusive), otherwise pixels. A raw axis next to an explicit one is a
///   fraction when it is within 0.0–1.0.
class McpPoint extends Equatable {
  const McpPoint(this.x, this.y);

  /// A point already in pixels (element centers, compiled batch steps).
  McpPoint.pixels(num x, num y)
    : x = McpAxis(x.toDouble(), McpUnit.pixel),
      y = McpAxis(y.toDouble(), McpUnit.pixel);

  /// A point given as screen fractions (computed scroll paths).
  McpPoint.ratio(double x, double y)
    : x = McpAxis(x, McpUnit.ratio),
      y = McpAxis(y, McpUnit.ratio);

  final McpAxis x;
  final McpAxis y;

  /// Whether [toPixels] needs the display size; when not, callers can skip
  /// the `wm size` query.
  bool get needsDisplaySize => _isRatio(x, y) || _isRatio(y, x);

  /// Pixel coordinates on a [width] × [height] display (ignored for pixel
  /// axes).
  (int, int) toPixels(int width, int height) =>
      (_resolve(x, y, width), _resolve(y, x, height));

  static int _resolve(McpAxis axis, McpAxis other, int extent) =>
      (_isRatio(axis, other) ? axis.value * extent : axis.value).round();

  static bool _isRatio(McpAxis axis, McpAxis other) => switch (axis.unit) {
    McpUnit.ratio => true,
    McpUnit.pixel => false,
    McpUnit.auto =>
      _isFraction(axis.value) &&
          (other.unit != McpUnit.auto || _isFraction(other.value)),
  };

  static bool _isFraction(double value) => value >= 0.0 && value <= 1.0;

  /// The values as the client gave them, e.g. `(0.5, 0.75)`.
  @override
  String toString() => '(${x.value}, ${y.value})';

  @override
  List<Object?> get props => [x, y];
}
