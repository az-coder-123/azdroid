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
  late StreamingRepositoryImpl repository;
  var nextTexture = 0;

  setUp(() {
    serverManager = _MockServerManager();
    nativeService = _MockNativeService();
    final preflight = _MockPreflight();
    final control = _MockControlConnector();
    nextTexture = 42;
    when(() => preflight.ensureReady(any())).thenAnswer((_) async {});
    when(() => control.waitForVideoSocket()).thenAnswer((_) async => true);
    when(
      () => control.openControl(
        deviceSerial: any(named: 'deviceSerial'),
        port: any(named: 'port'),
      ),
    ).thenAnswer((_) async => true);
    when(() => control.disconnect()).thenAnswer((_) async {});
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
      () => nativeService.startStream(
        host: any(named: 'host'),
        port: any(named: 'port'),
      ),
    ).thenAnswer((_) async => nextTexture++);
    when(() => nativeService.stopStream()).thenAnswer((_) async {});
    when(() => nativeService.getDimensions())
        .thenAnswer((_) async => {'width': 1080, 'height': 2336});
    repository = StreamingRepositoryImpl(
      serverManager: serverManager,
      videoStreamNativeService: nativeService,
      devicePreflight: preflight,
      controlConnector: control,
      audioService: FakeAudioStreamNativeService(),
    );
  });

  void verifyServerStarted({required bool stayAwake, int times = 1}) {
    verify(
      () => serverManager.startServerDaemon(
        deviceSerial: device.id,
        port: any(named: 'port'),
        maxFps: any(named: 'maxFps'),
        bitrateMbps: any(named: 'bitrateMbps'),
        stayAwake: stayAwake,
      ),
    ).called(times);
  }

  test('startSession passes stay awake to the server', () async {
    final session = await repository.startSession(device, stayAwake: true);

    expect(session.stayAwake, isTrue);
    verifyServerStarted(stayAwake: true);
  });

  test('startSession keeps the phone settings by default', () async {
    final session = await repository.startSession(device);

    expect(session.stayAwake, isFalse);
    verifyServerStarted(stayAwake: false);
  });

  test('updateStayAwake restarts the pipeline with the new value', () async {
    final session = await repository.startSession(device, stayAwake: true);

    final updated = await repository.updateStayAwake(session.sessionId, false);

    expect(updated.stayAwake, isFalse);
    expect(updated.textureId, 43);
    expect(updated.bitrateMbps, session.bitrateMbps);
    verify(() => nativeService.stopStream()).called(1);
    verifyServerStarted(stayAwake: false);
  });

  test('updateStayAwake keeps the pipeline when unchanged', () async {
    final session = await repository.startSession(device, stayAwake: true);

    final updated = await repository.updateStayAwake(session.sessionId, true);

    expect(updated, session);
    verifyNever(() => nativeService.stopStream());
  });

  test('updateBitrate keeps the stay awake choice', () async {
    final session = await repository.startSession(device, stayAwake: true);

    final updated = await repository.updateBitrate(session.sessionId, 16);

    expect(updated.stayAwake, isTrue);
    verifyServerStarted(stayAwake: true, times: 2);
  });

  test('updateStayAwake rejects an unknown session', () {
    expect(
      () => repository.updateStayAwake('missing', true),
      throwsA(isA<StateError>()),
    );
  });
}
