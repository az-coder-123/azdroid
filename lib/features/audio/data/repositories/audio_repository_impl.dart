import 'package:desk_droid/core/constants/audio_constants.dart';
import 'package:desk_droid/core/constants/socket_config.dart';
import 'package:desk_droid/core/services/adb_port_forwarder.dart';
import 'package:desk_droid/features/audio/data/datasources/audio_socket_datasource.dart';
import 'package:desk_droid/features/audio/domain/entities/audio_stream_entity.dart';
import 'package:desk_droid/features/audio/domain/repositories/audio_repository.dart';

/// Concrete implementation of [AudioRepository] managing audio tunnels and playback controls.
class AudioRepositoryImpl implements AudioRepository {
  AudioRepositoryImpl({
    required this._portForwarder,
    AudioSocketDatasource? socketDatasource,
  }) : _socketDatasource = socketDatasource ?? AudioSocketDatasourceImpl();

  final AdbPortForwarder _portForwarder;
  final AudioSocketDatasource _socketDatasource;

  double _volume = AudioConstants.defaultVolume;
  bool _isMuted = false;

  @override
  Future<AudioStreamEntity> startAudioStream(
    String deviceSerial, {
    int? sampleRate,
    int? channels,
    String? codec,
  }) async {
    // 1. Establish ADB port forwarding for the audio socket tunnel
    await _portForwarder.setupPortForward(
      deviceSerial: deviceSerial,
      localPort: SocketConfig.defaultAudioStreamPort,
    );

    // 2. Connect local TCP socket
    await _socketDatasource.connect(port: SocketConfig.defaultAudioStreamPort);

    return AudioStreamEntity(
      deviceId: deviceSerial,
      isEnabled: true,
      isMuted: _isMuted,
      volume: _volume,
      sampleRate: sampleRate ?? AudioConstants.defaultSampleRate,
      channels: channels ?? AudioConstants.defaultChannels,
      codec: codec ?? AudioConstants.defaultAudioCodec,
    );
  }

  @override
  Future<void> stopAudioStream(String deviceSerial) async {
    await _socketDatasource.disconnect();
    await _portForwarder.removePortForward(
      deviceSerial: deviceSerial,
      localPort: SocketConfig.defaultAudioStreamPort,
    );
  }

  @override
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(AudioConstants.minVolume, AudioConstants.maxVolume);
  }

  @override
  Future<bool> toggleMute() async {
    _isMuted = !_isMuted;
    return _isMuted;
  }
}
