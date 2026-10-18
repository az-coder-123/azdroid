import 'package:equatable/equatable.dart';

/// A launch option being applied by a video pipeline restart.
sealed class PendingStreamChange extends Equatable {
  const PendingStreamChange();
}

/// New video bitrate in Mbps.
final class BitrateChange extends PendingStreamChange {
  const BitrateChange(this.bitrateMbps);

  final int bitrateMbps;

  @override
  List<Object?> get props => [bitrateMbps];
}

/// "Keep the phone awake" turned on or off.
final class StayAwakeChange extends PendingStreamChange {
  const StayAwakeChange({required this.enabled});

  final bool enabled;

  @override
  List<Object?> get props => [enabled];
}
