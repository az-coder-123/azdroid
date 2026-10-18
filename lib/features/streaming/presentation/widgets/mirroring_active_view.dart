import 'package:desk_droid/core/models/device_entity.dart';
import 'package:desk_droid/core/platform/shortcuts/shortcut_scheme.dart';
import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/features/apk_installer/presentation/widgets/apk_installer_dialog.dart';
import 'package:desk_droid/features/control/domain/entities/input_event_entity.dart';
import 'package:desk_droid/features/control/presentation/bloc/control_bloc.dart';
import 'package:desk_droid/features/control/presentation/bloc/control_event.dart';
import 'package:desk_droid/features/control/presentation/widgets/quick_text_input_dialog.dart';
import 'package:desk_droid/features/intent_dispatcher/presentation/widgets/intent_dispatcher_dialog.dart';
import 'package:desk_droid/features/logging/presentation/widgets/device_log_dialog.dart';
import 'package:desk_droid/features/productivity/presentation/cubit/file_transfer_cubit.dart';
import 'package:desk_droid/features/productivity/presentation/cubit/screenshot_cubit.dart';
import 'package:desk_droid/features/productivity/presentation/widgets/device_file_manager_dialog.dart';
import 'package:desk_droid/features/productivity/presentation/widgets/file_drop_target_overlay.dart';
import 'package:desk_droid/features/productivity/presentation/widgets/transfer_status_banner.dart';
import 'package:desk_droid/features/showcase/presentation/widgets/feature_showcase_dialog.dart';
import 'package:desk_droid/features/streaming/presentation/cubit/streaming_cubit.dart';
import 'package:desk_droid/features/streaming/presentation/cubit/streaming_state.dart';
import 'package:desk_droid/features/streaming/presentation/widgets/interactive_display_viewport.dart';
import 'package:desk_droid/features/streaming/presentation/widgets/left_controls_toolbar.dart';
import 'package:desk_droid/features/streaming/presentation/widgets/mirroring_central_viewport.dart';
import 'package:desk_droid/features/streaming/presentation/widgets/mirroring_feedback_stack.dart';
import 'package:desk_droid/features/streaming/presentation/widgets/side_controls_toolbar.dart';
import 'package:desk_droid/features/streaming/presentation/widgets/stream_reconfiguring_badge.dart';
import 'package:desk_droid/features/streaming/presentation/widgets/stream_telemetry_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Active mirroring viewport layout with top telemetry, centered phone display,
/// right-side tools dock, bottom navigation toolbar, and overlay feedback cards.
class MirroringActiveView extends StatefulWidget {
  const MirroringActiveView({
    super.key,
    required this.device,
    required this.state,
    this.deviceStatusBanner,
  });

  final DeviceEntity device;
  final StreamingActive state;

  /// Status badge from another feature, shown at the top center without
  /// taking input (see MirroringPage).
  final Widget? deviceStatusBanner;

  /// Distance of [deviceStatusBanner] from the top: below the telemetry
  /// header, or near the edge in Zen mode.
  static const double statusBannerTop = 64;
  static const double statusBannerTopZen = 16;

  @override
  State<MirroringActiveView> createState() => _MirroringActiveViewState();
}

class _MirroringActiveViewState extends State<MirroringActiveView> {
  bool _isZenMode = false;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<StreamingCubit>();
    final keys = context.shortcuts;
    return CallbackShortcuts(
      bindings: {
        keys.activator(LogicalKeyboardKey.keyO): cubit.toggleScreenOff,
        keys.activator(LogicalKeyboardKey.keyR): cubit.rotateScreen,
        keys.activator(LogicalKeyboardKey.keyP): () =>
            _navigate(context, NavigationAction.power),
      },
      child: _buildLayout(context),
    );
  }

  Widget _buildLayout(BuildContext context) {
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
                      onClose: context.read<StreamingCubit>().stopSession,
                    ),
                  ),

                  // Dedicated Central Display Viewport with Dual Side Controls Toolbars
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 12.0),
                      child: _buildCentralViewport(context),
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

          if (widget.deviceStatusBanner case final banner?)
            Positioned(
              top: _isZenMode
                  ? MirroringActiveView.statusBannerTopZen
                  : MirroringActiveView.statusBannerTop,
              left: 0,
              right: 0,
              child: IgnorePointer(child: Center(child: banner)),
            ),

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

          // Pipeline restart feedback (bitrate or stay-awake change)
          if (widget.state.pendingChange case final change?)
            Positioned.fill(
              child: IgnorePointer(
                child: Center(child: StreamReconfiguringBadge(change: change)),
              ),
            ),
        ],
      ),
    );
  }

  void _navigate(BuildContext context, NavigationAction action) {
    context.read<ControlBloc>().add(
      ControlNavigationActionDispatched(
        deviceSerial: widget.device.serial,
        action: action,
      ),
    );
  }

  Widget _buildCentralViewport(BuildContext context) {
    // Stream aspect ratio accounting for the active rotation.
    final isRotated = (widget.state.rotationDegrees ~/ 90) % 2 != 0;
    final session = widget.state.session;
    final width = (isRotated ? session.height : session.width).toDouble();
    final height = (isRotated ? session.width : session.height).toDouble();
    return MirroringCentralViewport(
      aspectRatio: width / height,
      display: InteractiveDisplayViewport(
        session: session,
        deviceSerial: widget.device.serial,
        rotationDegrees: widget.state.rotationDegrees,
      ),
      leftToolbar: _buildLeftControls(context),
      sideToolbar: _buildSideControls(context),
    );
  }

  Widget _buildLeftControls(BuildContext context) {
    return LeftControlsToolbar(
      session: widget.state.session,
      onBack: () => _navigate(context, NavigationAction.back),
      onHome: () => _navigate(context, NavigationAction.home),
      onAppSwitch: () => _navigate(context, NavigationAction.appSwitch),
      onPower: () => _navigate(context, NavigationAction.power),
      onRotate: context.read<StreamingCubit>().rotateScreen,
      onToggleStayAwake: widget.state.isReconfiguring
          ? null
          : context.read<StreamingCubit>().toggleStayAwake,
      onToggleScreenOff: context.read<StreamingCubit>().toggleScreenOff,
      onToggleZenMode: () => setState(() => _isZenMode = true),
      onOpenShowcase: () => FeatureShowcaseDialog.show(context),
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
