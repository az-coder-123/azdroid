import 'dart:math';

import 'package:desk_droid/core/extensions/line_split_extension.dart';
import 'package:equatable/equatable.dart';

/// Frame pacing of one window, read from `dumpsys SurfaceFlinger --latency`.
///
/// The output is the refresh period in nanoseconds, then one line per frame
/// (up to 128): desired present, actual present, and frame-ready times.
/// Frames still queued show an actual present time of `INT64_MAX`. Verified
/// on Android 10 (60 Hz) and Android 13 (90 Hz) on 2026-10-22.
///
/// Unlike `dumpsys gfxinfo`, this also covers SurfaceView, OpenGL, and
/// Vulkan content, so it measures games.
class McpFrameStats extends Equatable {
  const McpFrameStats({
    required this.refreshPeriodNs,
    required this.frameCount,
    required this.renderingMs,
    required this.drawnIntervals,
    required this.slowFrames,
    required this.p95FrameMs,
    required this.maxFrameMs,
  });

  /// A pause longer than this is idle time (nothing to draw), not a slow
  /// frame, and is left out of [fps].
  static const int idleGapNs = 250000000;

  /// Parses the output; `null` when it is not a latency dump.
  static McpFrameStats? parse(String output) {
    final lines = output.trim().splitLines();
    final period = lines.isEmpty ? null : int.tryParse(lines.first.trim());
    if (period == null || period <= 0) return null;
    final presents = <int>[];
    for (final line in lines.skip(1)) {
      final cols = line.trim().split(RegExp(r'\s+'));
      final actual = cols.length >= 2 ? int.tryParse(cols[1]) : null;
      // 0 is an empty slot; INT64_MAX (or an overflowed parse) is pending.
      if (actual != null && actual > 0 && actual < 0x7fffffffffffffff) {
        presents.add(actual);
      }
    }
    presents.sort();
    final intervals = [
      for (var i = 1; i < presents.length; i++) presents[i] - presents[i - 1],
    ];
    final drawing = intervals.where((d) => d <= idleGapNs).toList()..sort();
    return McpFrameStats(
      refreshPeriodNs: period,
      frameCount: presents.length,
      renderingMs: drawing.fold<int>(0, (a, b) => a + b) / 1e6,
      drawnIntervals: drawing.length,
      slowFrames: drawing.where((d) => d > period * 2).length,
      p95FrameMs: drawing.isEmpty
          ? 0
          : drawing[min(drawing.length - 1, (drawing.length * 0.95).floor())] /
                1e6,
      maxFrameMs: drawing.isEmpty ? 0 : drawing.last / 1e6,
    );
  }

  final int refreshPeriodNs;

  /// Frames presented in the sample.
  final int frameCount;

  /// Time spent drawing: the sum of frame intervals, idle gaps excluded.
  final double renderingMs;

  /// Frame intervals counted in [renderingMs].
  final int drawnIntervals;

  /// Frames that missed at least one refresh (interval > 2 periods).
  final int slowFrames;
  final double p95FrameMs;
  final double maxFrameMs;

  double get refreshRateHz => 1e9 / refreshPeriodNs;

  /// Frames per second while the window was drawing (idle gaps excluded).
  double get fps =>
      renderingMs <= 0 ? 0 : drawnIntervals / (renderingMs / 1000);

  @override
  List<Object?> get props => [
    refreshPeriodNs,
    frameCount,
    renderingMs,
    drawnIntervals,
    slowFrames,
    p95FrameMs,
    maxFrameMs,
  ];
}
