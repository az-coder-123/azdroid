import 'package:desk_droid/features/mcp/domain/services/mcp_foreground_app_parser.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fixtures are real `dumpsys` lines from the test devices (2026-10-18).
void main() {
  test('an app window in focus is the foreground app', () {
    final app = McpForegroundAppParser.parse(
      windowDump:
          '  mCurrentFocus=Window{4a1b2c3 u0 com.android.settings/com.android.settings.SubSettings}\n'
          '  mFocusedApp=ActivityRecord{9f u0 com.android.settings/.SubSettings t12}',
    );
    expect(app, (
      package: 'com.android.settings',
      activity: 'com.android.settings.SubSettings',
      overlayWindow: null,
    ));
  });

  test('Android 10 lock screen: app read from the AppWindowToken wrapper', () {
    // Redmi 9 (MIUI, Android 10), locked: this used to fail (BL-09).
    final app = McpForegroundAppParser.parse(
      windowDump:
          '  mCurrentFocus=Window{999448a u0 StatusBar}\n'
          '  mFocusedApp=AppWindowToken{fa39d7e token=Token{da57339 '
          'ActivityRecord{1b46f00 u0 com.miui.home/.launcher.Launcher t3}}}',
    );
    expect(app, (
      package: 'com.miui.home',
      activity: 'com.miui.home.launcher.Launcher',
      overlayWindow: 'StatusBar',
    ));
  });

  test('Android 13 notification shade: app read from ActivityRecord', () {
    final app = McpForegroundAppParser.parse(
      windowDump:
          '  mCurrentFocus=Window{d3073c1 u0 NotificationShade}\n'
          '  mFocusedApp=ActivityRecord{d357582 u0 com.motorola.launcher3/'
          'com.android.launcher3.CustomizationPanelLauncher} t6}',
    );
    expect(app?.package, 'com.motorola.launcher3');
    expect(app?.overlayWindow, 'NotificationShade');
  });

  test('falls back to the resumed activity, then gives up', () {
    final resumed = McpForegroundAppParser.parse(
      windowDump: '  mCurrentFocus=null',
      activityDump: '  ResumedActivity: ActivityRecord{1b46f00 u0 com.miui.home/.launcher.Launcher t3}',
    );
    expect(resumed?.activity, 'com.miui.home.launcher.Launcher');
    expect(resumed?.overlayWindow, isNull);
    expect(McpForegroundAppParser.parse(windowDump: ''), isNull);
  });
}
