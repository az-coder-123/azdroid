import 'package:flutter/material.dart';
import 'package:desk_droid/core/constants/control_constants.dart';
import 'package:desk_droid/core/theme/app_colors.dart';

/// Data representing an active on-screen touch ripple.
class TouchPoint {
  TouchPoint({required this.position, required this.timestamp});
  final Offset position;
  final DateTime timestamp;
}

/// Visual feedback overlay rendering smooth touch ripples where clicks or taps occur.
class TouchIndicatorOverlay extends StatefulWidget {
  const TouchIndicatorOverlay({
    required this.child,
    this.enabled = true,
    super.key,
  });

  final Widget child;
  final bool enabled;

  @override
  State<TouchIndicatorOverlay> createState() => TouchIndicatorOverlayState();
}

class TouchIndicatorOverlayState extends State<TouchIndicatorOverlay>
    with SingleTickerProviderStateMixin {
  final List<TouchPoint> _points = [];
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController =
        AnimationController(
          vsync: this,
          duration: const Duration(
            milliseconds: ControlConstants.touchIndicatorFadeMs,
          ),
        )..addListener(() {
          if (mounted) setState(() {});
        });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  /// Registers a touch position to trigger an animated ripple.
  void addTouch(Offset localPosition) {
    if (!widget.enabled) return;
    _points.add(TouchPoint(position: localPosition, timestamp: DateTime.now()));
    _animController.forward(from: 0.0).then((_) {
      if (mounted) {
        final cutoff = DateTime.now().subtract(
          const Duration(milliseconds: ControlConstants.touchIndicatorFadeMs),
        );
        _points.removeWhere((p) => p.timestamp.isBefore(cutoff));
        if (mounted) setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _TouchPainter(
        points: _points,
        fadeProgress: _animController.value,
      ),
      child: widget.child,
    );
  }
}

class _TouchPainter extends CustomPainter {
  _TouchPainter({required this.points, required this.fadeProgress});

  final List<TouchPoint> points;
  final double fadeProgress;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final alpha = ((1.0 - fadeProgress) * 0.45).clamp(0.0, 1.0);
    final paintRing = Paint()
      ..color = AppColors.accent.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final paintFill = Paint()
      ..color = AppColors.accent.withValues(alpha: alpha * 0.5)
      ..style = PaintingStyle.fill;

    for (final point in points) {
      final currentRadius =
          ControlConstants.touchIndicatorRadius * (0.8 + fadeProgress * 0.5);
      canvas.drawCircle(point.position, currentRadius, paintFill);
      canvas.drawCircle(point.position, currentRadius, paintRing);
    }
  }

  @override
  bool shouldRepaint(covariant _TouchPainter oldDelegate) {
    return oldDelegate.fadeProgress != fadeProgress ||
        oldDelegate.points.length != points.length;
  }
}
