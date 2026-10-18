import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/core/theme/app_typography.dart';
import 'package:desk_droid/features/mcp_status/domain/entities/mcp_client_status.dart';
import 'package:desk_droid/features/mcp_status/presentation/widgets/mcp_status_labels.dart';
import 'package:desk_droid/features/mcp_status/presentation/widgets/mcp_status_line.dart';
import 'package:flutter/material.dart';

/// Whether each known AI client is set up to launch the DeskDroid server.
class McpClientsSection extends StatelessWidget {
  const McpClientsSection({super.key, required this.clients});

  final List<McpClientStatus> clients;

  static const double _gap = 8;
  static const double _rowPadding = 10;
  static const double _radius = 8;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('AI Clients', style: AppTypography.subtitle),
        const SizedBox(height: _gap),
        for (final client in clients) ...[
          _ClientRow(client: client),
          const SizedBox(height: _gap),
        ],
      ],
    );
  }
}

class _ClientRow extends StatelessWidget {
  const _ClientRow({required this.client});

  final McpClientStatus client;

  @override
  Widget build(BuildContext context) {
    final command = client.configuredCommand;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(McpClientsSection._rowPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(McpClientsSection._radius),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(client.name, style: AppTypography.body),
          const SizedBox(height: McpClientsSection._gap / 2),
          McpStatusLine(
            label: McpStatusLabels.client(client),
            style: AppTypography.caption,
          ),
          const SizedBox(height: McpClientsSection._gap / 2),
          SelectableText(client.configPath, style: AppTypography.caption),
          if (client.setup == McpClientSetup.configuredElsewhere &&
              command != null) ...[
            const SizedBox(height: McpClientsSection._gap / 2),
            SelectableText('Runs: $command', style: AppTypography.code),
          ],
        ],
      ),
    );
  }
}
