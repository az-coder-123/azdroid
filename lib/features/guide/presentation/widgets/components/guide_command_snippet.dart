import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:desk_droid/core/theme/app_colors.dart';

/// Interactive terminal command box with 1-click copy to clipboard and visual feedback.
class GuideCommandSnippet extends StatefulWidget {
  const GuideCommandSnippet({super.key, required this.command});

  final String command;

  @override
  State<GuideCommandSnippet> createState() => _GuideCommandSnippetState();
}

class _GuideCommandSnippetState extends State<GuideCommandSnippet> {
  bool _isCopied = false;
  Timer? _resetTimer;

  void _copy() {
    Clipboard.setData(ClipboardData(text: widget.command));
    setState(() => _isCopied = true);
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isCopied = false);
    });
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.terminal_rounded,
            size: 16,
            color: AppColors.accentLight,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.command,
              style: const TextStyle(
                fontFamily: 'SF Mono',
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          InkWell(
            onTap: _copy,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _isCopied
                    ? AppColors.statusSuccess.withValues(alpha: 0.2)
                    : AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isCopied ? Icons.check_rounded : Icons.copy_rounded,
                    size: 12,
                    color: _isCopied
                        ? AppColors.statusSuccess
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isCopied ? 'Copied' : 'Copy',
                    style: TextStyle(
                      fontSize: 11,
                      color: _isCopied
                          ? AppColors.statusSuccess
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
