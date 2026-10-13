import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wifi_desk/core/services/app_logger.dart';
import 'package:wifi_desk/features/productivity/domain/entities/screenshot_destination.dart';
import 'package:wifi_desk/features/productivity/domain/repositories/screenshot_repository.dart';
import 'package:wifi_desk/features/productivity/presentation/cubit/screenshot_state.dart';

/// Cubit managing screenshot capture operations and feedback states.
class ScreenshotCubit extends Cubit<ScreenshotState> {
  ScreenshotCubit({required this.repository})
    : super(const ScreenshotInitial());

  final ScreenshotRepository repository;

  /// Enters interactive area selection mode for the phone screen.
  void startAreaSelection(String deviceSerial) {
    emit(ScreenshotSelectingArea(deviceSerial));
  }

  /// Cancels area selection mode without capturing.
  void cancelAreaSelection() {
    if (state is ScreenshotSelectingArea) {
      emit(const ScreenshotInitial());
    }
  }

  /// Captures a screenshot from the remote Android device.
  /// If [cropRectNormalized] is provided, crops the screenshot to that region.
  /// [destination] controls whether to save to disk, clipboard, or both.
  Future<void> captureScreenshot(
    String deviceSerial, {
    String? customSaveDirectory,
    Rect? cropRectNormalized,
    ScreenshotDestination destination = ScreenshotDestination.both,
  }) async {
    if (state is ScreenshotCapturing) return;

    emit(const ScreenshotCapturing());

    try {
      final screenshot = await repository.captureScreenshot(
        deviceSerial: deviceSerial,
        customSaveDirectory: customSaveDirectory,
        cropRectNormalized: cropRectNormalized,
        destination: destination,
      );

      if (screenshot != null) {
        emit(ScreenshotSuccess(screenshot));
      } else {
        emit(const ScreenshotFailure('No screenshot data received'));
      }
    } catch (e, stack) {
      AppLogger.warning(
        'Screenshot failed for $deviceSerial',
        error: e,
        stackTrace: stack,
      );
      emit(ScreenshotFailure(e.toString()));
    }
  }

  /// Resets state back to [ScreenshotInitial].
  void reset() {
    emit(const ScreenshotInitial());
  }
}
