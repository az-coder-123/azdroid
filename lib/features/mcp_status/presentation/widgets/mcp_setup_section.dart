import 'package:desk_droid/core/theme/app_typography.dart';
import 'package:desk_droid/features/guide/presentation/widgets/components/guide_command_snippet.dart';
import 'package:flutter/material.dart';

/// The configuration an AI client needs, with a copy button.
class McpSetupSection extends StatelessWidget {
  const McpSetupSection({super.key, required this.snippet});

  final String snippet;

  static const double _gap = 8;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Set Up an AI Client', style: AppTypography.subtitle),
        const SizedBox(height: _gap),
        const Text(
          'Add this to the client\'s MCP configuration file (shown above), '
          'merging it with any servers already there, then restart the client.',
          style: AppTypography.caption,
        ),
        const SizedBox(height: _gap),
        GuideCommandSnippet(command: snippet),
      ],
    );
  }
}
