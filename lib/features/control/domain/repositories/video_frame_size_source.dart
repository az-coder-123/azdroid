import 'package:desk_droid/features/control/domain/entities/frame_size.dart';

/// Provides the size of the frame currently being mirrored.
abstract class VideoFrameSizeSource {
  /// The current frame size, or `null` when no video is decoded yet.
  Future<FrameSize?> current();
}
