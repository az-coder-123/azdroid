import 'package:desk_droid/core/models/device_entity.dart';
import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/features/apk_installer/presentation/widgets/apk_installer_dialog.dart';
import 'package:desk_droid/features/control/presentation/widgets/quick_text_input_dialog.dart';
import 'package:desk_droid/features/intent_dispatcher/presentation/widgets/intent_dispatcher_dialog.dart';
import 'package:desk_droid/features/logging/presentation/widgets/device_log_dialog.dart';
import 'package:desk_droid/features/productivity/presentation/cubit/file_transfer_cubit.dart';
import 'package:desk_droid/features/productivity/presentation/cubit/screenshot_cubit.dart';
import 'package:desk_droid/features/productivity/presentation/widgets/device_file_manager_dialog.dart';
import 'package:desk_droid/features/productivity/presentation/widgets/file_drop_target_overlay.dart';
import 'package:desk_droid/features/productivity/presentation/widgets/transfer_status_banner.dart';
import 'package:desk_droid/features/streaming/presentation/cubit/streaming_cubit.dart';
import 'package:desk_droid/features/streaming/presentation/cubit/streaming_state.dart';
import 'package:desk_droid/features/streaming/presentation/widgets/floating_controls_toolbar.dart';
import 'package:desk_droid/features/streaming/presentation/widgets/interactive_display_viewport.dart';
import 'package:desk_droid/features/streaming/presentation/widgets/mirroring_feedback_stack.dart';
import 'package:desk_droid/features/streaming/presentation/widgets/side_controls_toolbar.dart';
import 'package:desk_droid/features/streaming/presentation/widgets/stream_reconfiguring_badge.dart';
import 'package:desk_droid/features/streaming/presentation/widgets/stream_telemetry_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Active mirroring viewport layout with top telemetry, centered phone display,
/// right-side tools dock, bottom navigation toolbar, and overlay feedback cards.
class MirroringActiveView extends StatefulWidget {
  const MirroringActiveView({
    super.key,
    required this.device,
    required this.state,
  });

  final DeviceEntity device;
  final StreamingActive state;

  @override
  State<MirroringActiveView> createState() => _MirroringActiveViewState();
}

class _MirroringActiveViewState extends State<MirroringActiveView> {
  bool _isZenMode = false;

  @override
  Widget build(BuildContext context) {
    return FileDropTargetOverlay(
      deviceSerial: widget.device.serial,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (!_isZenMode)
            SafeArea(
              child: Column(
                children: [
                  // Top Non-overlapping Telemetry Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: StreamTelemetryHeader(
                      session: widget.state.session,
                      telemetry: widget.state.telemetry,
                      isZenMode: _isZenMode,
                      onToggleZenMode: () => setState(() => _isZenMode = true),
                      onClose: context.read<StreamingCubit>().stopSession,
                    ),
                  ),

                  // Dedicated Central Display Viewport with Side Controls Toolbar
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 4.0,
                      ),
                      child: _buildCentralViewport(context),
                    ),
                  ),

                  // Bottom Non-overlapping Controls Toolbar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: FloatingControlsToolbar(
                      session: widget.state.session,
                      onBack: context.read<StreamingCubit>().sendBack,
                      onHome: context.read<StreamingCubit>().sendHome,
                      onAppSwitch: context.read<StreamingCubit>().sendAppSwitch,
                      onRotate: context.read<StreamingCubit>().rotateScreen,
                      onToggleScreenOff: context
                          .read<StreamingCubit>()
                          .toggleScreenOff,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            // Zen Mode: Full-window display viewport
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: InteractiveDisplayViewport(
                session: widget.state.session,
                deviceSerial: widget.device.serial,
                rotationDegrees: widget.state.rotationDegrees,
              ),
            ),

            // Exit Zen Mode Floating Action
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(
                    Icons.fullscreen_exit_rounded,
                    size: 20,
                    color: AppColors.textPrimary,
                  ),
                ),
                tooltip: 'Exit Zen Mode',
                onPressed: () => setState(() => _isZenMode = false),
              ),
            ),
          ],

          // Top-Right Transfer Notification Banner
          Positioned(
            top: 16,
            right: _isZenMode ? 64 : 16,
            child: const TransferStatusBanner(),
          ),

          // Bottom-Right Feedback Toast Banners
          Positioned(
            bottom: _isZenMode ? 24 : 76,
            right: 24,
            child: const MirroringFeedbackStack(),
          ),

          // Pipeline restart feedback (bitrate change)
          if (widget.state.pendingBitrateMbps case final bitrate?)
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: StreamReconfiguringBadge(bitrateMbps: bitrate),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCentralViewport(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final maxH = constraints.maxHeight;

        // Calculate aspect ratio of the stream accounting for active rotation
        final isRotated = (widget.state.rotationDegrees ~/ 90) % 2 != 0;
        final rawW = widget.state.session.width > 0
            ? widget.state.session.width.toDouble()
            : 1080.0;
        final rawH = widget.state.session.height > 0
            ? widget.state.session.height.toDouble()
            : 2400.0;
        final streamW = isRotated ? rawH : rawW;
        final streamH = isRotated ? rawW : rawH;
        final phoneAspect = streamW / streamH;

        // Sidebar dimensions & ergonomic spacing
        const sidebarWidth = 44.0;
        const gap = 16.0;
        const reservedSidebarSpace = sidebarWidth + gap;

        // Available viewport space for the phone screen
        final availableW = (maxW - reservedSidebarSpace - 8.0).clamp(
          100.0,
          maxW,
        );
        final availableH = maxH;

        // Compute FittedBox contain dimensions
        final fitsWidth = (availableW / availableH) > phoneAspect;
        final phoneDisplayH = fitsWidth ? availableH : availableW / phoneAspect;
        final phoneDisplayW = fitsWidth ? availableH * phoneAspect : availableW;

        // Left spacer to keep phone centered in the window when horizontal space permits
        final canCenterSymmetrically =
            maxW > (phoneDisplayW + (reservedSidebarSpace * 2) + 16.0);

        return Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (canCenterSymmetrically)
                const SizedBox(width: reservedSidebarSpace),
              SizedBox(
                width: phoneDisplayW,
                height: phoneDisplayH,
                child: InteractiveDisplayViewport(
                  session: widget.state.session,
                  deviceSerial: widget.device.serial,
                  rotationDegrees: widget.state.rotationDegrees,
                ),
              ),
              const SizedBox(width: gap),
              _buildSideControls(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSideControls(BuildContext context) {
    final s = widget.device.serial;
    return SideControlsToolbar(
      session: widget.state.session,
      deviceSerial: s,
      onSelectBitrate: widget.state.isReconfiguring
          ? null
          : (b) => context.read<StreamingCubit>().updateBitrate(b),
      onScreenshot: () => context.read<ScreenshotCubit>().captureScreenshot(s),
      onCropScreenshot: () =>
          context.read<ScreenshotCubit>().startAreaSelection(s),
      onTextInject: () => QuickTextInputDialog.show(context, s),
      onSendFiles: () =>
          context.read<FileTransferCubit>().pickAndTransferFiles(s),
      onBrowseFiles: () => DeviceFileManagerDialog.show(context, s),
      onViewLogs: () => DeviceLogDialog.show(context, s),
      onInstallApk: () => ApkInstallerDialog.show(context, deviceSerial: s),
      onDispatchIntent: () => IntentDispatcherDialog.show(context, s),
    );
  }
}
