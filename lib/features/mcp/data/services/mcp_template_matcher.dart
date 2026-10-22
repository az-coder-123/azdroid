import 'dart:math';

import 'package:desk_droid/features/mcp/data/services/mcp_gray_image.dart';
import 'package:desk_droid/features/mcp/data/utils/mcp_argument_helper.dart';
import 'package:equatable/equatable.dart';
import 'package:image/image.dart' as img;

/// Where a template image was found on a screenshot, in screen pixels.
class McpImageMatch extends Equatable {
  const McpImageMatch({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.score,
    required this.scale,
  });

  final int left;
  final int top;
  final int width;
  final int height;

  /// Normalized cross-correlation, 1.0 for a perfect match.
  final double score;

  /// Template size on screen relative to the template file.
  final double scale;

  int get centerX => left + width ~/ 2;
  int get centerY => top + height ~/ 2;

  @override
  List<Object?> get props => [left, top, width, height, score, scale];
}

/// Finds a picture (a game sprite, a button image, a crop of an earlier
/// screenshot) on the screen, for screens with no accessibility tree such
/// as games drawn with OpenGL, Vulkan, or a game engine.
///
/// Searches a reduced screenshot first, then refines around the best spot
/// at full resolution. Grayscale correlation ignores brightness and
/// contrast changes but not rotation.
class McpTemplateMatcher {
  const McpTemplateMatcher._();

  /// Width of the reduced screenshot for the first pass.
  static const int coarseWidth = 240;

  /// Template side range (pixels) in the first pass: small enough to scan
  /// fast, large enough to keep detail.
  static const int minCoarseSide = 8;
  static const int maxCoarseSide = 40;

  /// Resolution step between refinement passes.
  static const double refineStep = 3;

  /// Sizes tried when the template does not match at its own size.
  static const List<double> fallbackScales = [
    0.5,
    0.67,
    0.75,
    1.25,
    1.5,
    2,
    2.5,
    3,
  ];

  /// The best match of [template] on [screen]. With no [scale], it tries
  /// the template's own size first, then [fallbackScales] when that scores
  /// below [threshold].
  static McpImageMatch find(
    img.Image screen,
    img.Image template, {
    double threshold = 0.8,
    double? scale,
  }) {
    if (McpGrayImage.from(template).isFlat) {
      throw const McpArgumentException(
        'The template is one flat color; crop a region with some detail.',
      );
    }
    McpImageMatch? best;
    for (final s in scale != null ? [scale] : [1.0, ...fallbackScales]) {
      final match = _findAtScale(screen, template, s);
      if (match != null && (best == null || match.score > best.score)) {
        best = match;
      }
      if (scale == null && s == 1.0 && (best?.score ?? 0) >= threshold) break;
    }
    if (best == null) {
      throw const McpArgumentException(
        'The template is larger than the screen at every size tried.',
      );
    }
    return best;
  }

  static McpImageMatch? _findAtScale(
    img.Image screen,
    img.Image template,
    double scale,
  ) {
    final tw = (template.width * scale).round();
    final th = (template.height * scale).round();
    if (tw < 2 || th < 2 || tw > screen.width || th > screen.height) {
      return null;
    }
    // Pass 1: a reduced copy, small enough to scan every position.
    final side = min(tw, th);
    var f = min(
      1.0,
      max(
        minCoarseSide / side,
        min(coarseWidth / screen.width, maxCoarseSide / side),
      ),
    );
    final coarse = McpGrayImage.from(
      screen,
      width: max(1, (screen.width * f).round()),
      height: max(1, (screen.height * f).round()),
    );
    final first = coarse.bestMatch(_scaled(template, tw, th, f));
    if (first.score < 0) return null;
    var hit = (score: first.score, x: first.x / f, y: first.y / f);

    // Refine: each pass searches only around the previous hit, at a higher
    // resolution, up to full resolution.
    while (f < 1) {
      final margin = (2 / f).ceil() + 2;
      f = min(1.0, f * refineStep);
      final x0 = max(0, hit.x.round() - margin);
      final y0 = max(0, hit.y.round() - margin);
      final w = min(screen.width - x0, tw + 2 * margin);
      final h = min(screen.height - y0, th + 2 * margin);
      final region = img.copyCrop(screen, x: x0, y: y0, width: w, height: h);
      final found = McpGrayImage.from(
        region,
        width: max(1, (w * f).round()),
        height: max(1, (h * f).round()),
      ).bestMatch(_scaled(template, tw, th, f));
      if (found.score < 0) break;
      hit = (score: found.score, x: x0 + found.x / f, y: y0 + found.y / f);
    }
    return McpImageMatch(
      left: hit.x.round(),
      top: hit.y.round(),
      width: tw,
      height: th,
      score: hit.score,
      scale: scale,
    );
  }

  static McpGrayImage _scaled(img.Image template, int tw, int th, double f) =>
      McpGrayImage.from(
        template,
        width: max(1, (tw * f).round()),
        height: max(1, (th * f).round()),
      );
}
