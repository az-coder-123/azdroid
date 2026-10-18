import 'dart:io';

import 'package:desk_droid/core/constants/scrcpy_server_constants.dart';

/// The two device settings scrcpy changes for "stay awake".
typedef AwakeSettings = ({String stayOn, String screenOffTimeout});

/// Checks that the server changes the stay-awake settings while it runs and
/// that its restore process (`cleanup=true`) puts the originals back.
class StayAwakeProbe {
  StayAwakeProbe({required this.adb, required this.serial});

  final String adb;
  final String serial;

  /// All plug types (AC | USB | wireless), as scrcpy sets it.
  static const String _stayOnAllPlugs = '7';
  static const Duration _restoreLimit = Duration(seconds: 5);
  static const Duration _pollInterval = Duration(milliseconds: 250);

  late final AwakeSettings original;
  AwakeSettings? during;
  AwakeSettings? after;

  /// Call before the server starts.
  Future<void> recordOriginal() async => original = await read();

  /// Call while the server runs.
  Future<void> recordDuring() async => during = await read();

  /// Call after the server was stopped; polls until restored or the limit.
  Future<void> recordAfter() async {
    final stopwatch = Stopwatch()..start();
    var current = await read();
    while (current != original && stopwatch.elapsed < _restoreLimit) {
      await Future<void>.delayed(_pollInterval);
      current = await read();
    }
    after = current;
  }

  bool get changedWhileRunning =>
      during ==
      (
        stayOn: _stayOnAllPlugs,
        screenOffTimeout:
            '${ScrcpyServerConstants.stayAwakeScreenOffTimeoutMs}',
      );

  bool get restoredAfterStop => after == original;

  bool get isOk => changedWhileRunning && restoredAfterStop;

  String describe() =>
      'stay awake: original=$original, during=$during, after=$after '
      '(changed=$changedWhileRunning, restored=$restoredAfterStop)';

  Future<AwakeSettings> read() async {
    final r = await Process.run(adb, [
      '-s',
      serial,
      'shell',
      'settings get global stay_on_while_plugged_in; '
          'settings get system screen_off_timeout',
    ]);
    final lines = '${r.stdout}'.trim().split('\n').map((l) => l.trim());
    return (stayOn: lines.first, screenOffTimeout: lines.last);
  }
}
