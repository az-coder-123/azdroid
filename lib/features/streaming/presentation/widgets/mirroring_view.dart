import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wifi_desk/core/di/injection.dart';
import 'package:wifi_desk/core/theme/app_colors.dart';
import 'package:wifi_desk/core/theme/app_typography.dart';
import 'package:wifi_desk/features/control/presentation/widgets/input_gesture_viewport_overlay.dart';
import 'package:wifi_desk/features/control/presentation/widgets/quick_text_input_dialog.dart';
import 'package:wifi_desk/features/discovery/domain/entities/device_entity.dart';
import 'package:wifi_desk/features/menubar/presentation/cubit/menu_bar_cubit.dart';
import 'package:wifi_desk/features/productivity/presentation/widgets/file_drop_target_overlay.dart';
import 'package:wifi_desk/features/productivity/presentation/widgets/transfer_status_banner.dart';
import 'package:wifi_desk/features/streaming/presentation/cubit/streaming_cubit.dart';
import 'package:wifi_desk/features/streaming/presentation/cubit/streaming_state.dart';
import 'package:wifi_desk/features/streaming/presentation/widgets/floating_controls_toolbar.dart';
import 'package:wifi_desk/features/streaming/presentation/widgets/stream_telemetry_header.dart';
import 'package:wifi_desk/features/streaming/presentation/widgets/video_display_viewport.dart';

/// Interactive mirroring view with non-overlapping controls and Zen mode support.
class MirroringView extends StatefulWidget {
  const MirroringView({super.key, required this.device});

  final DeviceEntity device;

  @override
  State<MirroringView> createState() => _MirroringViewState();
}

class _MirroringViewState extends State<MirroringView> {
  bool _isZenMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocConsumer<StreamingCubit, StreamingState>(
        listener: (context, state) {
          if (state is StreamingActive) {
            sl<MenuBarCubit>().updateActiveSession(
              deviceName: state.session.deviceName,
              latencyMs: state.session.latencyMs,
              fps: state.session.fps,
            );
          } else if (state is StreamingInitial) {
            sl<MenuBarCubit>().clearActiveSession();
            Navigator.of(context).maybePop();
          }
        },
        builder: (context, state) {
          if (state is StreamingStarting) {
            return _buildStartingView();
          }

          if (state is StreamingError) {
            return _buildErrorView(context, state.message);
          }

          if (state is StreamingActive) {
            return _buildActiveView(context, state);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildStartingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.accent),
          const SizedBox(height: 20),
          Text(
            'Starting Display Stream on ${widget.device.name}...',
            style: AppTypography.title,
          ),
          const SizedBox(height: 8),
          const Text(
            'Initializing hardware video decoder & tunneling sockets...',
            style: AppTypography.subtitle,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.statusError,
              size: 54,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTypography.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Back to Devices'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () => context.read<StreamingCubit>().startSession(
                    widget.device,
                  ),
                  child: const Text('Retry Connection'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveView(BuildContext context, StreamingActive state) {
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
                    session: state.session,
                    isZenMode: _isZenMode,
                    onToggleZenMode: () {
                      setState(() => _isZenMode = true);
                    },
                    onClose: () {
                      context.read<StreamingCubit>().stopSession();
                    },
                  ),
                ),

                // Dedicated Unobstructed Central Display Viewport
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 4.0,
                    ),
                    child: FileDropTargetOverlay(
                      deviceSerial: widget.device.serial,
                      child: InputGestureViewportOverlay(
                        deviceSerial: widget.device.serial,
                        showShortcutBadge: false,
                        child: VideoDisplayViewport(
                          session: state.session,
                          rotationDegrees: state.rotationDegrees,
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom Non-overlapping Controls Toolbar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: FloatingControlsToolbar(
                    session: state.session,
                    deviceSerial: widget.device.serial,
                    onBack: () => context.read<StreamingCubit>().sendBack(),
                    onHome: () => context.read<StreamingCubit>().sendHome(),
                    onAppSwitch: () =>
                        context.read<StreamingCubit>().sendAppSwitch(),
                    onRotate: () =>
                        context.read<StreamingCubit>().rotateScreen(),
                    onToggleScreenOff: () =>
                        context.read<StreamingCubit>().toggleScreenOff(),
                    onSelectBitrate: (bitrate) =>
                        context.read<StreamingCubit>().updateBitrate(bitrate),
                    onTextInject: () => QuickTextInputDialog.show(
                      context,
                      widget.device.serial,
                    ),
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
                  session: state.session,
                  rotationDegrees: state.rotationDegrees,
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
      ],
    );
  }
}
