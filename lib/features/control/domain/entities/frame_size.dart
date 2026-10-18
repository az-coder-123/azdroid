import 'package:equatable/equatable.dart';

/// Size of the mirrored video frame, in pixels.
///
/// Equals the server's encoder size in the current orientation. scrcpy
/// control messages must carry it exactly; the server ignores positions
/// generated for any other size.
class FrameSize extends Equatable {
  const FrameSize(this.width, this.height);

  final int width;
  final int height;

  @override
  List<Object?> get props => [width, height];

  @override
  String toString() => '${width}x$height';
}
