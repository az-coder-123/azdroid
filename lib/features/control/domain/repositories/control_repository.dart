import 'package:desk_droid/features/control/domain/entities/input_event_entity.dart';
import 'package:desk_droid/features/control/domain/entities/touch_stream.dart';

/// Abstract contract governing remote mouse, touch, gesture, and keyboard input injection.
abstract class ControlRepository {
  /// Injects a touch tap at the specified normalized coordinates (0.0 to 1.0).
  Future<bool> sendTap(
    String deviceSerial, {
    required double normalizedX,
    required double normalizedY,
    int? displayWidth,
    int? displayHeight,
  });

  /// Injects a swipe gesture from start coordinates to end coordinates.
  Future<bool> sendSwipe(
    String deviceSerial, {
    required double startX,
    required double startY,
    required double endX,
    required double endY,
    int? durationMs,
    int? displayWidth,
    int? displayHeight,
  });

  /// Translates mouse wheel or trackpad scroll delta into an on-screen swipe gesture.
  Future<bool> sendScroll(
    String deviceSerial, {
    required double normalizedX,
    required double normalizedY,
    required double deltaX,
    required double deltaY,
    int? displayWidth,
    int? displayHeight,
  });

  /// Injects an Android physical or logical key event by keycode.
  Future<bool> sendKeyEvent(String deviceSerial, int keyCode);

  /// Injects raw text or international Unicode characters into the focused Android input field.
  Future<bool> sendText(String deviceSerial, String text);

  /// Streams live fingers at normalized positions (one finger for drags,
  /// two for pinch and rotate). Call `start`, any number of `move`, then
  /// `end`; [points] may be empty for `end` (lift where the fingers are).
  Future<bool> sendTouchStream(
    String deviceSerial,
    TouchStreamPhase phase,
    List<NormalizedPoint> points,
  );

  /// Triggers standard Android navigation shortcuts (Back, Home, AppSwitch, etc.).
  Future<bool> sendNavigationAction(
    String deviceSerial,
    NavigationAction action,
  );
}
