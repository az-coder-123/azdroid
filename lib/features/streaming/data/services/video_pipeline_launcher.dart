import 'package:desk_droid/core/constants/socket_config.dart';
import 'package:desk_droid/core/services/video_stream_native_service.dart';
import 'package:desk_droid/features/streaming/data/datasources/scrcpy_server_manager.dart';
import 'package:desk_droid/features/streaming/data/services/scrcpy_control_connector.dart';
import 'package:desk_droid/features/streaming/domain/errors/stream_start_exception.dart';

/// Launch options that scrcpy-server reads only at start.
typedef VideoLaunchOptions = ({int maxFps, int bitrateMbps, bool stayAwake});

/// Starts and stops the three parts of a mirroring pipeline in the order the
/// protocol needs: scrcpy-server, the native video socket, then control.
class VideoPipelineLauncher {
  VideoPipelineLauncher({
    required this._serverManager,
    required this._native,
    required this._control,
  });

  final ScrcpyServerManager _serverManager;
  final IVideoStreamNativeService _native;
  final ScrcpyControlConnector _control;

  /// Starts the server (replacing a running one), connects the native
  /// decoder, then opens the control socket. Returns the texture ID.
  ///
  /// Throws [StreamStartException] when the server does not start or the
  /// control socket does not open; the pipeline is stopped in that case.
  Future<int?> launch(String deviceSerial, VideoLaunchOptions options) async {
    final serverStarted = await _serverManager.startServerDaemon(
      deviceSerial: deviceSerial,
      port: SocketConfig.defaultVideoStreamPort,
      maxFps: options.maxFps,
      bitrateMbps: options.bitrateMbps,
      stayAwake: options.stayAwake,
    );
    if (!serverStarted) {
      throw StreamStartException(
        StreamStartFailure.serverStartFailed,
        deviceSerial: deviceSerial,
      );
    }
    final textureId = await _native.startStream(
      host: SocketConfig.loopbackHost,
      port: SocketConfig.defaultVideoStreamPort,
    );
    // The server streams only once the control socket is connected.
    final controlReady = await _control.connect(
      deviceSerial: deviceSerial,
      port: SocketConfig.defaultVideoStreamPort,
    );
    if (!controlReady) {
      await _native.stopStream();
      await _serverManager.stopServerDaemon(deviceSerial: deviceSerial);
      throw StreamStartException(
        StreamStartFailure.controlConnectFailed,
        deviceSerial: deviceSerial,
      );
    }
    return textureId;
  }

  /// Stops control and video but keeps the server; [launch] replaces it.
  Future<void> stopForRelaunch() async {
    await _control.disconnect();
    await _native.stopStream();
  }

  /// Stops control, video, and the server on [deviceSerial].
  Future<void> stop(String deviceSerial) async {
    await stopForRelaunch();
    await _serverManager.stopServerDaemon(deviceSerial: deviceSerial);
  }
}
