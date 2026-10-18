import 'dart:io';

/// The two device settings older DeskDroid builds changed for "stay awake".
typedef AwakeSettings = ({String stayOn, String screenOffTimeout});

/// Checks scrcpy's `keep_active` option: while the server runs, it reports
/// user activity every few seconds (so the screen does not time out), and it
/// leaves the device's sleep settings untouched before, during and after.
class KeepActiveProbe {
  KeepActiveProbe({required this.adb, required this.serial});

  final String adb;
  final String serial;

  /// The server reports activity every 4 s (`Controller.KEEP_ACTIVE_INTERVAL_MS`).
  static const Duration _activityLimit = Duration(seconds: 6);
  static const Duration _pollInterval = Duration(milliseconds: 250);
  static final RegExp _activityTime = RegExp(r'mLastUserActivityTime=(\d+)');

  late final AwakeSettings original;
  AwakeSettings? during;
  AwakeSettings? after;
  bool activityRefreshed = false;

  /// Call before the server starts.
  Future<void> recordOriginal() async => original = await readSettings();

  /// Call while the server runs and nothing else touches the device: waits
  /// for the server to report user activity on its own.
  Future<void> recordDuring() async {
    during = await readSettings();
    final start = await _lastActivity();
    final stopwatch = Stopwatch()..start();
    while (stopwatch.elapsed < _activityLimit) {
      await Future<void>.delayed(_pollInterval);
      final now = await _lastActivity();
      if (start != null && now != null && now > start) {
        activityRefreshed = true;
        return;
      }
    }
  }

  /// Call after the server was stopped.
  Future<void> recordAfter() async => after = await readSettings();

  bool get settingsUntouched => during == original && after == original;

  bool get isOk => activityRefreshed && settingsUntouched;

  String describe() =>
      'keep active: activity refreshed=$activityRefreshed, '
      'settings untouched=$settingsUntouched '
      '(original=$original, during=$during, after=$after)';

  Future<AwakeSettings> readSettings() async {
    final lines = (await _shell(
      'settings get global stay_on_while_plugged_in; '
      'settings get system screen_off_timeout',
    )).trim().split('\n').map((l) => l.trim());
    return (stayOn: lines.first, screenOffTimeout: lines.last);
  }

  Future<int?> _lastActivity() async {
    final match = _activityTime.firstMatch(await _shell('dumpsys power'));
    return match == null ? null : int.parse(match.group(1)!);
  }

  Future<String> _shell(String command) async =>
      '${(await Process.run(adb, ['-s', serial, 'shell', command])).stdout}';
}
