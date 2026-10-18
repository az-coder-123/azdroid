import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/features/mcp_status/presentation/cubit/mcp_status_cubit.dart';
import 'package:desk_droid/features/mcp_status/presentation/cubit/mcp_status_state.dart';
import 'package:desk_droid/features/mcp_status/presentation/widgets/mcp_status_dialog.dart';
import 'package:desk_droid/features/mcp_status/presentation/widgets/mcp_status_labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Toolbar button that shows the MCP server state as a colored dot (or the
/// number of connected AI sessions) and opens [McpStatusDialog].
///
/// Reads [McpStatusCubit] from above (provided app-wide in main.dart).
class McpStatusIndicator extends StatelessWidget {
  const McpStatusIndicator({super.key});

  static const double _iconSize = 19;
  static const double _dotSize = 8;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<McpStatusCubit, McpStatusState>(
      builder: (context, state) {
        final (tooltip, tone, sessions) = switch (state) {
          McpStatusLoaded(:final status) => (
            'MCP server: ${McpStatusLabels.overall(status).text}',
            McpStatusLabels.overall(status).tone,
            status.binary.isReady ? (status.runningSessions ?? 0) : 0,
          ),
          McpStatusFailure() => (
            'MCP server: status unavailable',
            McpTone.error,
            0,
          ),
          McpStatusInitial() ||
          McpStatusLoading() => ('MCP server: checking…', null, 0),
        };
        const icon = Icon(
          Icons.hub_outlined,
          size: _iconSize,
          color: AppColors.textSecondary,
        );
        return IconButton(
          tooltip: tooltip,
          splashRadius: 20,
          onPressed: () => McpStatusDialog.show(context),
          icon: switch ((tone, sessions)) {
            (null, _) => icon,
            (final McpTone t, final int n) when n > 0 => Badge.count(
              count: n,
              backgroundColor: t.color,
              textColor: AppColors.background,
              child: icon,
            ),
            (final McpTone t, _) => Badge(
              smallSize: _dotSize,
              backgroundColor: t.color,
              child: icon,
            ),
          },
        );
      },
    );
  }
}
