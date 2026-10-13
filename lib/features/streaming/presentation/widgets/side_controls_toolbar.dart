import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wifi_desk/core/theme/app_colors.dart';
import 'package:wifi_desk/features/productivity/presentation/cubit/screen_recording_cubit.dart';
import 'package:wifi_desk/features/productivity/presentation/cubit/screen_recording_state.dart';
import 'package:wifi_desk/features/productivity/presentation/widgets/clipboard_sync_menu_button.dart';
import 'package:wifi_desk/features/streaming/domain/entities/stream_session_entity.dart';

/// Vertical actions toolbar placed beside the real-time phone display
/// providing fast access to quality bitrate settings, screenshots, screen recording,
/// text injection, and clipboard sync.
class SideControlsToolbar extends StatelessWidget {
  const SideControlsToolbar({
    super.key,
    required this.session,
    required this.onSelectBitrate,
    this.onScreenshot,
    this.onCropScreenshot,
    this.onTextInject,
    this.deviceSerial,
  });

  final StreamSessionEntity session;
  final ValueChanged<int> onSelectBitrate;
  final VoidCallback? onScreenshot;
  final VoidCallback? onCropScreenshot;
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
                  tooltip: 'Take Screenshot (Cmd+S)',
                  onPressed: onScreenshot!,
                ),

              // Regional / Partial Screenshot
              if (onCropScreenshot != null) ...[
                const SizedBox(height: 4),
                _buildToolButton(
                  icon: Icons.crop_rounded,
                  tooltip: 'Capture Area (Cmd+Shift+S)',
                  onPressed: onCropScreenshot!,
                ),
              ],

              // Screen Recording Toggle
              if (deviceSerial != null) ...[
                const SizedBox(height: 4),
                _buildScreenRecordButton(context),
              ],

              // Quick Text Injection (Unicode / IME)
              if (onTextInject != null) ...[
                const SizedBox(height: 4),
                _buildToolButton(
                  icon: Icons.keyboard_alt_outlined,
                  tooltip: 'Inject Text (Cmd+K)',
                  onPressed: onTextInject!,
                ),
              ],

              // Clipboard Synchronization Menu
              if (deviceSerial != null) ...[
                const SizedBox(height: 4),
                ClipboardSyncMenuButton(deviceSerial: deviceSerial!),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScreenRecordButton(BuildContext context) {
    return BlocBuilder<ScreenRecordingCubit, ScreenRecordingState>(
      builder: (context, state) {
        final isRecording = state is ScreenRecordingActive;
        final isPreparing = state is ScreenRecordingPreparing;
        final isCountdown = state is ScreenRecordingCountdown;
        final isFinalizing = state is ScreenRecordingFinalizing;

        if (isFinalizing) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.accent,
              ),
            ),
          );
        }

        final IconData icon;
        final String tooltip;
        final Color? color;
        final VoidCallback onPressed;

        if (isRecording) {
          icon = Icons.stop_circle_rounded;
          tooltip = 'Stop Recording (REC)';
          color = AppColors.statusError;
          onPressed = () =>
              context.read<ScreenRecordingCubit>().stopRecording();
        } else if (isCountdown) {
          icon = Icons.hourglass_top_rounded;
          tooltip = 'Counting down (Cancel)';
          color = AppColors.statusError;
          onPressed = () =>
              context.read<ScreenRecordingCubit>().cancelPreparation();
        } else if (isPreparing) {
          icon = Icons.videocam_rounded;
          tooltip = 'Cancel Recording Setup';
          color = AppColors.statusError;
          onPressed = () =>
              context.read<ScreenRecordingCubit>().cancelPreparation();
        } else {
          icon = Icons.videocam_outlined;
          tooltip = 'Record Screen (Cmd+Shift+R)';
          color = null;
          onPressed = () => context
              .read<ScreenRecordingCubit>()
              .prepareRecording(deviceSerial!);
        }

        return _buildToolButton(
          icon: icon,
          tooltip: tooltip,
          color: color,
          onPressed: onPressed,
        );
      },
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
