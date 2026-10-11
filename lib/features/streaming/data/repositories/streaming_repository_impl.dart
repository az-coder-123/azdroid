import 'package:wifi_desk/core/constants/socket_config.dart';
import 'package:wifi_desk/features/discovery/domain/entities/device_entity.dart';
import 'package:wifi_desk/features/streaming/data/datasources/scrcpy_server_manager.dart';
import 'package:wifi_desk/features/streaming/data/datasources/streaming_socket_datasource.dart';
import 'package:wifi_desk/features/streaming/domain/entities/stream_session_entity.dart';
import 'package:wifi_desk/features/streaming/domain/repositories/streaming_repository.dart';

/// Concrete implementation of [StreamingRepository] orchestrating server and socket layers.
class StreamingRepositoryImpl implements StreamingRepository {
  StreamingRepositoryImpl({
    ScrcpyServerManager? serverManager,
    StreamingSocketDatasource? socketDatasource,
  }) : _serverManager = serverManager ?? ScrcpyServerManager(),
       _socketDatasource = socketDatasource ?? StreamingSocketDatasourceImpl();

  final ScrcpyServerManager _serverManager;
  final StreamingSocketDatasource _socketDatasource;

  StreamSessionEntity? _currentSession;

  @override
  Future<StreamSessionEntity> startSession(
    DeviceEntity device, {
    int? maxFps,
    int? bitrateMbps,
    bool? turnScreenOff,
  }) async {
    final fps = maxFps ?? 60;
    final bitrate = bitrateMbps ?? 8;
    final screenOff = turnScreenOff ?? false;

    // 1. Start scrcpy-server daemon on Android target
    await _serverManager.startServerDaemon(
      deviceSerial: device.id,
      maxFps: fps,
      bitrateMbps: bitrate,
    );

    // 2. Open TCP stream connection
    await _socketDatasource.connect(port: SocketConfig.defaultVideoStreamPort);

    // 3. Turn screen off if requested
    if (screenOff) {
      await _serverManager.setScreenPower(
        deviceSerial: device.id,
        powerOff: true,
      );
    }

    final session = StreamSessionEntity(
      sessionId:
          'session_${device.id}_${DateTime.now().millisecondsSinceEpoch}',
      deviceId: device.id,
      deviceName: device.name,
      width: 1080,
      height: 2400,
      fps: fps,
      bitrateMbps: bitrate,
      isScreenOff: screenOff,
      latencyMs: 18,
    );

    _currentSession = session;
    return session;
  }

  @override
  Future<void> stopSession(String sessionId) async {
    final session = _currentSession;
    if (session != null) {
      // Restore phone screen if was turned off
      if (session.isScreenOff) {
        await _serverManager.setScreenPower(
          deviceSerial: session.deviceId,
          powerOff: false,
        );
      }

      await _socketDatasource.disconnect();
      await _serverManager.removePortForward(deviceSerial: session.deviceId);
    }
    _currentSession = null;
  }

  @override
  Future<void> toggleScreenOff(String sessionId, bool turnOff) async {
    final session = _currentSession;
    if (session != null) {
      await _serverManager.setScreenPower(
        deviceSerial: session.deviceId,
        powerOff: turnOff,
      );
      _currentSession = session.copyWith(isScreenOff: turnOff);
    }
  }

  @override
  Future<void> updateBitrate(String sessionId, int bitrateMbps) async {
    final session = _currentSession;
    if (session != null) {
      _currentSession = session.copyWith(bitrateMbps: bitrateMbps);
    }
  }

  @override
  Future<void> sendNavigationKey(String sessionId, int keyCode) async {
    final session = _currentSession;
    if (session != null) {
      await _serverManager.sendKeyevent(
        deviceSerial: session.deviceId,
        keyCode: keyCode,
      );
    }
  }
}
