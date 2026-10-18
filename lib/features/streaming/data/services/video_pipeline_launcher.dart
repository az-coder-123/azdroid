import 'package:desk_droid/core/constants/socket_config.dart';
import 'package:desk_droid/core/services/audio_stream_native_service.dart';
import 'package:desk_droid/core/services/video_stream_native_service.dart';
import 'package:desk_droid/features/streaming/data/datasources/scrcpy_server_manager.dart';
import 'package:desk_droid/features/streaming/data/services/scrcpy_control_connector.dart';
import 'package:desk_droid/features/streaming/domain/errors/stream_start_exception.dart';

/// Launch options that scrcpy-server reads only at start.
typedef VideoLaunchOptions = ({int maxFps, int bitrateMbps, bool stayAwake});

/// Starts and stops the parts of a mirroring pipeline in the order the
/// protocol needs: scrcpy-server, then the video, audio, and control
/// sockets (docs/native-video-contract.md, docs/native-audio-contract.md).
class VideoPipelineLauncher {
  VideoPipelineLauncher({
    required this._serverManager,
    required this._native,
    required this._control,
    required this._audio,
  });

  final ScrcpyServerManager _serverManager;
  final IVideoStreamNativeService _native;
  final ScrcpyControlConnector _control;
  final IAudioStreamNativeService _audio;

  /// Starts the server (replacing a running one), connects the native
  /// decoder, the audio player when this platform has one, then control.
  /// Returns the texture ID.
  ///
  /// Throws [StreamStartException] when the server does not start or a
  /// socket does not open; the pipeline is stopped in that case.
  Future<int?> launch(String deviceSerial, VideoLaunchOptions options) async {
    // Decided before the server starts: with audio=true it accepts control
    // only after an audio socket.
    final withAudio = await _audio.isAvailable();
    final serverStarted = await _serverManager.startServerDaemon(
      deviceSerial: deviceSerial,
      port: SocketConfig.defaultVideoStreamPort,
      maxFps: options.maxFps,
      bitrateMbps: options.bitrateMbps,
      stayAwake: options.stayAwake,
      audio: withAudio,
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
    if (!await _control.waitForVideoSocket()) {
      await _abort(deviceSerial, StreamStartFailure.controlConnectFailed);
    }
    if (withAudio &&
        !await _audio.startAudio(
          host: SocketConfig.loopbackHost,
          port: SocketConfig.defaultVideoStreamPort,
        )) {
      await _abort(deviceSerial, StreamStartFailure.audioConnectFailed);
    }
    // The server streams only once the control socket is connected.
    if (!await _control.openControl(
      deviceSerial: deviceSerial,
      port: SocketConfig.defaultVideoStreamPort,
    )) {
      await _abort(deviceSerial, StreamStartFailure.controlConnectFailed);
    }
    return textureId;
  }

  /// Stops control, audio, and video but keeps the server; [launch]
  /// replaces it.
  Future<void> stopForRelaunch() async {
    await _control.disconnect();
    await _audio.stopAudio();
    await _native.stopStream();
  }

  /// Stops control, audio, video, and the server on [deviceSerial].
  Future<void> stop(String deviceSerial) async {
    await stopForRelaunch();
    await _serverManager.stopServerDaemon(deviceSerial: deviceSerial);
  }

  Future<Never> _abort(String deviceSerial, StreamStartFailure failure) async {
    await stop(deviceSerial);
    throw StreamStartException(failure, deviceSerial: deviceSerial);
  }
}
