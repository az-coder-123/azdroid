import 'package:flutter/material.dart';
import 'package:wifi_desk/features/logging/domain/entities/log_level.dart';

/// Compact badge widget rendering an Android logcat severity indicator.
class LogLevelBadge extends StatelessWidget {
  const LogLevelBadge({super.key, required this.level, this.compact = false});

  final LogLevel level;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = level.color;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 4.0 : 6.0,
        vertical: 1.5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.75),
      ),
      child: Text(
        level.code,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: compact ? 10.0 : 11.0,
          fontWeight: FontWeight.w700,
          color: color,
          height: 1.1,
        ),
      ),
    );
  }
}
