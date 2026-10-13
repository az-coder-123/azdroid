import 'package:wifi_desk/features/productivity/domain/entities/screenshot_entity.dart';

/// Contract for capturing and persisting remote device screenshots.
abstract class ScreenshotRepository {
  /// Captures a lossless full-resolution PNG screenshot of the active device display.
  Future<ScreenshotEntity?> captureScreenshot({
    required String deviceSerial,
    String? customSaveDirectory,
  });
}
