import 'package:desk_droid/core/extensions/optional_read_extension.dart';
import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/core/theme/app_typography.dart';
import 'package:desk_droid/features/mcp_status/domain/entities/mcp_activity.dart';
import 'package:desk_droid/features/mcp_status/presentation/cubit/mcp_status_cubit.dart';
import 'package:desk_droid/features/mcp_status/presentation/cubit/mcp_status_state.dart';
import 'package:desk_droid/features/mcp_status/presentation/widgets/mcp_activity_labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// "An AI is controlling this device" badge for the mirroring page, shown
/// while an AI client used [deviceSerial] within the active window.
///
/// Renders nothing without an [McpStatusCubit] above it.
class McpDeviceActivityBanner extends StatelessWidget {
  const McpDeviceActivityBanner({super.key, required this.deviceSerial});

  final String deviceSerial;

  static const double _radius = 18;
  static const double _iconSize = 16;
  static const double _maxWidth = 420;

  @override
  Widget build(BuildContext context) {
    final cubit = context.tryRead<McpStatusCubit>();
    if (cubit == null) return const SizedBox.shrink();
    return BlocSelector<McpStatusCubit, McpStatusState, McpActivityEntry?>(
      bloc: cubit,
      selector: (state) => state is McpStatusLoaded
          ? state.status.activity.activeByDevice[deviceSerial]
          : null,
      builder: (context, entry) {
        if (entry == null) return const SizedBox.shrink();
        return Semantics(
          liveRegion: true,
          child: Container(
            constraints: const BoxConstraints(maxWidth: _maxWidth),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(_radius),
              border: Border.all(color: AppColors.statusSuccess),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.smart_toy_outlined,
                  size: _iconSize,
                  color: AppColors.statusSuccess,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '${McpActivityLabels.client(entry.clientName)} is '
                    'controlling this device · ${entry.event.tool ?? 'tool'}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
