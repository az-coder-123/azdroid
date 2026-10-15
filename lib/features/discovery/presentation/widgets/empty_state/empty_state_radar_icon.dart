import 'package:flutter/material.dart';
import 'package:desk_droid/core/theme/app_colors.dart';

/// Animated central hero icon with concentric radar pulse ripples when scanning.
class EmptyStateRadarIcon extends StatefulWidget {
  const EmptyStateRadarIcon({super.key, required this.isScanning});

  final bool isScanning;

  @override
  State<EmptyStateRadarIcon> createState() => _EmptyStateRadarIconState();
}

class _EmptyStateRadarIconState extends State<EmptyStateRadarIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeOutQuad,
    );

    if (widget.isScanning) {
      _pulseController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant EmptyStateRadarIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isScanning != oldWidget.isScanning) {
      if (widget.isScanning) {
        _pulseController.repeat();
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Radar pulse waves when actively searching
          if (widget.isScanning)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                final scale = 1.0 + (_pulseAnimation.value * 0.45);
                final opacity = (1.0 - _pulseAnimation.value).clamp(0.0, 1.0);
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.accent.withValues(
                          alpha: opacity * 0.6,
                        ),
                        width: 2,
                      ),
                    ),
                  ),
                );
              },
            ),

          // Central badge
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.surfaceElevated, AppColors.surface],
              ),
              border: Border.all(
                color: widget.isScanning
                    ? AppColors.accentLight
                    : AppColors.border,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.isScanning
                      ? AppColors.accent.withValues(alpha: 0.25)
                      : Colors.black.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.devices_other_rounded,
              size: 36,
              color: widget.isScanning
                  ? AppColors.accentLight
                  : AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}
