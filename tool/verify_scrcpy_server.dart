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

import 'scrcpy_verify/stream_probe.dart';

const String _scid = '7a5e0001';
const int _localPort = 27199;
const int _packetsToRead = 30;
const Duration _readyTimeout = Duration(seconds: 15);

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
    // Displays only produce frames while the screen is on.
    stdout.writeln('Waking the device screen (no frames while it is off).');
    await _adb(adb, serial, ['shell', 'input', 'keyevent', 'KEYCODE_WAKEUP']);
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
      ),
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

    final report = await StreamProbe(port: _localPort)
        .run(packets: _packetsToRead);
    stdout
      ..writeln('scrcpy-server $version on $serial')
      ..writeln(report.describe())
      ..writeln(report.isHealthy ? 'RESULT: OK' : 'RESULT: FAILED');
    if (!report.isHealthy) exitCode = 1;
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
    serverLog.take(40).forEach(stdout.writeln);
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
