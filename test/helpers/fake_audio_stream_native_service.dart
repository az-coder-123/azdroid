import 'package:desk_droid/core/models/native_audio_stats.dart';
import 'package:desk_droid/core/services/audio_stream_native_service.dart';

/// In-memory [IAudioStreamNativeService] that records calls in order.
class FakeAudioStreamNativeService implements IAudioStreamNativeService {
  FakeAudioStreamNativeService({this.available = false, this.connects = true});

  bool available;
  bool connects;
  final List<String> calls = [];

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> startAudio({String host = '', int port = 0}) async {
    calls.add('startAudio');
    return connects;
  }

  @override
  Future<void> stopAudio() async => calls.add('stopAudio');

  @override
  Future<void> setVolume(double volume) async => calls.add('setVolume');

  @override
  Future<void> setMuted(bool muted) async => calls.add('setMuted');

  @override
  Future<NativeAudioStats?> getStats() async => null;
}
