import 'package:flutter/material.dart';
import 'package:wifi_desk/features/productivity/presentation/widgets/clipboard_feedback_banner.dart';
import 'package:wifi_desk/features/productivity/presentation/widgets/screen_recording_feedback_banner.dart';
import 'package:wifi_desk/features/productivity/presentation/widgets/screenshot_feedback_banner.dart';

/// Floating stack of productivity feedback toasts (Clipboard, Recording, Screenshots).
class MirroringFeedbackStack extends StatelessWidget {
  const MirroringFeedbackStack({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ClipboardFeedbackBanner(),
        ScreenRecordingFeedbackBanner(),
        SizedBox(height: 8),
        ScreenshotFeedbackBanner(),
      ],
    );
  }
}
