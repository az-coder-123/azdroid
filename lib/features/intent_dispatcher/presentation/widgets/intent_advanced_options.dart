import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Collapsible section for configuring optional target package and component names.
class IntentAdvancedOptions extends StatefulWidget {
  const IntentAdvancedOptions({
    required this.packageController,
    required this.componentController,
    super.key,
  });

  final TextEditingController packageController;
  final TextEditingController componentController;

  @override
  State<IntentAdvancedOptions> createState() => _IntentAdvancedOptionsState();
}

class _IntentAdvancedOptionsState extends State<IntentAdvancedOptions> {
  bool _showAdvanced = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _showAdvanced = !_showAdvanced),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _showAdvanced
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                size: 16,
                color: AppColors.accent,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  _showAdvanced
                      ? 'Hide Package & Component'
                      : 'Show Package & Component Options',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (_showAdvanced) ...[
          const SizedBox(height: 10),
          TextField(
            controller: widget.packageController,
            style: const TextStyle(fontSize: 12),
            decoration: const InputDecoration(
              hintText: 'Target Package (optional, e.g. com.example.app)',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: widget.componentController,
            style: const TextStyle(fontSize: 12),
            decoration: const InputDecoration(
              hintText:
                  'Target Component (optional, e.g. com.example/.MainActivity)',
            ),
          ),
        ],
      ],
    );
  }
}
