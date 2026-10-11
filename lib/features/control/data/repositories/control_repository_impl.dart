import 'package:wifi_desk/core/constants/android_key_codes.dart';
import 'package:wifi_desk/core/constants/control_constants.dart';
import 'package:wifi_desk/features/control/data/datasources/control_datasource.dart';
import 'package:wifi_desk/features/control/domain/entities/input_event_entity.dart';
import 'package:wifi_desk/features/control/domain/repositories/control_repository.dart';

/// Concrete implementation of [ControlRepository] translating normalized coordinates and events to native device actions.
class ControlRepositoryImpl implements ControlRepository {
  ControlRepositoryImpl({ControlDatasource? datasource})
    : _datasource = datasource ?? ControlDatasourceImpl();

  final ControlDatasource _datasource;

  @override
  Future<bool> sendTap(
    String deviceSerial, {
    required double normalizedX,
    required double normalizedY,
    int? displayWidth,
    int? displayHeight,
  }) async {
    final width = displayWidth ?? ControlConstants.defaultDisplayWidth;
    final height = displayHeight ?? ControlConstants.defaultDisplayHeight;

    final targetX = (normalizedX * width).round().clamp(0, width);
    final targetY = (normalizedY * height).round().clamp(0, height);

    return _datasource.injectTap(deviceSerial, targetX, targetY);
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
    final width = displayWidth ?? ControlConstants.defaultDisplayWidth;
    final height = displayHeight ?? ControlConstants.defaultDisplayHeight;
    final duration = durationMs ?? ControlConstants.defaultSwipeDurationMs;

    final x1 = (startX * width).round().clamp(0, width);
    final y1 = (startY * height).round().clamp(0, height);
    final x2 = (endX * width).round().clamp(0, width);
    final y2 = (endY * height).round().clamp(0, height);

    return _datasource.injectSwipe(deviceSerial, x1, y1, x2, y2, duration);
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
    final width = displayWidth ?? ControlConstants.defaultDisplayWidth;
    final height = displayHeight ?? ControlConstants.defaultDisplayHeight;

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
