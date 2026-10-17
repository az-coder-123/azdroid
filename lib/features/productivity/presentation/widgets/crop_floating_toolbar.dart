import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:desk_droid/features/productivity/domain/entities/screenshot_destination.dart';
import 'package:desk_droid/features/productivity/presentation/widgets/crop_action_toolbar.dart';

/// Positioned wrapper positioning the [CropActionToolbar] dynamically above or below
/// the current selection rectangle within the viewport bounds.
class CropFloatingToolbar extends StatelessWidget {
  const CropFloatingToolbar({
    super.key,
    required this.selectionRect,
    required this.viewportSize,
    required this.onSelectDestination,
    required this.onCancel,
  });

  final Rect selectionRect;
  final Size viewportSize;
  final ValueChanged<ScreenshotDestination> onSelectDestination;
  final VoidCallback onCancel;

  static const double _toolbarWidth = 275.0;
  static const double _toolbarHeight = 40.0;

  @override
  Widget build(BuildContext context) {
    final maxLeft = math
        .max(12.0, viewportSize.width - _toolbarWidth - 12.0)
        .toDouble();
    final left =
        (selectionRect.left + (selectionRect.width / 2) - (_toolbarWidth / 2))
            .clamp(12.0, maxLeft);
    final fitsBelow =
        selectionRect.bottom + 10 + _toolbarHeight < viewportSize.height;
    final top = fitsBelow
        ? selectionRect.bottom + 10.0
        : (math.max(
            10.0,
            selectionRect.top - 10.0 - _toolbarHeight,
          )).toDouble();

    return Positioned(
      left: left,
      top: top,
      child: CropActionToolbar(
        onSelect: onSelectDestination,
        onCancel: onCancel,
      ),
    );
  }
}
