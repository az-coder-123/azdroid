import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/features/streaming/domain/entities/stream_session_entity.dart';
import 'package:flutter/material.dart';

/// Stream launch options at the top of the side toolbar: the bitrate menu
/// and the "keep the phone awake" toggle. Changing either restarts the
/// stream, so both are disabled (callbacks `null`) while a change applies.
class StreamSettingsControls extends StatelessWidget {
  const StreamSettingsControls({
    super.key,
    required this.session,
    required this.onSelectBitrate,
  });

  final StreamSessionEntity session;
  final ValueChanged<int>? onSelectBitrate;

  static const double _iconSize = 20;
  static const List<(int, String)> _bitrates = [
    (4, '4 Mbps (Eco / Weak Wi-Fi)'),
    (8, '8 Mbps (Standard 1080p)'),
    (16, '16 Mbps (Ultra / 60+ FPS)'),
  ];

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      tooltip: 'Streaming Bitrate & Quality',
      enabled: onSelectBitrate != null,
      icon: const Icon(
        Icons.tune_rounded,
        size: _iconSize,
        color: AppColors.textPrimary,
      ),
      color: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: const BorderSide(color: AppColors.border),
      ),
      initialValue: session.bitrateMbps,
      onSelected: onSelectBitrate,
      itemBuilder: (context) => [
        for (final (mbps, label) in _bitrates)
          PopupMenuItem(value: mbps, child: Text(label)),
      ],
    );
  }
}
