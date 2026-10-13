import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wifi_desk/core/theme/app_colors.dart';
import 'package:wifi_desk/features/productivity/presentation/cubit/screenshot_cubit.dart';
import 'package:wifi_desk/features/productivity/presentation/widgets/crop_mask_painter.dart';

/// Interactive draggable overlay displayed over the phone viewport when
/// regional/area screenshot mode is active.
class CropSelectionOverlay extends StatefulWidget {
  const CropSelectionOverlay({super.key, required this.deviceSerial});

  final String deviceSerial;

  @override
  State<CropSelectionOverlay> createState() => _CropSelectionOverlayState();
}

class _CropSelectionOverlayState extends State<CropSelectionOverlay> {
  final FocusNode _focusNode = FocusNode();
  Offset? _startPoint;
  Offset? _currentPoint;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Rect? _computeSelectionRect(Size size) {
    if (_startPoint == null || _currentPoint == null) return null;
    final left = math
        .min(_startPoint!.dx, _currentPoint!.dx)
        .clamp(0.0, size.width);
    final top = math
        .min(_startPoint!.dy, _currentPoint!.dy)
        .clamp(0.0, size.height);
    final right = math
        .max(_startPoint!.dx, _currentPoint!.dx)
        .clamp(0.0, size.width);
    final bottom = math
        .max(_startPoint!.dy, _currentPoint!.dy)
        .clamp(0.0, size.height);
    return Rect.fromLTRB(left, top, right, bottom);
  }

  void _onPanEnd(Size size) {
    final rect = _computeSelectionRect(size);
    if (rect != null &&
        rect.width >= 12 &&
        rect.height >= 12 &&
        size.width > 0 &&
        size.height > 0) {
      final normRect = Rect.fromLTRB(
        (rect.left / size.width).clamp(0.0, 1.0),
        (rect.top / size.height).clamp(0.0, 1.0),
        (rect.right / size.width).clamp(0.0, 1.0),
        (rect.bottom / size.height).clamp(0.0, 1.0),
      );
      context.read<ScreenshotCubit>().captureScreenshot(
        widget.deviceSerial,
        cropRectNormalized: normRect,
      );
    } else {
      context.read<ScreenshotCubit>().cancelAreaSelection();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final selRect = _computeSelectionRect(size);

        return Focus(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.escape) {
              context.read<ScreenshotCubit>().cancelAreaSelection();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.precise,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onSecondaryTap: () =>
                  context.read<ScreenshotCubit>().cancelAreaSelection(),
              onPanStart: (d) => setState(() {
                _startPoint = d.localPosition;
                _currentPoint = d.localPosition;
              }),
              onPanUpdate: (d) => setState(() {
                _currentPoint = d.localPosition;
              }),
              onPanEnd: (_) => _onPanEnd(size),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(
                    size: size,
                    painter: CropMaskPainter(
                      selectionRect: selRect,
                      maskColor: Colors.black.withValues(alpha: 0.55),
                      borderColor: AppColors.accent,
                    ),
                  ),

                  // Top instruction helper pill
                  Positioned(
                    top: 14,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: math.max(0, constraints.maxWidth - 24),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated.withValues(
                            alpha: 0.92,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.crop_rounded,
                              size: 15,
                              color: AppColors.accent,
                            ),
                            const SizedBox(width: 8),
                            const Flexible(
                              child: Text(
                                'Drag to select area • Esc to cancel',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => context
                                  .read<ScreenshotCubit>()
                                  .cancelAreaSelection(),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Dynamic dimension label badge
                  if (selRect != null &&
                      selRect.width > 24 &&
                      selRect.height > 16)
                    Positioned(
                      left: selRect.left + (selRect.width / 2) - 45,
                      top: (selRect.bottom + 8 < size.height - 30)
                          ? selRect.bottom + 8
                          : math.max(8.0, selRect.top - 28),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.7),
                          ),
                        ),
                        child: Text(
                          '${selRect.width.toInt()} × ${selRect.height.toInt()} px',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
