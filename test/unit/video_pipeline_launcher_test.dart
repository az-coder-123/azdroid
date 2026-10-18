import 'package:desk_droid/core/services/video_stream_native_service.dart';
import 'package:desk_droid/features/streaming/data/datasources/scrcpy_server_manager.dart';
import 'package:desk_droid/features/streaming/data/services/scrcpy_control_connector.dart';
import 'package:desk_droid/features/streaming/data/services/video_pipeline_launcher.dart';
import 'package:desk_droid/features/streaming/domain/errors/stream_start_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/fake_audio_stream_native_service.dart';

class _MockServerManager extends Mock implements ScrcpyServerManager {}

class _MockNative extends Mock implements IVideoStreamNativeService {}

class _MockControl extends Mock implements ScrcpyControlConnector {}

void main() {
  const serial = '192.168.1.3:5555';
  const options = (maxFps: 60, bitrateMbps: 8, stayAwake: true);

  late _MockServerManager server;
  late _MockNative native;
  late _MockControl control;
  late FakeAudioStreamNativeService audio;
  late VideoPipelineLauncher launcher;
  // Shared log: the protocol cares about the order across the three parts.
  late List<String> calls;

  setUp(() {
    server = _MockServerManager();
    native = _MockNative();
    control = _MockControl();
    audio = FakeAudioStreamNativeService(available: true);
    calls = audio.calls;
    when(
      () => server.startServerDaemon(
        deviceSerial: any(named: 'deviceSerial'),
        port: any(named: 'port'),
        maxFps: any(named: 'maxFps'),
        bitrateMbps: any(named: 'bitrateMbps'),
        stayAwake: any(named: 'stayAwake'),
        audio: any(named: 'audio'),
      ),
    ).thenAnswer((_) async => true);
    when(
      () => server.stopServerDaemon(deviceSerial: any(named: 'deviceSerial')),
    ).thenAnswer((_) async => calls.add('stopServer'));
    when(
      () => native.startStream(
        host: any(named: 'host'),
        port: any(named: 'port'),
      ),
    ).thenAnswer((_) async => 7);
    when(() => native.stopStream())
        .thenAnswer((_) async => calls.add('stopVideo'));
    when(() => control.waitForVideoSocket()).thenAnswer((_) async {
      calls.add('videoAccepted');
      return true;
    });
    when(
      () => control.openControl(
        deviceSerial: any(named: 'deviceSerial'),
        port: any(named: 'port'),
      ),
    ).thenAnswer((_) async {
      calls.add('openControl');
      return true;
    });
    when(() => control.disconnect())
        .thenAnswer((_) async => calls.add('closeControl'));
    launcher = VideoPipelineLauncher(
      serverManager: server,
      native: native,
      control: control,
      audio: audio,
    );
  });

  bool serverStartedWithAudio() =>
      verify(
            () => server.startServerDaemon(
              deviceSerial: serial,
              port: any(named: 'port'),
              maxFps: 60,
              bitrateMbps: 8,
              stayAwake: true,
              audio: captureAny(named: 'audio'),
            ),
          ).captured.single
          as bool;

  test('connects video, then audio, then control', () async {
    expect(await launcher.launch(serial, options), 7);

    expect(serverStartedWithAudio(), isTrue);
    expect(calls, ['videoAccepted', 'startAudio', 'openControl']);
  });

  test('without a native player the server runs without audio', () async {
    audio.available = false;

    await launcher.launch(serial, options);

    expect(serverStartedWithAudio(), isFalse);
    expect(calls, ['videoAccepted', 'openControl']);
  });

  test('a failed audio socket stops everything and explains it', () async {
    audio.connects = false;

    await expectLater(
      launcher.launch(serial, options),
      throwsA(
        isA<StreamStartException>().having(
          (e) => e.failure,
          'failure',
          StreamStartFailure.audioConnectFailed,
        ),
      ),
    );
    expect(calls, [
      'videoAccepted',
      'startAudio',
      'closeControl',
      'stopAudio',
      'stopVideo',
      'stopServer',
    ]);
    verifyNever(
      () => control.openControl(
        deviceSerial: any(named: 'deviceSerial'),
        port: any(named: 'port'),
      ),
    );
  });

  test('no audio socket opens when video was never accepted', () async {
    when(() => control.waitForVideoSocket()).thenAnswer((_) async => false);

    await expectLater(
      launcher.launch(serial, options),
      throwsA(
        isA<StreamStartException>().having(
          (e) => e.failure,
          'failure',
          StreamStartFailure.controlConnectFailed,
        ),
      ),
    );
    expect(calls, isNot(contains('startAudio')));
  });

  test('stopForRelaunch stops audio but keeps the server', () async {
    await launcher.stopForRelaunch();

    expect(calls, ['closeControl', 'stopAudio', 'stopVideo']);
  });
}
