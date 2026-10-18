import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/core/theme/app_typography.dart';
import 'package:desk_droid/features/mcp_status/domain/entities/mcp_binary_status.dart';
import 'package:desk_droid/features/mcp_status/domain/entities/mcp_server_status.dart';
import 'package:desk_droid/features/mcp_status/presentation/widgets/mcp_status_labels.dart';
import 'package:desk_droid/features/mcp_status/presentation/widgets/mcp_status_line.dart';
import 'package:flutter/material.dart';

/// The bundled server executable and the AI sessions running it now.
class McpServerSection extends StatelessWidget {
  const McpServerSection({super.key, required this.status});

  final McpServerStatus status;

  static const String rosettaCommand = 'softwareupdate --install-rosetta';
  static const double _gap = 8;

  @override
  Widget build(BuildContext context) {
    final binary = status.binary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Server', style: AppTypography.subtitle),
        const SizedBox(height: _gap),
        McpStatusLine(label: McpStatusLabels.binary(binary)),
        const SizedBox(height: _gap),
        SelectableText(binary.executablePath, style: AppTypography.code),
        if (binary.architectures.isNotEmpty) ...[
          const SizedBox(height: _gap / 2),
          Text(
            'Built for ${McpStatusLabels.architectures(binary.architectures)}',
            style: AppTypography.caption,
          ),
        ],
        if (binary.availability == McpBinaryAvailability.needsRosetta) ...[
          const SizedBox(height: _gap),
          const Text(
            'Install Rosetta 2 in Terminal, then press Refresh:',
            style: AppTypography.caption,
          ),
          const SizedBox(height: _gap / 2),
          const SelectableText(rosettaCommand, style: AppTypography.code),
        ],
        if (binary.availability == McpBinaryAvailability.missing) ...[
          const SizedBox(height: _gap),
          const Text(
            'Release builds include the server. From a source checkout, '
            'point your AI client at scripts/start_mcp_server.sh.',
            style: AppTypography.caption,
          ),
        ],
        const SizedBox(height: _gap * 2),
        const Text('Sessions', style: AppTypography.subtitle),
        const SizedBox(height: _gap),
        McpStatusLine(label: McpStatusLabels.sessions(status.runningSessions)),
        const SizedBox(height: _gap / 2),
        Text(
          'Each connected AI client runs its own server process.',
          style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
        ),
      ],
    );
  }
}
