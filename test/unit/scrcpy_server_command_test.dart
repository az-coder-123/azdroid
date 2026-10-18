import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:desk_droid/core/constants/scrcpy_server_constants.dart';
import 'package:desk_droid/features/streaming/data/services/scrcpy_server_command.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final args = ScrcpyServerCommand.adbArguments(
    deviceSerial: '192.168.1.3:5555',
    remoteJarPath: ScrcpyServerConstants.remoteJarPath,
    serverVersion: ScrcpyServerConstants.version,
    scid: ScrcpyServerConstants.scid,
    videoBitRateBps: 8000000,
    maxFps: 60,
    stayAwake: true,
    audio: true,
  );

  test('runs the server class with the client version first', () {
    final mainIndex = args.indexOf(ScrcpyServerCommand.mainClass);
    expect(mainIndex, greaterThan(0));
    expect(args[mainIndex + 1], ScrcpyServerConstants.version);
    expect(args, contains('CLASSPATH=${ScrcpyServerConstants.remoteJarPath}'));
  });

  test('passes bitrate and frame rate', () {
    expect(args, containsAll(['video_bit_rate=8000000', 'max_fps=60']));
  });

  test('stay awake keeps the phone on while charging and on battery', () {
    expect(
      args,
      containsAll([
        'cleanup=true',
        'stay_awake=true',
        'screen_off_timeout=${ScrcpyServerConstants.stayAwakeScreenOffTimeoutMs}',
      ]),
    );
  });

  test('without stay awake, no device setting is changed', () {
    final plain = ScrcpyServerCommand.adbArguments(
      deviceSerial: '192.168.1.3:5555',
      remoteJarPath: ScrcpyServerConstants.remoteJarPath,
      serverVersion: ScrcpyServerConstants.version,
      scid: ScrcpyServerConstants.scid,
      videoBitRateBps: 8000000,
      maxFps: 60,
      stayAwake: false,
      audio: false,
    );
    expect(plain.where((a) => a.startsWith('stay_awake')), isEmpty);
    expect(plain.where((a) => a.startsWith('screen_off_timeout')), isEmpty);
    expect(plain, contains('cleanup=true'));
  });

  test('audio requests raw PCM, which needs no decoder', () {
    expect(args, containsAll(['audio=true', 'audio_codec=raw']));
  });

  test('without audio, no audio codec is sent', () {
    final plain = ScrcpyServerCommand.adbArguments(
      deviceSerial: '192.168.1.3:5555',
      remoteJarPath: ScrcpyServerConstants.remoteJarPath,
      serverVersion: ScrcpyServerConstants.version,
      scid: ScrcpyServerConstants.scid,
      videoBitRateBps: 8000000,
      maxFps: 60,
      stayAwake: false,
      audio: false,
    );
    expect(plain, contains('audio=false'));
    expect(plain.where((a) => a.startsWith('audio_codec')), isEmpty);
  });

  // The server rejects unknown keys, so every key must exist in the bundled
  // jar. This fails if an upgrade drops or renames an option.
  test('every option key exists in the bundled scrcpy-server.jar', () {
    final archive = ZipDecoder().decodeBytes(
      File(ScrcpyServerConstants.assetKey).readAsBytesSync(),
    );
    final dex = latin1.decode(archive.findFile('classes.dex')!.readBytes()!);
    final keys = [
      for (final arg in args)
        if (arg.contains('=') && !arg.startsWith('CLASSPATH='))
          arg.split('=').first,
    ];

    expect(keys, isNotEmpty);
    for (final key in keys) {
      expect(dex.contains(key), isTrue, reason: 'option "$key" not in jar');
    }
    expect(dex.contains('Lcom/genymobile/scrcpy/Server;'), isTrue);
    // The restore process is waited for by class name (ScrcpyCleanupWaiter).
    final cleanupClass = ScrcpyServerConstants.cleanupMainClass.replaceAll(
      '.',
      '/',
    );
    expect(dex.contains('L$cleanupClass;'), isTrue);
  });
}
