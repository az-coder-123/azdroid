import 'package:desk_droid/core/models/device_entity.dart';
import 'package:desk_droid/core/services/video_stream_native_service.dart';
import 'package:desk_droid/features/streaming/data/datasources/scrcpy_server_manager.dart';
import 'package:desk_droid/features/streaming/data/repositories/streaming_repository_impl.dart';
import 'package:desk_droid/features/streaming/data/services/scrcpy_control_connector.dart';
import 'package:desk_droid/features/streaming/data/services/stream_device_preflight.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/fake_audio_stream_native_service.dart';

class _MockServerManager extends Mock implements ScrcpyServerManager {}

class _MockNativeService extends Mock implements IVideoStreamNativeService {}

class _MockPreflight extends Mock implements StreamDevicePreflight {}

class _MockControlConnector extends Mock implements ScrcpyControlConnector {}

void main() {
  const device = DeviceEntity(
    id: '192.168.1.3:5555',
    name: 'Redmi 9',
    ipAddress: '192.168.1.3',
    port: 5555,
    connectionType: DeviceConnectionType.wireless,
  );

  late _MockServerManager serverManager;
  late _MockNativeService nativeService;
  late _MockControlConnector control;
  late StreamingRepositoryImpl repository;
  late List<String> calls;

  setUp(() {
    serverManager = _MockServerManager();
    nativeService = _MockNativeService();
    control = _MockControlConnector();
    final preflight = _MockPreflight();
    calls = [];
    when(() => preflight.ensureReady(any())).thenAnswer((_) async {});
    when(
      () => serverManager.startServerDaemon(
        deviceSerial: any(named: 'deviceSerial'),
        port: any(named: 'port'),
        maxFps: any(named: 'maxFps'),
        bitrateMbps: any(named: 'bitrateMbps'),
        stayAwake: any(named: 'stayAwake'),
      ),
    ).thenAnswer((_) async => true);
    when(
      () => serverManager.stopServerDaemon(
        deviceSerial: any(named: 'deviceSerial'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => nativeService.startStream(
        host: any(named: 'host'),
        port: any(named: 'port'),
      ),
    ).thenAnswer((_) async => 42);
    when(() => nativeService.stopStream()).thenAnswer((_) async {});
    when(() => nativeService.getDimensions())
        .thenAnswer((_) async => {'width': 1080, 'height': 2336});
    when(() => control.waitForVideoSocket()).thenAnswer((_) async => true);
    when(
      () => control.openControl(
        deviceSerial: any(named: 'deviceSerial'),
        port: any(named: 'port'),
      ),
    ).thenAnswer((_) async => true);
    when(() => control.disconnect()).thenAnswer((_) async {
      calls.add('disconnect');
    });
    when(() => control.setDisplayPower(on: any(named: 'on')))
        .thenAnswer((invocation) {
          calls.add('display ${invocation.namedArguments[#on] ? 'on' : 'off'}');
          return true;
        });
    repository = StreamingRepositoryImpl(
      serverManager: serverManager,
      videoStreamNativeService: nativeService,
      devicePreflight: preflight,
      controlConnector: control,
      audioService: FakeAudioStreamNativeService(),
    );
  });

  test('toggleScreenOff turns the panel off through control', () async {
    final session = await repository.startSession(device);

    expect(await repository.toggleScreenOff(session.sessionId, true), isTrue);
    expect(calls, ['display off']);
    // The POWER key would put the phone to sleep and stop the mirror.
    verifyNever(
      () => serverManager.sendKeyevent(
        deviceSerial: any(named: 'deviceSerial'),
        keyCode: any(named: 'keyCode'),
      ),
    );
  });

  test('toggleScreenOff reports a closed control socket', () async {
    when(() => control.setDisplayPower(on: any(named: 'on'))).thenReturn(false);
    final session = await repository.startSession(device);

    expect(await repository.toggleScreenOff(session.sessionId, true), isFalse);
    await repository.stopSession(session.sessionId);
    // Not marked off, so nothing to turn back on.
    verify(() => control.setDisplayPower(on: false)).called(1);
    verifyNever(() => control.setDisplayPower(on: true));
  });

  test('toggleScreenOff ignores an unknown session', () async {
    await repository.startSession(device);

    expect(await repository.toggleScreenOff('other', true), isFalse);
    verifyNever(() => control.setDisplayPower(on: any(named: 'on')));
  });

  test('startSession can start with the panel off', () async {
    final session = await repository.startSession(device, turnScreenOff: true);

    expect(session.isScreenOff, isTrue);
    expect(calls, ['display off']);
  });

  test('stopSession turns the panel on before closing control', () async {
    final session = await repository.startSession(device);
    await repository.toggleScreenOff(session.sessionId, true);

    await repository.stopSession(session.sessionId);

    expect(calls, ['display off', 'display on', 'disconnect']);
  });

  test('a pipeline restart turns the panel off again', () async {
    final session = await repository.startSession(device);
    await repository.toggleScreenOff(session.sessionId, true);

    final updated = await repository.updateBitrate(session.sessionId, 16);

    expect(updated.isScreenOff, isTrue);
    expect(calls, ['display off', 'disconnect', 'display off']);
  });
}
