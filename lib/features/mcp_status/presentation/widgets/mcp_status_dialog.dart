import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/core/theme/app_typography.dart';
import 'package:desk_droid/features/mcp_status/domain/entities/mcp_binary_status.dart';
import 'package:desk_droid/features/mcp_status/presentation/cubit/mcp_status_cubit.dart';
import 'package:desk_droid/features/mcp_status/presentation/cubit/mcp_status_state.dart';
import 'package:desk_droid/features/mcp_status/presentation/widgets/mcp_clients_section.dart';
import 'package:desk_droid/features/mcp_status/presentation/widgets/mcp_server_section.dart';
import 'package:desk_droid/features/mcp_status/presentation/widgets/mcp_setup_section.dart';
import 'package:desk_droid/features/mcp_status/presentation/widgets/mcp_status_labels.dart';
import 'package:desk_droid/features/mcp_status/presentation/widgets/mcp_status_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Panel with the MCP server details. The header and the footer stay
/// pinned; the body scrolls when the window is short.
class McpStatusDialog extends StatelessWidget {
  const McpStatusDialog({super.key});

  /// Opens the panel and re-checks the status.
  static Future<void> show(BuildContext context) {
    final cubit = context.read<McpStatusCubit>()..load();
    return showDialog<void>(
      context: context,
      builder: (_) =>
          BlocProvider.value(value: cubit, child: const McpStatusDialog()),
    );
  }

  static const double _maxWidth = 540;
  static const double _maxHeightFraction = 0.85;
  static const double _padding = 20;
  static const double _sectionGap = 20;
  static const double _radius = 16;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * _maxHeightFraction;
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radius),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: _maxWidth, maxHeight: maxHeight),
        child: BlocBuilder<McpStatusCubit, McpStatusState>(
          builder: (context, state) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Header(state: state),
              const Divider(height: 1, color: AppColors.border),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(_padding),
                  child: _Body(state: state),
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              _Footer(state: state),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.state});

  final McpStatusState state;

  @override
  Widget build(BuildContext context) {
    final summary = switch (state) {
      McpStatusLoaded(:final status) => McpStatusLabels.overall(status),
      McpStatusFailure() => (text: 'Status unavailable', tone: McpTone.error),
      _ => (text: 'Checking…', tone: McpTone.neutral),
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        McpStatusDialog._padding,
        McpStatusDialog._padding,
        McpStatusDialog._padding / 2,
        McpStatusDialog._padding,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.hub_outlined, color: AppColors.accent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('MCP Server', style: AppTypography.title),
                const SizedBox(height: 4),
                McpStatusLine(label: summary, style: AppTypography.caption),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Close',
            icon: const Icon(Icons.close_rounded, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state});

  final McpStatusState state;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      McpStatusLoaded(:final status) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI assistants (Claude Desktop, Cursor, Antigravity) start this '
            'server themselves to control your Android devices. DeskDroid '
            'does not need to be open; this panel only checks the setup.',
            style: AppTypography.caption,
          ),
          const SizedBox(height: McpStatusDialog._sectionGap),
          McpServerSection(status: status),
          const SizedBox(height: McpStatusDialog._sectionGap),
          McpClientsSection(clients: status.clients),
          if (status.binary.availability != McpBinaryAvailability.missing) ...[
            const SizedBox(height: McpStatusDialog._sectionGap),
            McpSetupSection(
              snippet: context.read<McpStatusCubit>().configurationSnippet,
            ),
          ],
        ],
      ),
      McpStatusFailure(:final message) => Text(
        message,
        style: AppTypography.body,
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.state});

  final McpStatusState state;

  static const double _spinnerSize = 14;
  static const double _buttonGap = 8;

  @override
  Widget build(BuildContext context) {
    final busy =
        state is McpStatusLoading ||
        state is McpStatusInitial ||
        (state is McpStatusLoaded && (state as McpStatusLoaded).isRefreshing);
    return Padding(
      padding: const EdgeInsets.all(McpStatusDialog._padding / 2),
      // Wraps the buttons onto two lines when the window is very narrow.
      child: OverflowBar(
        alignment: MainAxisAlignment.end,
        overflowAlignment: OverflowBarAlignment.end,
        spacing: _buttonGap,
        overflowSpacing: _buttonGap,
        children: [
          TextButton.icon(
            onPressed: busy
                ? null
                : () => context.read<McpStatusCubit>().load(),
            icon: busy
                ? const SizedBox(
                    width: _spinnerSize,
                    height: _spinnerSize,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Refresh'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
