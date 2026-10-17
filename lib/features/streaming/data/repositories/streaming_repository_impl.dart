import 'package:desk_droid/core/constants/socket_config.dart';
import 'package:desk_droid/core/models/device_entity.dart';
import 'package:desk_droid/core/services/app_logger.dart';
import 'package:desk_droid/core/services/video_stream_native_service.dart';
import 'package:desk_droid/features/streaming/data/datasources/scrcpy_server_manager.dart';
import 'package:desk_droid/features/streaming/domain/entities/stream_session_entity.dart';
import 'package:desk_droid/features/streaming/domain/repositories/streaming_repository.dart';

/// Concrete implementation of [StreamingRepository] orchestrating server daemon and native decoder.
class StreamingRepositoryImpl implements StreamingRepository {
  StreamingRepositoryImpl({
    ScrcpyServerManager? serverManager,
    IVideoStreamNativeService? videoStreamNativeService,
  }) : _serverManager = serverManager ?? ScrcpyServerManager(),
       _videoStreamNativeService =
           videoStreamNativeService ?? VideoStreamNativeService();

  final ScrcpyServerManager _serverManager;
  final IVideoStreamNativeService _videoStreamNativeService;

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

    AppLogger.info(
      'Starting streaming session for ${device.name} (${device.id})...',
    );

    // 1. Launch persistent scrcpy-server daemon on target
    await _serverManager.startServerDaemon(
      deviceSerial: device.id,
      port: SocketConfig.defaultVideoStreamPort,
      maxFps: fps,
      bitrateMbps: bitrate,
    );

    // 2. Connect native VideoToolbox decoder and obtain hardware texture ID
    final textureId = await _videoStreamNativeService.startStream(
      host: '127.0.0.1',
      port: SocketConfig.defaultVideoStreamPort,
    );

    // 3. Obtain real device frame dimensions from decoded header
    final dims = await _videoStreamNativeService.getDimensions();
    final realWidth = dims['width'] ?? 0;
    final realHeight = dims['height'] ?? 0;

    // 4. Turn screen off if requested
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
      width: realWidth > 0 ? realWidth : 1080,
      height: realHeight > 0 ? realHeight : 2400,
      fps: fps,
      bitrateMbps: bitrate,
      textureId: textureId,
      isScreenOff: screenOff,
      latencyMs: 16,
    );

    _currentSession = session;
    return session;
  }

  @override
  Future<void> stopSession(String sessionId) async {
    final session = _currentSession;
    if (session != null) {
      // Restore physical screen if turned off
      if (session.isScreenOff) {
        await _serverManager.setScreenPower(
          deviceSerial: session.deviceId,
          powerOff: false,
        );
      }

      await _videoStreamNativeService.stopStream();
      await _serverManager.stopServerDaemon(deviceSerial: session.deviceId);
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
