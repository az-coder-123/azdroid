import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wifi_desk/core/services/app_logger.dart';
import 'package:wifi_desk/features/productivity/domain/repositories/screenshot_repository.dart';
import 'package:wifi_desk/features/productivity/presentation/cubit/screenshot_state.dart';

/// Cubit managing screenshot capture operations and feedback states.
class ScreenshotCubit extends Cubit<ScreenshotState> {
  ScreenshotCubit({required this.repository})
    : super(const ScreenshotInitial());

  final ScreenshotRepository repository;

  /// Captures a screenshot from the remote Android device.
  Future<void> captureScreenshot(
    String deviceSerial, {
    String? customSaveDirectory,
  }) async {
    if (state is ScreenshotCapturing) return;

    emit(const ScreenshotCapturing());

    try {
      final screenshot = await repository.captureScreenshot(
        deviceSerial: deviceSerial,
        customSaveDirectory: customSaveDirectory,
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
