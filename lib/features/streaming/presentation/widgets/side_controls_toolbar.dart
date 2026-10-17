import 'package:desk_droid/core/platform/shortcuts/shortcut_scheme.dart';
import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/features/productivity/presentation/widgets/clipboard_sync_menu_button.dart';
import 'package:desk_droid/features/productivity/presentation/widgets/screen_record_button.dart';
import 'package:desk_droid/features/streaming/domain/entities/stream_session_entity.dart';
import 'package:flutter/material.dart';

/// Vertical actions toolbar placed beside the real-time phone display
/// providing fast access to quality bitrate settings, screenshots, screen recording,
/// text injection, file transfer, APK installation, and intent dispatching.
class SideControlsToolbar extends StatelessWidget {
  const SideControlsToolbar({
    super.key,
    required this.session,
    required this.onSelectBitrate,
    this.onScreenshot,
    this.onCropScreenshot,
    this.onTextInject,
    this.onSendFiles,
    this.onBrowseFiles,
    this.onViewLogs,
    this.onInstallApk,
    this.onDispatchIntent,
    this.deviceSerial,
  });

  final StreamSessionEntity session;
  final ValueChanged<int> onSelectBitrate;
  final VoidCallback? onScreenshot;
  final VoidCallback? onCropScreenshot;
  final VoidCallback? onTextInject;
  final VoidCallback? onSendFiles;
  final VoidCallback? onBrowseFiles;
  final VoidCallback? onViewLogs;
  final VoidCallback? onInstallApk;
  final VoidCallback? onDispatchIntent;
  final String? deviceSerial;

  @override
  Widget build(BuildContext context) {
    final keys = context.shortcuts;
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
              itemBuilder: (context) =>
                  const [
                        (4, '4 Mbps (Eco / Weak Wi-Fi)'),
                        (8, '8 Mbps (Standard 1080p)'),
                        (16, '16 Mbps (Ultra / 60+ FPS)'),
                      ]
                      .map((b) => PopupMenuItem(value: b.$1, child: Text(b.$2)))
                      .toList(),
            ),

            if (onScreenshot != null ||
                onCropScreenshot != null ||
                deviceSerial != null ||
                onTextInject != null) ...[
              const SizedBox(height: 6),
              _buildDivider(),
              const SizedBox(height: 6),

              // Lossless Full Phone Screenshot
              if (onScreenshot != null)
                _buildToolButton(
                  icon: Icons.camera_alt_outlined,
                  tooltip: 'Take Screenshot (${keys.label('S')})',
                  onPressed: onScreenshot!,
                ),

              // Regional / Partial Screenshot
              if (onCropScreenshot != null) ...[
                const SizedBox(height: 4),
                _buildToolButton(
                  icon: Icons.crop_rounded,
                  tooltip: 'Capture Area (${keys.label('S', shift: true)})',
                  onPressed: onCropScreenshot!,
                ),
              ],

              // Screen Recording Toggle
              if (deviceSerial != null) ...[
                const SizedBox(height: 4),
                ScreenRecordButton(deviceSerial: deviceSerial!),
              ],

              // Quick Text Injection (Unicode / IME)
              if (onTextInject != null) ...[
                const SizedBox(height: 4),
                _buildToolButton(
                  icon: Icons.keyboard_alt_outlined,
                  tooltip: 'Inject Text (${keys.label('K')})',
                  onPressed: onTextInject!,
                ),
              ],

              // Clipboard Synchronization Menu
              if (deviceSerial != null) ...[
                const SizedBox(height: 4),
                ClipboardSyncMenuButton(deviceSerial: deviceSerial!),
              ],

              // Send Files from Mac to Phone (Finder Picker)
              if (onSendFiles != null) ...[
                const SizedBox(height: 4),
                _buildToolButton(
                  icon: Icons.file_upload_outlined,
                  tooltip: 'Send Files to Phone (${keys.label('U')})',
                  onPressed: onSendFiles!,
                ),
              ],

              // Browse & Download Android Files to Mac
              if (onBrowseFiles != null) ...[
                const SizedBox(height: 4),
                _buildToolButton(
                  icon: Icons.folder_shared_outlined,
                  tooltip:
                      'Device Files & Downloads (${keys.label('F', shift: true)})',
                  onPressed: onBrowseFiles!,
                ),
              ],

              // Real-time Android Logcat Console
              if (onViewLogs != null) ...[
                const SizedBox(height: 4),
                _buildToolButton(
                  icon: Icons.terminal_rounded,
                  tooltip:
                      'Device Logcat Console (${keys.label('L', shift: true)})',
                  onPressed: onViewLogs!,
                ),
              ],

              // Sideload & Install APK Package
              if (onInstallApk != null) ...[
                const SizedBox(height: 4),
                _buildToolButton(
                  icon: Icons.install_mobile_rounded,
                  tooltip:
                      'Install APK Package (${keys.label('I', shift: true)})',
                  onPressed: onInstallApk!,
                ),
              ],

              // Deep Link & Intent Dispatcher
              if (onDispatchIntent != null) ...[
                const SizedBox(height: 4),
                _buildToolButton(
                  icon: Icons.alt_route_rounded,
                  tooltip:
                      'Deep Link & Intent Dispatcher (${keys.label('D', shift: true)})',
                  onPressed: onDispatchIntent!,
                ),
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
    Color? color,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8.0),
        hoverColor: AppColors.surfaceElevated,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(icon, size: 20.0, color: color ?? AppColors.textPrimary),
        ),
      ),
    );
  }
}
