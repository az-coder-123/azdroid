import 'package:desk_droid/core/models/device_entity.dart';
import 'package:desk_droid/core/services/app_logger.dart';
import 'package:desk_droid/core/services/audio_stream_native_service.dart';
import 'package:desk_droid/core/services/scrcpy_control_channel.dart';
import 'package:desk_droid/core/services/video_stream_native_service.dart';
import 'package:desk_droid/features/streaming/data/datasources/scrcpy_server_manager.dart';
import 'package:desk_droid/features/streaming/data/services/scrcpy_control_connector.dart';
import 'package:desk_droid/features/streaming/data/services/stream_device_preflight.dart';
import 'package:desk_droid/features/streaming/data/services/stream_telemetry_sampler.dart';
import 'package:desk_droid/features/streaming/data/services/video_pipeline_launcher.dart';
import 'package:desk_droid/features/streaming/domain/entities/stream_session_entity.dart';
import 'package:desk_droid/features/streaming/domain/entities/stream_telemetry.dart';
import 'package:desk_droid/features/streaming/domain/repositories/streaming_repository.dart';

/// Concrete implementation of [StreamingRepository] orchestrating server daemon and native decoder.
class StreamingRepositoryImpl implements StreamingRepository {
  factory StreamingRepositoryImpl({
    ScrcpyServerManager? serverManager,
    IVideoStreamNativeService? videoStreamNativeService,
    StreamDevicePreflight? devicePreflight,
    StreamTelemetrySampler? telemetrySampler,
    ScrcpyControlConnector? controlConnector,
    IAudioStreamNativeService? audioService,
  }) {
    final native = videoStreamNativeService ?? VideoStreamNativeService();
    return StreamingRepositoryImpl._(
      serverManager: serverManager ?? ScrcpyServerManager(),
      nativeService: native,
      devicePreflight: devicePreflight ?? StreamDevicePreflight(),
      telemetrySampler:
          telemetrySampler ?? StreamTelemetrySampler(nativeService: native),
      controlConnector:
          controlConnector ??
          ScrcpyControlConnector(
            nativeService: native,
            channel: SocketScrcpyControlChannel(),
          ),
      audioService: audioService ?? AudioStreamNativeService(),
    );
  }

  StreamingRepositoryImpl._({
    required this._serverManager,
    required this._nativeService,
    required this._devicePreflight,
    required this._telemetrySampler,
    required this._controlConnector,
    required this._audioService,
  });

  final ScrcpyServerManager _serverManager;
  final IVideoStreamNativeService _nativeService;
  final StreamDevicePreflight _devicePreflight;
  final StreamTelemetrySampler _telemetrySampler;
  final ScrcpyControlConnector _controlConnector;
  final IAudioStreamNativeService _audioService;
  late final VideoPipelineLauncher _pipeline = VideoPipelineLauncher(
    serverManager: _serverManager,
    native: _nativeService,
    control: _controlConnector,
    audio: _audioService,
  );

  StreamSessionEntity? _currentSession;

  @override
  Future<StreamSessionEntity> startSession(
    DeviceEntity device, {
    int? maxFps,
    int? bitrateMbps,
    bool? turnScreenOff,
    bool stayAwake = false,
  }) async {
    final fps = maxFps ?? 60;
    final bitrate = bitrateMbps ?? 8;

    AppLogger.info(
      'Starting streaming session for ${device.name} (${device.id})...',
    );

    // 1. Fail fast with a clear reason instead of showing a black viewport
    await _devicePreflight.ensureReady(device.id);

    // 2. Launch the scrcpy server, the native decoder, and control
    final textureId = await _pipeline.launch(device.id, (
      maxFps: fps,
      bitrateMbps: bitrate,
      stayAwake: stayAwake,
    ));

    // 3. Obtain real device frame dimensions from decoded header
    final dims = await _nativeService.getDimensions();
    final realWidth = dims['width'] ?? 0;
    final realHeight = dims['height'] ?? 0;

    // 4. Turn the display panel off if requested (mirroring continues)
    final screenOff =
        (turnScreenOff ?? false) &&
        _controlConnector.setDisplayPower(on: false);

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
      stayAwake: stayAwake,
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
      // The server's restore process would also do this when it exits; doing
      // it here turns the panel on at once.
      if (session.isScreenOff) _controlConnector.setDisplayPower(on: true);
      await _pipeline.stop(session.deviceId);
    }
    _currentSession = null;
  }

  @override
  Future<bool> toggleScreenOff(String sessionId, bool turnOff) async {
    final session = _currentSession;
    if (session == null || session.sessionId != sessionId) return false;
    final sent = _controlConnector.setDisplayPower(on: !turnOff);
    if (sent) _currentSession = session.copyWith(isScreenOff: turnOff);
    return sent;
  }

  @override
  Future<StreamSessionEntity> updateBitrate(
    String sessionId,
    int bitrateMbps,
  ) => _restartPipeline(
    sessionId,
    (session) => session.copyWith(bitrateMbps: bitrateMbps),
  );

  @override
  Future<StreamSessionEntity> updateStayAwake(
    String sessionId,
    bool stayAwake,
  ) => _restartPipeline(
    sessionId,
    (session) => session.copyWith(stayAwake: stayAwake),
  );

  /// Relaunches the pipeline with the launch options of [change] applied to
  /// the active session. scrcpy reads them only at launch. Returns the
  /// session unchanged when [change] changes none of them.
  Future<StreamSessionEntity> _restartPipeline(
    String sessionId,
    StreamSessionEntity Function(StreamSessionEntity session) change,
  ) async {
    final session = _currentSession;
    if (session == null || session.sessionId != sessionId) {
      throw StateError('No active streaming session $sessionId');
    }
    final target = change(session);
    if (target == session) return session;

    AppLogger.info(
      'Restarting video pipeline for ${session.deviceId} '
      '(${target.bitrateMbps} Mbps, stay awake: ${target.stayAwake})',
    );
    await _pipeline.stopForRelaunch();
    final textureId = await _pipeline.launch(session.deviceId, (
      maxFps: target.fps,
      bitrateMbps: target.bitrateMbps,
      stayAwake: target.stayAwake,
    ));
    // The old server turned the panel back on when it exited.
    final screenOff =
        target.isScreenOff && _controlConnector.setDisplayPower(on: false);

    final updated = target.copyWith(
      textureId: textureId,
      isScreenOff: screenOff,
    );
    _currentSession = updated;
    return updated;
  }
}
