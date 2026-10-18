import 'package:equatable/equatable.dart';

/// Lifecycle state reported by the native `getStats` method.
enum NativeStreamState {
  idle,

  /// Waiting for the server to accept the video socket.
  connecting,

  /// The server accepted the video socket and waits for the control socket
  /// before it sends the stream header. The client must connect control now.
  connected,
  streaming,
  failed,
  ended,

  /// A state name this app version does not know yet.
  unknown;

  static NativeStreamState fromWireName(Object? name) =>
      values.firstWhere((state) => state.name == name, orElse: () => unknown);
}

/// Raw snapshot from `getStats` (see docs/native-video-contract.md).
///
/// Counters are cumulative since the stream started, so rates come from the
/// difference between two snapshots.
class NativeStreamStats extends Equatable {
  const NativeStreamStats({
    required this.state,
    this.framesDecoded = 0,
    this.bytesReceived = 0,
    this.processingTimeUs = 0,
  });

  factory NativeStreamStats.fromMap(Map<Object?, Object?> map) {
    int readInt(String key) => (map[key] as num?)?.toInt() ?? 0;
    return NativeStreamStats(
      state: NativeStreamState.fromWireName(map['state']),
      framesDecoded: readInt('framesDecoded'),
      bytesReceived: readInt('bytesReceived'),
      processingTimeUs: readInt('processingTimeUs'),
    );
  }

  final NativeStreamState state;
  final int framesDecoded;
  final int bytesReceived;

  /// Sum of "packet received → frame published" times, in microseconds.
  final int processingTimeUs;

  @override
  List<Object?> get props => [
    state,
    framesDecoded,
    bytesReceived,
    processingTimeUs,
  ];
}
