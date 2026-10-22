import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// A grayscale image for template matching (luminance 0–255).
class McpGrayImage {
  McpGrayImage(this.width, this.height, this.pixels);

  /// [image] in grayscale, resized to [width] × [height] when given.
  factory McpGrayImage.from(img.Image image, {int? width, int? height}) {
    final src = width == null || height == null
        ? image
        : img.copyResize(
            image,
            width: width,
            height: height,
            interpolation: img.Interpolation.average,
          );
    final pixels = Float32List(src.width * src.height);
    var i = 0;
    for (final p in src) {
      pixels[i++] = img.getLuminanceRgb(p.r, p.g, p.b).toDouble();
    }
    return McpGrayImage(src.width, src.height, pixels);
  }

  /// A small copy [width] pixels wide, keeping the aspect ratio.
  factory McpGrayImage.thumbnail(img.Image image, int width) =>
      McpGrayImage.from(
        image,
        width: width,
        height: max(1, (image.height * width / image.width).round()),
      );

  final int width;
  final int height;
  final Float32List pixels;

  /// Pixels whose gray level moved by more than this count as changed.
  static const int changeLevel = 24;

  /// The fraction of pixels that differ from [other], skipping the top
  /// [ignoreTop] of the rows (status bar). 1.0 when the sizes differ
  /// (the screen rotated).
  double changedFraction(McpGrayImage other, {double ignoreTop = 0}) {
    if (width != other.width || height != other.height) return 1;
    final start = (height * ignoreTop).round() * width;
    if (start >= pixels.length) return 0;
    var changed = 0;
    for (var i = start; i < pixels.length; i++) {
      if ((pixels[i] - other.pixels[i]).abs() > changeLevel) changed++;
    }
    return changed / (pixels.length - start);
  }

  /// Whether the image is flat (no detail to match on).
  bool get isFlat {
    var lo = double.infinity, hi = double.negativeInfinity;
    for (final v in pixels) {
      lo = min(lo, v);
      hi = max(hi, v);
    }
    return hi - lo < 8;
  }

  /// The position where [template] matches best, by normalized
  /// cross-correlation (1.0 = identical up to brightness and contrast,
  /// 0 = unrelated). Window sums come from integral images, so only the
  /// cross term is computed per position.
  ({double score, int x, int y}) bestMatch(McpGrayImage template) {
    final tw = template.width, th = template.height;
    if (tw > width || th > height) return (score: -1, x: 0, y: 0);
    final n = tw * th;
    var tSum = 0.0;
    for (final v in template.pixels) {
      tSum += v;
    }
    final tMean = tSum / n;
    final t = Float32List(n);
    var tNorm = 0.0;
    for (var i = 0; i < n; i++) {
      t[i] = template.pixels[i] - tMean;
      tNorm += t[i] * t[i];
    }
    tNorm = sqrt(tNorm);
    if (tNorm < 1e-6) return (score: -1, x: 0, y: 0);

    final (sum, sumSq) = _integrals();
    final stride = width + 1;
    var best = (score: -1.0, x: 0, y: 0);
    for (var y = 0; y <= height - th; y++) {
      for (var x = 0; x <= width - tw; x++) {
        final a = y * stride + x, b = a + tw, c = a + th * stride, d = c + tw;
        final s = sum[d] - sum[b] - sum[c] + sum[a];
        final s2 = sumSq[d] - sumSq[b] - sumSq[c] + sumSq[a];
        final variance = s2 - s * s / n;
        if (variance < 1e-3) continue;
        var cross = 0.0;
        for (var j = 0; j < th; j++) {
          final row = (y + j) * width + x, tRow = j * tw;
          for (var i = 0; i < tw; i++) {
            cross += t[tRow + i] * pixels[row + i];
          }
        }
        final score = cross / (sqrt(variance) * tNorm);
        if (score > best.score) best = (score: score, x: x, y: y);
      }
    }
    return best;
  }

  /// Integral images of the values and of their squares.
  (Float64List, Float64List) _integrals() {
    final stride = width + 1;
    final sum = Float64List(stride * (height + 1));
    final sumSq = Float64List(stride * (height + 1));
    for (var y = 0; y < height; y++) {
      var rowSum = 0.0, rowSq = 0.0;
      for (var x = 0; x < width; x++) {
        final v = pixels[y * width + x];
        rowSum += v;
        rowSq += v * v;
        final k = (y + 1) * stride + x + 1;
        sum[k] = sum[k - stride] + rowSum;
        sumSq[k] = sumSq[k - stride] + rowSq;
      }
    }
    return (sum, sumSq);
  }
}
