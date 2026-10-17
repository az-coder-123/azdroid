import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// Shown over the viewport while the video pipeline restarts with a new
/// bitrate, so the brief black frame does not look like a failure.
class StreamReconfiguringBadge extends StatelessWidget {
  const StreamReconfiguringBadge({super.key, required this.bitrateMbps});

  final int bitrateMbps;

  static const double _spinnerSize = 14;
  static const double _spinnerStroke = 2;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: _spinnerSize,
            height: _spinnerSize,
            child: CircularProgressIndicator(
              strokeWidth: _spinnerStroke,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              'Applying $bitrateMbps Mbps…',
              style: AppTypography.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
