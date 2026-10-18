import 'package:equatable/equatable.dart';

/// Audio player state reported by the native `getAudioStats` method
/// (docs/native-audio-contract.md).
enum NativeAudioState {
  idle,

  /// Socket open, waiting for the audio header.
  connecting,
  playing,

  /// The device cannot capture audio (Android 10 or older).
  disabled,
  failed,
  ended,

  /// A state name this app version does not know yet.
  unknown;

  static NativeAudioState fromWireName(Object? name) =>
      values.firstWhere((state) => state.name == name, orElse: () => unknown);
}

/// Raw snapshot from `getAudioStats`. Counters are cumulative per session.
class NativeAudioStats extends Equatable {
  const NativeAudioStats({
    required this.state,
    this.bytesReceived = 0,
    this.bufferedFrames = 0,
    this.playedFrames = 0,
    this.droppedFrames = 0,
    this.underruns = 0,
  });

  factory NativeAudioStats.fromMap(Map<Object?, Object?> map) {
    int readInt(String key) => (map[key] as num?)?.toInt() ?? 0;
    return NativeAudioStats(
      state: NativeAudioState.fromWireName(map['state']),
      bytesReceived: readInt('bytesReceived'),
      bufferedFrames: readInt('bufferedFrames'),
      playedFrames: readInt('playedFrames'),
      droppedFrames: readInt('droppedFrames'),
      underruns: readInt('underruns'),
    );
  }

  /// scrcpy raw audio rate (frames per second).
  static const int sampleRate = 48000;

  final NativeAudioState state;
  final int bytesReceived;
  final int bufferedFrames;
  final int playedFrames;
  final int droppedFrames;
  final int underruns;

  /// Audio waiting in the jitter buffer, in milliseconds.
  int get bufferedMs =>
      bufferedFrames * Duration.millisecondsPerSecond ~/ sampleRate;

  @override
  List<Object?> get props => [
    state,
    bytesReceived,
    bufferedFrames,
    playedFrames,
    droppedFrames,
    underruns,
  ];
}
