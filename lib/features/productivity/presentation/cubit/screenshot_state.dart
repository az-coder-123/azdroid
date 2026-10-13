import 'package:equatable/equatable.dart';
import 'package:wifi_desk/features/productivity/domain/entities/screenshot_entity.dart';

/// Base state for device screenshot capturing lifecycle.
sealed class ScreenshotState extends Equatable {
  const ScreenshotState();

  @override
  List<Object?> get props => [];
}

/// Initial resting state with no active capture operations.
final class ScreenshotInitial extends ScreenshotState {
  const ScreenshotInitial();
}

/// Active interactive state when user is selecting a sub-region on the phone screen.
final class ScreenshotSelectingArea extends ScreenshotState {
  const ScreenshotSelectingArea(this.deviceSerial);

  final String deviceSerial;

  @override
  List<Object?> get props => [deviceSerial];
}

/// Active state while screenshot frame is being streamed and written to disk.
final class ScreenshotCapturing extends ScreenshotState {
  const ScreenshotCapturing();
}

/// Success state containing the saved screenshot details and clipboard status.
final class ScreenshotSuccess extends ScreenshotState {
  const ScreenshotSuccess(this.screenshot);

  final ScreenshotEntity screenshot;

  @override
  List<Object?> get props => [screenshot];
}

/// Failure state containing error diagnosis.
final class ScreenshotFailure extends ScreenshotState {
  const ScreenshotFailure(this.errorMessage);

  final String errorMessage;

  String get message => errorMessage;

  @override
  List<Object?> get props => [errorMessage];
}
