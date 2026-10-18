// Verifies the bundled scrcpy-server against a real device or emulator, with
// the exact arguments DeskDroid uses (ScrcpyServerCommand). Run it after every
// scrcpy upgrade, on an old and on the newest Android version:
//
//   dart run tool/verify_scrcpy_server.dart --serial=<adb serial> [--adb=<path>]
//
// It is isolated from a running DeskDroid (own scid, local port, and remote
// jar path) and cleans up after itself. See docs/scrcpy-upgrade-assessment.md.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:desk_droid/core/constants/scrcpy_server_constants.dart';
import 'package:desk_droid/features/streaming/data/services/scrcpy_server_command.dart';
import 'package:desk_droid/features/streaming/data/services/scrcpy_server_output.dart';

import 'scrcpy_verify/control_probe.dart';
import 'scrcpy_verify/stay_awake_probe.dart';
import 'scrcpy_verify/stream_probe.dart';

const String _scid = '7a5e0001';
const int _localPort = 27199;
const int _packetsToRead = 30;
const Duration _readyTimeout = Duration(seconds: 15);
const Duration _powerOnCheckDelay = Duration(milliseconds: 1500);
const Duration _logWaitLimit = Duration(seconds: 5);

Future<void> main(List<String> args) async {
  final serial = _option(args, 'serial');
  final adb = _option(args, 'adb') ?? 'adb';
  if (serial == null) {
    stderr.writeln(
      'Usage: dart run tool/verify_scrcpy_server.dart --serial=<serial>',
    );
    exitCode = 64;
    return;
  }
  const version = ScrcpyServerConstants.version;
  const remoteJar = '/data/local/tmp/deskdroid-verify-$version.jar';
  Process? server;
  final serverLog = <String>[];
  try {
    // By default start with the screen off: with control enabled, the server
    // must turn it on by itself (power_on). --keep-screen skips that check.
    final keepScreen = args.contains('--keep-screen');
    await _adb(adb, serial, [
      'shell',
      'input',
      'keyevent',
      keepScreen ? 'KEYCODE_WAKEUP' : 'KEYCODE_SLEEP',
    ]);
    final screenOffBefore = !await isScreenOn(adb, serial);
    final awake = StayAwakeProbe(adb: adb, serial: serial);
    await awake.recordOriginal();
    await _adb(adb, serial, [
      'push',
      ScrcpyServerConstants.assetKey,
      remoteJar,
    ]);
    server = await Process.start(adb, [
      ...ScrcpyServerCommand.adbArguments(
        deviceSerial: serial,
        remoteJarPath: remoteJar,
        serverVersion: version,
        scid: _scid,
        videoBitRateBps: 8000000,
        maxFps: 60,
        stayAwake: true,
      ),
      // Verification only: makes the server log ignored positional events.
      'log_level=verbose',
    ]);
    final ready = Completer<ScrcpyServerEvent>();
    void onOutput(List<int> data) {
      for (final (event, line) in ScrcpyServerOutput.parseChunk(
        utf8.decode(data, allowMalformed: true),
      )) {
        serverLog.add(line);
        if ((event == ScrcpyServerEvent.ready ||
                event == ScrcpyServerEvent.versionMismatch) &&
            !ready.isCompleted) {
          ready.complete(event);
        }
      }
    }

    server.stdout.listen(onOutput);
    server.stderr.listen(onOutput);
    final event = await ready.future.timeout(_readyTimeout);
    if (event == ScrcpyServerEvent.versionMismatch) {
      throw StateError('Version mismatch');
    }
    await _adb(adb, serial, [
      'forward',
      'tcp:$_localPort',
      'localabstract:scrcpy_$_scid',
    ]);

    final control = ControlProbe(port: _localPort, adb: adb, serial: serial);
    // power_on acts when the controller starts (then sleeps 500 ms); check
    // soon after, because a locked screen turns itself off within seconds.
    late Future<bool> screenOnAfterControl;
    final probe = StreamProbe(port: _localPort);
    final report = await probe.run(
      packets: _packetsToRead,
      onVideoAccepted: () async {
        await control.connect();
        screenOnAfterControl = Future<bool>.delayed(
          _powerOnCheckDelay,
          () => isScreenOn(adb, serial),
        );
      },
    );
    final screenOnAfter = await screenOnAfterControl;
    await awake.recordDuring();
    // Dismisses an insecure (swipe) lock screen; a PIN lock stays.
    await _adb(adb, serial, ['shell', 'wm', 'dismiss-keyguard'], check: false);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final locked = await isKeyguardShowing(adb, serial);
    final skipKeys = args.contains('--skip-keys');
    final keyResults = locked || skipKeys
        ? [
            'keys: skipped '
                '(${skipKeys ? '--skip-keys' : 'device is locked; unlock it to verify HOME/BACK'})',
          ]
        : await control.checkKeys();
    control.sendTapPair(width: report.width, height: report.height);
    // Server logs arrive asynchronously through `adb shell`; wait for them.
    List<String> ignoredEvents() =>
        serverLog.where((l) => l.contains('Ignore positional event')).toList();
    final logWait = Stopwatch()..start();
    while (ignoredEvents().length < 2 && logWait.elapsed < _logWaitLimit) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    // Give a stray third event (it would mean the right-size tap was
    // rejected too) a moment to show up before counting.
    await Future<void>.delayed(const Duration(milliseconds: 500));
    await control.close();
    await probe.close();
    final ignored = ignoredEvents();
    // Stopping the server (as the app does) must restore the settings.
    server.kill();
    await awake.recordAfter();

    final powerOnOk = !screenOffBefore || screenOnAfter;
    final keysOk =
        locked ||
        skipKeys ||
        (keyResults.any((r) => r.contains('launcher')) &&
            keyResults.any((r) => r.startsWith('BACK closed Settings: true')));
    // The wrong-size tap is a DOWN and an UP: two ignored events.
    final tapOk = ignored.length == 2;
    stdout
      ..writeln('scrcpy-server $version on $serial')
      ..writeln(report.describe())
      ..writeln(
        'power_on: screen off before=$screenOffBefore, on after=$screenOnAfter',
      )
      ..writeAll(keyResults.map((r) => '$r\n'))
      ..writeln(
        'positional events ignored by the size check: ${ignored.length} '
        '(expected 2: DOWN and UP of the wrong-size tap)',
      )
      ..writeln(awake.describe());
    final ok = report.isHealthy && powerOnOk && keysOk && tapOk && awake.isOk;
    stdout.writeln(ok ? 'RESULT: OK' : 'RESULT: FAILED');
    if (!ok) exitCode = 1;
  } on TimeoutException {
    stdout.writeln(
      'RESULT: FAILED (no video data in time: is the screen on and unlocked?)',
    );
    exitCode = 1;
  } on Object catch (error) {
    stdout.writeln('RESULT: FAILED ($error)');
    exitCode = 1;
  } finally {
    stdout.writeln('--- server log ---');
    serverLog.take(60).forEach(stdout.writeln);
    server?.kill();
    await _adb(adb, serial, [
      'forward',
      '--remove',
      'tcp:$_localPort',
    ], check: false);
    await _adb(adb, serial, ['shell', 'pkill -f $_scid'], check: false);
    await _adb(adb, serial, ['shell', 'rm -f $remoteJar'], check: false);
  }
}

String? _option(List<String> args, String name) {
  final prefix = '--$name=';
  for (final arg in args) {
    if (arg.startsWith(prefix)) return arg.substring(prefix.length);
  }
  return null;
}

Future<void> _adb(
  String adb,
  String serial,
  List<String> args, {
  bool check = true,
}) async {
  final result = await Process.run(adb, ['-s', serial, ...args]);
  if (check && result.exitCode != 0) {
    throw ProcessException(adb, args, '${result.stderr}', result.exitCode);
  }
}
