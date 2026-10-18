import 'package:desk_droid/core/theme/app_typography.dart';
import 'package:desk_droid/features/mcp_status/presentation/widgets/mcp_status_labels.dart';
import 'package:flutter/material.dart';

/// A colored dot followed by a status text that wraps on narrow widths.
class McpStatusLine extends StatelessWidget {
  const McpStatusLine({super.key, required this.label, this.style});

  final McpLabel label;
  final TextStyle? style;

  static const double _dotSize = 8;
  static const double _gap = 8;

  @override
  Widget build(BuildContext context) {
    final textStyle = style ?? AppTypography.body;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          // Centers the dot on the first text line.
          padding: EdgeInsets.only(
            top:
                ((textStyle.fontSize ?? _dotSize) * (textStyle.height ?? 1.2) -
                    _dotSize) /
                2,
          ),
          child: Container(
            width: _dotSize,
            height: _dotSize,
            decoration: BoxDecoration(
              color: label.tone.color,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: _gap),
        Expanded(child: Text(label.text, style: textStyle)),
      ],
    );
  }
}
