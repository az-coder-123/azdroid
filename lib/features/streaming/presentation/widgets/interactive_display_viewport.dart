import 'package:desk_droid/features/control/presentation/widgets/input_gesture_viewport_overlay.dart';
import 'package:desk_droid/features/productivity/presentation/cubit/screenshot_cubit.dart';
import 'package:desk_droid/features/productivity/presentation/cubit/screenshot_state.dart';
import 'package:desk_droid/features/productivity/presentation/widgets/crop_selection_overlay.dart';
import 'package:desk_droid/features/productivity/presentation/widgets/recording_countdown_overlay.dart';
import 'package:desk_droid/features/streaming/domain/entities/stream_session_entity.dart';
import 'package:desk_droid/features/streaming/presentation/widgets/video_display_viewport.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Wraps the remote video display viewport with interactive surface overlays:
/// mouse/touch input injection, area crop marquee, and screen recording countdown overlay.
class InteractiveDisplayViewport extends StatelessWidget {
  const InteractiveDisplayViewport({
    super.key,
    required this.session,
    required this.deviceSerial,
    required this.rotationDegrees,
    this.showShortcutBadge = false,
  });

  final StreamSessionEntity session;
  final String deviceSerial;
  final int rotationDegrees;
  final bool showShortcutBadge;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScreenshotCubit, ScreenshotState>(
      builder: (context, screenshotState) {
        final isSelectingCropArea =
            screenshotState is ScreenshotSelectingArea &&
            screenshotState.deviceSerial == deviceSerial;

        return Stack(
          fit: StackFit.expand,
          children: [
            InputGestureViewportOverlay(
              deviceSerial: deviceSerial,
              showShortcutBadge: showShortcutBadge,
              child: VideoDisplayViewport(
                session: session,
                rotationDegrees: rotationDegrees,
              ),
            ),
            if (isSelectingCropArea)
              CropSelectionOverlay(deviceSerial: deviceSerial),
            RecordingCountdownOverlay(deviceSerial: deviceSerial),
          ],
        );
      },
    );
  }
}
