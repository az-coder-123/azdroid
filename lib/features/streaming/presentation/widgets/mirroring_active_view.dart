import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wifi_desk/core/theme/app_colors.dart';
import 'package:wifi_desk/features/control/presentation/widgets/input_gesture_viewport_overlay.dart';
import 'package:wifi_desk/features/control/presentation/widgets/quick_text_input_dialog.dart';
import 'package:wifi_desk/features/discovery/domain/entities/device_entity.dart';
import 'package:wifi_desk/features/productivity/presentation/cubit/screenshot_cubit.dart';
import 'package:wifi_desk/features/productivity/presentation/widgets/file_drop_target_overlay.dart';
import 'package:wifi_desk/features/productivity/presentation/widgets/screen_recording_feedback_banner.dart';
import 'package:wifi_desk/features/productivity/presentation/widgets/screenshot_feedback_banner.dart';
import 'package:wifi_desk/features/productivity/presentation/widgets/transfer_status_banner.dart';
import 'package:wifi_desk/features/streaming/presentation/cubit/streaming_cubit.dart';
import 'package:wifi_desk/features/streaming/presentation/cubit/streaming_state.dart';
import 'package:wifi_desk/features/streaming/presentation/widgets/floating_controls_toolbar.dart';
import 'package:wifi_desk/features/streaming/presentation/widgets/side_controls_toolbar.dart';
import 'package:wifi_desk/features/streaming/presentation/widgets/stream_telemetry_header.dart';
import 'package:wifi_desk/features/streaming/presentation/widgets/video_display_viewport.dart';

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
    return Stack(
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
                    isZenMode: _isZenMode,
                    onToggleZenMode: () {
                      setState(() => _isZenMode = true);
                    },
                    onClose: () {
                      context.read<StreamingCubit>().stopSession();
                    },
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
                    onBack: () => context.read<StreamingCubit>().sendBack(),
                    onHome: () => context.read<StreamingCubit>().sendHome(),
                    onAppSwitch: () =>
                        context.read<StreamingCubit>().sendAppSwitch(),
                    onRotate: () =>
                        context.read<StreamingCubit>().rotateScreen(),
                    onToggleScreenOff: () =>
                        context.read<StreamingCubit>().toggleScreenOff(),
                  ),
                ),
              ],
            ),
          )
        else ...[
          // Zen Mode: Full-window display viewport
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FileDropTargetOverlay(
              deviceSerial: widget.device.serial,
              child: InputGestureViewportOverlay(
                deviceSerial: widget.device.serial,
                showShortcutBadge: false,
                child: VideoDisplayViewport(
                  session: widget.state.session,
                  rotationDegrees: widget.state.rotationDegrees,
                ),
              ),
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
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ScreenRecordingFeedbackBanner(),
              SizedBox(height: 8),
              ScreenshotFeedbackBanner(),
            ],
          ),
        ),
      ],
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
        double phoneDisplayW;
        double phoneDisplayH;
        if ((availableW / availableH) > phoneAspect) {
          phoneDisplayH = availableH;
          phoneDisplayW = phoneDisplayH * phoneAspect;
        } else {
          phoneDisplayW = availableW;
          phoneDisplayH = phoneDisplayW / phoneAspect;
        }

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

              // The Real-Time Phone Display Viewport
              SizedBox(
                width: phoneDisplayW,
                height: phoneDisplayH,
                child: FileDropTargetOverlay(
                  deviceSerial: widget.device.serial,
                  child: InputGestureViewportOverlay(
                    deviceSerial: widget.device.serial,
                    showShortcutBadge: false,
                    child: VideoDisplayViewport(
                      session: widget.state.session,
                      rotationDegrees: widget.state.rotationDegrees,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: gap),

              // Vertical Actions Sidebar placed on the right
              SideControlsToolbar(
                session: widget.state.session,
                deviceSerial: widget.device.serial,
                onSelectBitrate: (bitrate) =>
                    context.read<StreamingCubit>().updateBitrate(bitrate),
                onScreenshot: () => context
                    .read<ScreenshotCubit>()
                    .captureScreenshot(widget.device.serial),
                onTextInject: () =>
                    QuickTextInputDialog.show(context, widget.device.serial),
              ),
            ],
          ),
        );
      },
    );
  }
}
