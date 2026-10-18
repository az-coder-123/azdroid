/// The app in the foreground, and the system window in front of it, if any.
typedef McpForegroundApp = ({
  String package,
  String activity,
  String? overlayWindow,
});

/// Finds the foreground app in `dumpsys window` (and, as a fallback,
/// `dumpsys activity activities`) output.
///
/// The focused window is not always an app: on the lock screen or with the
/// notification shade open it is `StatusBar` or `NotificationShade`. The app
/// underneath is then read from `mFocusedApp`, which Android 10 wraps as
/// `AppWindowToken{… ActivityRecord{…}}` and Android 11+ prints as
/// `ActivityRecord{…}`. Pure Dart (no Flutter).
class McpForegroundAppParser {
  const McpForegroundAppParser._();

  /// `mCurrentFocus=Window{d3073c1 u0 NotificationShade}`: the window title.
  static final RegExp _focus = RegExp(
    r'mCurrentFocus=Window\{\S+ u\d+ ([^}\s]+)\}',
  );

  /// `ActivityRecord{1b46f00 u0 com.miui.home/.launcher.Launcher t3}`.
  static const String _record = r'ActivityRecord\{\S+ u\d+ ([\w.]+)/([\w.$]+)';
  static final RegExp _focusedApp = RegExp('mFocusedApp=.*?$_record');
  static final RegExp _resumed = RegExp(
    '(?:mResumedActivity|topResumedActivity|ResumedActivity)[:=]\\s*$_record',
  );

  static McpForegroundApp? parse({
    required String windowDump,
    String activityDump = '',
  }) {
    final focus = _focus.firstMatch(windowDump)?.group(1);
    if (focus != null && focus.contains('/')) {
      final [package, activity, ...] = focus.split('/');
      return _app(package, activity, null);
    }
    final record =
        _focusedApp.firstMatch(windowDump) ?? _resumed.firstMatch(activityDump);
    if (record == null) return null;
    return _app(record.group(1)!, record.group(2)!, focus);
  }

  /// Expands a short activity name (`.launcher.Launcher`) to its full class.
  static McpForegroundApp _app(
    String package,
    String activity,
    String? overlay,
  ) => (
    package: package,
    activity: activity.startsWith('.') ? '$package$activity' : activity,
    overlayWindow: overlay,
  );
}
