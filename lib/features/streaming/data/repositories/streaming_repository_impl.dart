import 'package:desk_droid/core/constants/socket_config.dart';
import 'package:desk_droid/core/models/device_entity.dart';
import 'package:desk_droid/core/services/app_logger.dart';
import 'package:desk_droid/core/services/scrcpy_control_channel.dart';
import 'package:desk_droid/core/services/video_stream_native_service.dart';
import 'package:desk_droid/features/streaming/data/datasources/scrcpy_server_manager.dart';
import 'package:desk_droid/features/streaming/data/services/scrcpy_control_connector.dart';
import 'package:desk_droid/features/streaming/data/services/stream_device_preflight.dart';
import 'package:desk_droid/features/streaming/data/services/stream_telemetry_sampler.dart';
import 'package:desk_droid/features/streaming/domain/entities/stream_session_entity.dart';
import 'package:desk_droid/features/streaming/domain/entities/stream_telemetry.dart';
import 'package:desk_droid/features/streaming/domain/errors/stream_start_exception.dart';
import 'package:desk_droid/features/streaming/domain/repositories/streaming_repository.dart';

/// Concrete implementation of [StreamingRepository] orchestrating server daemon and native decoder.
class StreamingRepositoryImpl implements StreamingRepository {
  StreamingRepositoryImpl({
    ScrcpyServerManager? serverManager,
    IVideoStreamNativeService? videoStreamNativeService,
    StreamDevicePreflight? devicePreflight,
    StreamTelemetrySampler? telemetrySampler,
    ScrcpyControlConnector? controlConnector,
  }) : _serverManager = serverManager ?? ScrcpyServerManager(),
       _videoStreamNativeService =
           videoStreamNativeService ?? VideoStreamNativeService(),
       _devicePreflight = devicePreflight ?? StreamDevicePreflight(),
       _controlConnector =
           controlConnector ??
           ScrcpyControlConnector(
             nativeService:
                 videoStreamNativeService ?? VideoStreamNativeService(),
             channel: SocketScrcpyControlChannel(),
           ),
       // The native service is a stateless channel wrapper, so a second
       // default instance for the sampler is harmless.
       _telemetrySampler =
           telemetrySampler ??
           StreamTelemetrySampler(
             nativeService:
                 videoStreamNativeService ?? VideoStreamNativeService(),
           );

  final ScrcpyServerManager _serverManager;
  final IVideoStreamNativeService _videoStreamNativeService;
  final StreamDevicePreflight _devicePreflight;
  final StreamTelemetrySampler _telemetrySampler;
  final ScrcpyControlConnector _controlConnector;

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

    // 1. Fail fast with a clear reason instead of showing a black viewport
    await _devicePreflight.ensureReady(device.id);

    // 2. Launch the scrcpy server and connect the native decoder
    final textureId = await _launchVideoPipeline(
      device.id,
      maxFps: fps,
      bitrateMbps: bitrate,
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
      // Usually 0 here: the native side connects in the background. The
      // telemetry stream replaces the placeholder with the real size.
      width: realWidth > 0 ? realWidth : StreamSessionEntity.placeholderWidth,
      height: realHeight > 0
          ? realHeight
          : StreamSessionEntity.placeholderHeight,
      fps: fps,
      bitrateMbps: bitrate,
      textureId: textureId,
      isScreenOff: screenOff,
    );

    _currentSession = session;
    return session;
  }

  @override
  Stream<StreamTelemetry> watchTelemetry() => _telemetrySampler.watch();

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

      await _controlConnector.disconnect();
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
  Future<StreamSessionEntity> updateBitrate(
    String sessionId,
    int bitrateMbps,
  ) async {
    final session = _currentSession;
    if (session == null || session.sessionId != sessionId) {
      throw StateError('No active streaming session $sessionId');
    }
    if (session.bitrateMbps == bitrateMbps) return session;

    // scrcpy reads `video_bit_rate` only at launch, so restart the pipeline.
    AppLogger.info(
      'Restarting video pipeline at $bitrateMbps Mbps for ${session.deviceId}',
    );
    await _controlConnector.disconnect();
    await _videoStreamNativeService.stopStream();
    final textureId = await _launchVideoPipeline(
      session.deviceId,
      maxFps: session.fps,
      bitrateMbps: bitrateMbps,
    );

    final updated = session.copyWith(
      bitrateMbps: bitrateMbps,
      textureId: textureId,
    );
    _currentSession = updated;
    return updated;
  }

  /// Starts the scrcpy server (replacing a running one), connects the native
  /// decoder, then opens the control socket. Returns the new texture ID.
  Future<int?> _launchVideoPipeline(
    String deviceSerial, {
    required int maxFps,
    required int bitrateMbps,
  }) async {
    final serverStarted = await _serverManager.startServerDaemon(
      deviceSerial: deviceSerial,
      port: SocketConfig.defaultVideoStreamPort,
      maxFps: maxFps,
      bitrateMbps: bitrateMbps,
    );
    if (!serverStarted) {
      throw StreamStartException(
        StreamStartFailure.serverStartFailed,
        deviceSerial: deviceSerial,
      );
    }
    final textureId = await _videoStreamNativeService.startStream(
      host: SocketConfig.loopbackHost,
      port: SocketConfig.defaultVideoStreamPort,
    );
    // The server streams only once the control socket is connected.
    final controlReady = await _controlConnector.connect(
      deviceSerial: deviceSerial,
      port: SocketConfig.defaultVideoStreamPort,
    );
    if (!controlReady) {
      await _videoStreamNativeService.stopStream();
      await _serverManager.stopServerDaemon(deviceSerial: deviceSerial);
      throw StreamStartException(
        StreamStartFailure.controlConnectFailed,
        deviceSerial: deviceSerial,
      );
    }
    return textureId;
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
