import 'package:desk_droid/core/services/video_stream_native_service.dart';
import 'package:desk_droid/features/control/domain/entities/frame_size.dart';
import 'package:desk_droid/features/control/domain/repositories/video_frame_size_source.dart';

/// [VideoFrameSizeSource] backed by the native decoder (`getDimensions`),
/// which tracks size changes such as rotation.
class NativeVideoFrameSizeSource implements VideoFrameSizeSource {
  const NativeVideoFrameSizeSource(this._native);

  final IVideoStreamNativeService _native;

  @override
  Future<FrameSize?> current() async {
    final dims = await _native.getDimensions();
    final width = dims['width'] ?? 0;
    final height = dims['height'] ?? 0;
    return width > 0 && height > 0 ? FrameSize(width, height) : null;
  }
}
