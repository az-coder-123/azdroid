import 'package:desk_droid/core/constants/android_key_codes.dart';
import 'package:desk_droid/core/constants/control_constants.dart';
import 'package:desk_droid/features/control/data/datasources/control_datasource.dart';
import 'package:desk_droid/features/control/domain/entities/frame_size.dart';
import 'package:desk_droid/features/control/domain/entities/input_event_entity.dart';
import 'package:desk_droid/features/control/domain/repositories/control_repository.dart';
import 'package:desk_droid/features/control/domain/repositories/video_frame_size_source.dart';

/// Concrete implementation of [ControlRepository] translating normalized coordinates and events to native device actions.
///
/// Normalized positions are mapped onto the real video frame size from
/// [VideoFrameSizeSource] (the device screen in its current orientation).
/// Explicit `displayWidth`/`displayHeight` arguments take precedence; the
/// [ControlConstants] defaults apply only when no video is decoded yet.
class ControlRepositoryImpl implements ControlRepository {
  ControlRepositoryImpl({ControlDatasource? datasource, this._frameSizeSource})
    : _datasource = datasource ?? ControlDatasourceImpl();

  final ControlDatasource _datasource;
  final VideoFrameSizeSource? _frameSizeSource;

  /// Frame used for mapping: explicit size, else the live video size.
  Future<FrameSize?> _frameFor(int? width, int? height) async {
    if (width != null && height != null) return FrameSize(width, height);
    return _frameSizeSource?.current();
  }

  @override
  Future<bool> sendTap(
    String deviceSerial, {
    required double normalizedX,
    required double normalizedY,
    int? displayWidth,
    int? displayHeight,
  }) async {
    final frame = await _frameFor(displayWidth, displayHeight);
    final width = frame?.width ?? ControlConstants.defaultDisplayWidth;
    final height = frame?.height ?? ControlConstants.defaultDisplayHeight;

    final targetX = (normalizedX * width).round().clamp(0, width);
    final targetY = (normalizedY * height).round().clamp(0, height);

    return _datasource.injectTap(deviceSerial, targetX, targetY, frame: frame);
  }

  @override
  Future<bool> sendSwipe(
    String deviceSerial, {
    required double startX,
    required double startY,
    required double endX,
    required double endY,
    int? durationMs,
    int? displayWidth,
    int? displayHeight,
  }) async {
    final frame = await _frameFor(displayWidth, displayHeight);
    final width = frame?.width ?? ControlConstants.defaultDisplayWidth;
    final height = frame?.height ?? ControlConstants.defaultDisplayHeight;
    final duration = durationMs ?? ControlConstants.defaultSwipeDurationMs;

    final x1 = (startX * width).round().clamp(0, width);
    final y1 = (startY * height).round().clamp(0, height);
    final x2 = (endX * width).round().clamp(0, width);
    final y2 = (endY * height).round().clamp(0, height);

    return _datasource.injectSwipe(
      deviceSerial,
      x1,
      y1,
      x2,
      y2,
      duration,
      frame: frame,
    );
  }

  @override
  Future<bool> sendScroll(
    String deviceSerial, {
    required double normalizedX,
    required double normalizedY,
    required double deltaX,
    required double deltaY,
    int? displayWidth,
    int? displayHeight,
  }) async {
    final frame = await _frameFor(displayWidth, displayHeight);
    final width = frame?.width ?? ControlConstants.defaultDisplayWidth;
    final height = frame?.height ?? ControlConstants.defaultDisplayHeight;

    final startPixelX = (normalizedX * width).round().clamp(0, width);
    final startPixelY = (normalizedY * height).round().clamp(0, height);

    // Negative deltaY on trackpad (scrolling down to view content below) translates to an upward swipe on touchscreen
    final travelX = (deltaX * ControlConstants.scrollFactor).round();
    final travelY = (-deltaY * ControlConstants.scrollFactor).round();

    final endPixelX = (startPixelX + travelX).clamp(0, width);
    final endPixelY = (startPixelY + travelY).clamp(0, height);

    return _datasource.injectSwipe(
      deviceSerial,
      startPixelX,
      startPixelY,
      endPixelX,
      endPixelY,
      ControlConstants.defaultSwipeDurationMs,
      frame: frame,
    );
  }

  @override
  Future<bool> sendKeyEvent(String deviceSerial, int keyCode) {
    return _datasource.injectKeyevent(deviceSerial, keyCode);
  }

  @override
  Future<bool> sendText(String deviceSerial, String text) {
    return _datasource.injectText(deviceSerial, text);
  }

  @override
  Future<bool> sendNavigationAction(
    String deviceSerial,
    NavigationAction action,
  ) {
    final keyCode = switch (action) {
      NavigationAction.back => AndroidKeyCodes.keycodeBack,
      NavigationAction.home => AndroidKeyCodes.keycodeHome,
      NavigationAction.appSwitch => AndroidKeyCodes.keycodeAppSwitch,
      NavigationAction.volumeUp => AndroidKeyCodes.keycodeVolumeUp,
      NavigationAction.volumeDown => AndroidKeyCodes.keycodeVolumeDown,
      NavigationAction.power => AndroidKeyCodes.keycodePower,
    };

    return _datasource.injectKeyevent(deviceSerial, keyCode);
  }
}
