import 'dart:io';

import 'package:desk_droid/features/control/data/scrcpy/scrcpy_control_message.dart';

/// Opens the scrcpy control socket and checks, on a real device, that the
/// app's own [ScrcpyControlMessage] bytes are understood by the server.
class ControlProbe {
  ControlProbe({required this.port, required this.adb, required this.serial});

  final int port;
  final String adb;
  final String serial;
  Socket? _socket;

  static const Duration _settle = Duration(milliseconds: 1200);
  static const Duration _pollInterval = Duration(milliseconds: 250);

  // Android KeyEvent codes (AndroidKeyCodes pulls in Flutter, so not usable
  // from a plain Dart tool).
  static const int _keycodeHome = 3;
  static const int _keycodeBack = 4;

  Future<void> connect() async {
    _socket = await Socket.connect(InternetAddress.loopbackIPv4, port)
      ..setOption(SocketOption.tcpNoDelay, true)
      ..listen((_) {});
  }

  Future<void> close() async => _socket?.destroy();

  /// HOME and BACK through the control socket, checked with dumpsys.
  ///
  /// Waits for conditions (bounded) instead of fixed delays, because slow
  /// devices and emulators take seconds to launch or close an activity.
  Future<List<String>> checkKeys() async {
    final results = <String>[];
    await _key(_keycodeHome);
    final afterHome = await _waitForResumed((a) => a.contains('launcher'));
    results.add('HOME -> resumed: $afterHome');

    await _shell(['am', 'start', '-a', 'android.settings.SETTINGS']);
    final settings = await _waitForResumed((a) => a.contains('settings'));
    await _key(_keycodeBack);
    final afterBack = await _waitForResumed((a) => !a.contains('settings'));
    final closed =
        settings.contains('settings') && !afterBack.contains('settings');
    results.add('BACK closed Settings: $closed ($settings -> $afterBack)');
    return results;
  }

  /// Polls the resumed activity until [done] holds or [_settle] x 5 passes.
  Future<String> _waitForResumed(bool Function(String activity) done) async {
    final stopwatch = Stopwatch()..start();
    var activity = await _resumedActivity();
    while (!done(activity) && stopwatch.elapsed < _settle * 5) {
      await Future<void>.delayed(_pollInterval);
      activity = await _resumedActivity();
    }
    return activity;
  }

  /// Sends a tap with the correct frame size and one with a wrong size. With
  /// `log_level=verbose`, the server logs "Ignore positional event" only for
  /// the wrong one.
  void sendTapPair({required int width, required int height}) {
    for (final (w, h) in [(width, height), (width + 8, height)]) {
      for (final action in [
        ScrcpyControlMessage.actionDown,
        ScrcpyControlMessage.actionUp,
      ]) {
        _socket!.add(
          ScrcpyControlMessage.touch(
            action: action,
            x: width ~/ 2,
            y: height - 4,
            screenWidth: w,
            screenHeight: h,
            pressure: action == ScrcpyControlMessage.actionUp ? 0 : 1,
          ),
        );
      }
    }
  }

  Future<void> _key(int keyCode) async {
    for (final action in [
      ScrcpyControlMessage.actionDown,
      ScrcpyControlMessage.actionUp,
    ]) {
      _socket!.add(
        ScrcpyControlMessage.keycode(action: action, keyCode: keyCode),
      );
    }
    await _socket!.flush();
  }

  Future<String> _resumedActivity() async {
    final out = await _shell(['dumpsys', 'activity', 'activities']);
    final line = out
        .split('\n')
        .firstWhere(
          // "mResumedActivity"/"topResumedActivity" on newer Android,
          // "ResumedActivity:" on Android 10 (MIUI).
          (l) => l.contains('ResumedActivity'),
          orElse: () => 'unknown',
        );
    return line.trim().toLowerCase();
  }

  Future<String> _shell(List<String> args) async {
    final r = await Process.run(adb, ['-s', serial, 'shell', ...args]);
    return '${r.stdout}';
  }
}

/// Whether the device display is on, from `dumpsys power`.
Future<bool> isScreenOn(String adb, String serial) async {
  final r = await Process.run(adb, ['-s', serial, 'shell', 'dumpsys', 'power']);
  return '${r.stdout}'.contains('mWakefulness=Awake');
}

/// Whether the lock screen is showing (HOME/BACK do nothing there).
Future<bool> isKeyguardShowing(String adb, String serial) async {
  final r = await Process.run(adb, [
    '-s',
    serial,
    'shell',
    'dumpsys',
    'window',
  ]);
  final out = '${r.stdout}';
  return out.contains('isStatusBarKeyguard=true') ||
      out.contains('mDreamingLockscreen=true') ||
      out.contains('mShowingLockscreen=true');
}
