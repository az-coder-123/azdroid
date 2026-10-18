import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// Places the phone display inside the area left of the side toolbar.
///
/// The display keeps the stream [aspectRatio] (width / height) and is as
/// large as [area] allows. Horizontally it is centered in the whole window
/// ([windowWidth]) when the area has room for that, otherwise it moves as
/// little as needed to stay inside [area]. The result never exceeds [area].
Rect placePhoneDisplay({
  required Size area,
  required double windowWidth,
  required double aspectRatio,
  double leftOffset = 0.0,
}) {
  if (area.isEmpty || aspectRatio <= 0 || !aspectRatio.isFinite) {
    return Rect.zero;
  }
  final fitsHeight = area.width / area.height > aspectRatio;
  final width = fitsHeight ? area.height * aspectRatio : area.width;
  final height = fitsHeight ? area.height : area.width / aspectRatio;

  final windowCenteredLeft = (windowWidth - width) / 2 - leftOffset;
  final left = math.min(
    math.max(0.0, windowCenteredLeft),
    math.max(0.0, area.width - width),
  );
  final top = (area.height - height) / 2;
  return Rect.fromLTWH(left, top, width, height);
}
