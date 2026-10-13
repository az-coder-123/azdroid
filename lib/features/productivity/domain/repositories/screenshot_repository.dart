import 'dart:ui';

import 'package:wifi_desk/features/productivity/domain/entities/screenshot_destination.dart';
import 'package:wifi_desk/features/productivity/domain/entities/screenshot_entity.dart';

/// Contract for capturing display screenshot artifacts.
abstract class ScreenshotRepository {
  /// Captures a display frame from the Android device.
  /// If [cropRectNormalized] is supplied, crops the image to the specified sub-region.
  /// [destination] specifies whether to persist to disk, copy to clipboard, or both.
  Future<ScreenshotEntity?> captureScreenshot({
    required String deviceSerial,
    String? customSaveDirectory,
    Rect? cropRectNormalized,
    ScreenshotDestination destination = ScreenshotDestination.both,
  });
}
