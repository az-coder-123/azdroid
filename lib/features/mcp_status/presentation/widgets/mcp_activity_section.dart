import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/core/theme/app_typography.dart';
import 'package:desk_droid/features/mcp_status/domain/entities/mcp_activity.dart';
import 'package:desk_droid/features/mcp_status/presentation/widgets/mcp_activity_labels.dart';
import 'package:desk_droid/features/mcp_status/presentation/widgets/mcp_status_labels.dart';
import 'package:desk_droid/features/mcp_status/presentation/widgets/mcp_status_line.dart';
import 'package:flutter/material.dart';

/// The connected AI sessions and their latest tool calls.
class McpActivitySection extends StatelessWidget {
  const McpActivitySection({super.key, required this.activity});

  final McpActivitySnapshot activity;

  static const double _gap = 8;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Live Activity', style: AppTypography.subtitle),
        const SizedBox(height: _gap),
        if (activity.sessions.isEmpty && activity.recent.isEmpty)
          const Text(
            'No tool calls yet. They appear here as an AI client works.',
            style: AppTypography.caption,
          ),
        for (final session in activity.sessions) ...[
          _SessionRow(session: session, activity: activity),
          const SizedBox(height: _gap),
        ],
        if (activity.recent.isNotEmpty) ...[
          const SizedBox(height: _gap / 2),
          Text(
            'Recent tool calls',
            style: AppTypography.caption.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: _gap / 2),
          for (final entry in activity.recent)
            Padding(
              padding: const EdgeInsets.only(bottom: _gap / 2),
              child: Text(
                '${McpActivityLabels.time(entry.event.at)}  '
                '${McpActivityLabels.client(entry.clientName)}: '
                '${McpActivityLabels.call(entry.event)}',
                style: AppTypography.code.copyWith(
                  color: entry.event.succeeded == false
                      ? AppColors.statusError
                      : null,
                ),
              ),
            ),
        ],
        const SizedBox(height: _gap / 2),
        Text(
          'Only tool names, devices, results, and durations are recorded, '
          'never what the AI types.',
          style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
        ),
      ],
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.session, required this.activity});

  final McpSessionActivity session;
  final McpActivitySnapshot activity;

  @override
  Widget build(BuildContext context) {
    final last = session.lastCall;
    final serial = last?.deviceSerial;
    final controlling =
        serial != null && activity.activeByDevice[serial]?.pid == session.pid;
    return McpStatusLine(
      label: (
        text:
            '${McpActivityLabels.client(session.clientName)} '
            '(since ${McpActivityLabels.time(session.startedAt)}): '
            '${last == null ? 'no tool calls yet' : 'last ${McpActivityLabels.call(last)} at ${McpActivityLabels.time(last.at)}'}',
        tone: controlling ? McpTone.success : McpTone.info,
      ),
    );
  }
}
