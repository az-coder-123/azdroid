import 'package:equatable/equatable.dart';

/// Phase of a live touch stream: fingers go down, move, and lift together.
enum TouchStreamPhase { start, move, end }

/// A finger position relative to the video frame, 0.0 – 1.0 on both axes.
class NormalizedPoint extends Equatable {
  const NormalizedPoint(this.x, this.y);

  final double x;
  final double y;

  /// The same point kept inside the frame.
  NormalizedPoint clamped() =>
      NormalizedPoint(x.clamp(0.0, 1.0), y.clamp(0.0, 1.0));

  @override
  List<Object?> get props => [x, y];
}
