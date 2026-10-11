import 'package:flutter/material.dart';
import 'package:wifi_desk/core/theme/app_colors.dart';
import 'package:wifi_desk/features/streaming/domain/entities/stream_session_entity.dart';

/// Floating HUD toolbar providing quick access to Android navigation and stream controls.
class FloatingControlsToolbar extends StatelessWidget {
  const FloatingControlsToolbar({
    super.key,
    required this.session,
    required this.onBack,
    required this.onHome,
    required this.onAppSwitch,
    required this.onRotate,
    required this.onToggleScreenOff,
    required this.onSelectBitrate,
  });

  final StreamSessionEntity session;
  final VoidCallback onBack;
  final VoidCallback onHome;
  final VoidCallback onAppSwitch;
  final VoidCallback onRotate;
  final VoidCallback onToggleScreenOff;
  final ValueChanged<int> onSelectBitrate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Android System Navigation Keys
          _buildToolButton(
            icon: Icons.arrow_back_rounded,
            tooltip: 'Back (Right Click)',
            onPressed: onBack,
          ),
          const SizedBox(width: 8),
          _buildToolButton(
            icon: Icons.circle_outlined,
            tooltip: 'Home (Cmd+H / Middle Click)',
            onPressed: onHome,
          ),
          const SizedBox(width: 8),
          _buildToolButton(
            icon: Icons.crop_square_rounded,
            tooltip: 'App Switcher (Cmd+Tab)',
            onPressed: onAppSwitch,
          ),
          const SizedBox(width: 12),
          _buildDivider(),
          const SizedBox(width: 12),

          // Display & Stream Controls
          _buildToolButton(
            icon: Icons.rotate_right_rounded,
            tooltip: 'Rotate Display',
            onPressed: onRotate,
          ),
          const SizedBox(width: 8),
          _buildToolButton(
            icon: session.isScreenOff
                ? Icons.screen_lock_portrait_rounded
                : Icons.stay_current_portrait_rounded,
            tooltip: session.isScreenOff
                ? 'Turn Phone Screen On'
                : 'Turn Phone Screen Off (--turn-screen-off)',
            color: session.isScreenOff ? AppColors.statusWarning : null,
            onPressed: onToggleScreenOff,
          ),
          const SizedBox(width: 8),
          PopupMenuButton<int>(
            tooltip: 'Streaming Bitrate & Quality',
            icon: const Icon(
              Icons.tune_rounded,
              size: 20,
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
              const PopupMenuItem(
                value: 4,
                child: Text('4 Mbps (Eco / Weak Wi-Fi)'),
              ),
              const PopupMenuItem(
                value: 8,
                child: Text('8 Mbps (Standard 1080p)'),
              ),
              const PopupMenuItem(
                value: 16,
                child: Text('16 Mbps (Ultra / 60+ FPS)'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 20, color: AppColors.border);
  }

  Widget _buildToolButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return IconButton(
      tooltip: tooltip,
      icon: Icon(icon, size: 20, color: color ?? AppColors.textPrimary),
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(),
      splashRadius: 20,
      onPressed: onPressed,
    );
  }
}
