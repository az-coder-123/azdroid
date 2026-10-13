import 'package:flutter/material.dart';
import 'package:wifi_desk/core/theme/app_colors.dart';
import 'package:wifi_desk/features/productivity/presentation/widgets/clipboard_sync_menu_button.dart';
import 'package:wifi_desk/features/streaming/domain/entities/stream_session_entity.dart';

/// Vertical actions toolbar placed beside the real-time phone display
/// providing fast access to quality bitrate settings, screenshots, text injection, and clipboard sync.
class SideControlsToolbar extends StatelessWidget {
  const SideControlsToolbar({
    super.key,
    required this.session,
    required this.onSelectBitrate,
    this.onScreenshot,
    this.onTextInject,
    this.deviceSerial,
  });

  final StreamSessionEntity session;
  final ValueChanged<int> onSelectBitrate;
  final VoidCallback? onScreenshot;
  final VoidCallback? onTextInject;
  final String? deviceSerial;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 8.0),
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Stream Quality & Bitrate Settings
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

            if (onScreenshot != null ||
                onTextInject != null ||
                deviceSerial != null) ...[
              const SizedBox(height: 6),
              _buildDivider(),
              const SizedBox(height: 6),

              // Lossless Phone Screenshot
              if (onScreenshot != null)
                _buildToolButton(
                  icon: Icons.camera_alt_outlined,
                  tooltip: 'Take Screenshot (Cmd+S)',
                  onPressed: onScreenshot!,
                ),

              // Quick Text Injection (Unicode / IME)
              if (onTextInject != null) ...[
                if (onScreenshot != null) const SizedBox(height: 6),
                _buildToolButton(
                  icon: Icons.keyboard_alt_outlined,
                  tooltip: 'Inject Text (Cmd+K)',
                  onPressed: onTextInject!,
                ),
              ],

              // Clipboard Synchronization Menu
              if (deviceSerial != null) ...[
                const SizedBox(height: 6),
                ClipboardSyncMenuButton(deviceSerial: deviceSerial!),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(width: 24.0, height: 1.0, color: AppColors.borderSubtle);
  }

  Widget _buildToolButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8.0),
        hoverColor: AppColors.surfaceElevated,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(icon, size: 20.0, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
