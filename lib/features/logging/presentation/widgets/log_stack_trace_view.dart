import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Formatted stack trace viewer highlighting exception headers, causes, and caller frames.
class LogStackTraceView extends StatelessWidget {
  const LogStackTraceView({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final lines = message.split('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: lines.map((line) {
        final trimmed = line.trim();
        final isExceptionHeader =
            trimmed.contains('Exception') ||
            trimmed.contains('Error:') ||
            trimmed.startsWith('Caused by:');
        final isStackFrame = trimmed.startsWith('at ');

        Color textColor = AppColors.textPrimary;
        FontWeight weight = FontWeight.normal;

        if (isExceptionHeader) {
          textColor = AppColors.statusError;
          weight = FontWeight.w600;
        } else if (isStackFrame) {
          textColor = AppColors.textSecondary;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 1.0),
          child: SelectableText(
            line,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              fontWeight: weight,
              color: textColor,
            ),
          ),
        );
      }).toList(),
    );
  }
}
