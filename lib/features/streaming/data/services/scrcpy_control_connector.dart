import 'package:desk_droid/core/models/native_stream_stats.dart';
import 'package:desk_droid/core/services/app_logger.dart';
import 'package:desk_droid/core/services/scrcpy_control_channel.dart';
import 'package:desk_droid/core/services/scrcpy_control_message.dart';
import 'package:desk_droid/core/services/video_stream_native_service.dart';

/// Opens the scrcpy control socket at the only correct moment, and sends
/// the session-level commands that streaming owns (display power).
///
/// In forward-tunnel mode the server accepts the video socket first and the
/// control socket second, and it sends the stream header only after both
/// exist. Connecting control too early would make it the video socket;
/// waiting for the header would deadlock. So this waits until the native
/// plugin reports `connected` (dummy byte read), then connects.
/// See docs/native-video-contract.md.
class ScrcpyControlConnector {
  ScrcpyControlConnector({
    required IVideoStreamNativeService nativeService,
    required this._channel,
    this.pollInterval = const Duration(milliseconds: 50),
    this.timeout = const Duration(seconds: 15),
  }) : _native = nativeService;

  final IVideoStreamNativeService _native;
  final ScrcpyControlChannel _channel;

  /// How often the native stream state is checked.
  final Duration pollInterval;

  /// Upper bound covering the native plugins' 30 connection attempts.
  final Duration timeout;

  /// Waits for the video socket, then opens control. Returns `false` when the
  /// stream fails first, when [timeout] elapses, or when connecting fails.
  Future<bool> connect({
    required String deviceSerial,
    required int port,
  }) async {
    final stopwatch = Stopwatch()..start();
    while (stopwatch.elapsed < timeout) {
      final state = (await _native.getStats())?.state;
      switch (state) {
        case NativeStreamState.connected:
          return _channel.connect(deviceSerial: deviceSerial, port: port);
        case NativeStreamState.failed || NativeStreamState.ended:
          AppLogger.warning(
            'Video stream ${state!.name} before control opened',
          );
          return false;
        case _:
          await Future<void>.delayed(pollInterval);
      }
    }
    AppLogger.warning(
      'Video socket not accepted within ${timeout.inSeconds}s; control not opened',
    );
    return false;
  }

  /// Turns the device's display panel off (`on: false`) or back on while
  /// mirroring continues. Returns `false` when control is not connected.
  bool setDisplayPower({required bool on}) =>
      _channel.send(ScrcpyControlMessage.setDisplayPower(on: on));

  /// Closes the control socket of the current session.
  Future<void> disconnect() => _channel.close();
}
