import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wifi_desk/core/theme/app_colors.dart';
import 'package:wifi_desk/features/productivity/domain/entities/screenshot_destination.dart';
import 'package:wifi_desk/features/productivity/presentation/cubit/screenshot_cubit.dart';
import 'package:wifi_desk/features/productivity/presentation/widgets/crop_action_toolbar.dart';
import 'package:wifi_desk/features/productivity/presentation/widgets/crop_mask_painter.dart';

/// Interactive draggable overlay displayed over the phone viewport when
/// regional/area screenshot mode is active, with floating destination options.
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
  Rect? _finalRect;
  bool _hasSelection = false;

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

  Rect? _computeActiveRect(Size size) {
    if (_hasSelection && _finalRect != null) return _finalRect;
    if (_startPoint == null || _currentPoint == null) return null;
    return Rect.fromLTRB(
      math.min(_startPoint!.dx, _currentPoint!.dx).clamp(0.0, size.width),
      math.min(_startPoint!.dy, _currentPoint!.dy).clamp(0.0, size.height),
      math.max(_startPoint!.dx, _currentPoint!.dx).clamp(0.0, size.width),
      math.max(_startPoint!.dy, _currentPoint!.dy).clamp(0.0, size.height),
    );
  }

  void _onPanEnd(Size size) {
    final rect = _computeActiveRect(size);
    if (rect != null &&
        rect.width >= 16 &&
        rect.height >= 16 &&
        size.width > 0) {
      setState(() {
        _finalRect = rect;
        _hasSelection = true;
      });
    } else {
      context.read<ScreenshotCubit>().cancelAreaSelection();
    }
  }

  void _onSelectDestination(ScreenshotDestination destination, Size size) {
    final rect = _finalRect ?? _computeActiveRect(size);
    if (rect == null || size.width == 0 || size.height == 0) return;

    final normRect = Rect.fromLTRB(
      (rect.left / size.width).clamp(0.0, 1.0),
      (rect.top / size.height).clamp(0.0, 1.0),
      (rect.right / size.width).clamp(0.0, 1.0),
      (rect.bottom / size.height).clamp(0.0, 1.0),
    );

    context.read<ScreenshotCubit>().captureScreenshot(
      widget.deviceSerial,
      cropRectNormalized: normRect,
      destination: destination,
    );
  }

  KeyEventResult _handleKeyEvent(KeyEvent event, Size size) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      context.read<ScreenshotCubit>().cancelAreaSelection();
      return KeyEventResult.handled;
    }
    if (_hasSelection) {
      if (event.logicalKey == LogicalKeyboardKey.keyC) {
        _onSelectDestination(ScreenshotDestination.clipboard, size);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyS) {
        _onSelectDestination(ScreenshotDestination.file, size);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        _onSelectDestination(ScreenshotDestination.both, size);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final selRect = _computeActiveRect(size);

        return Focus(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: (node, event) => _handleKeyEvent(event, size),
          child: MouseRegion(
            cursor: _hasSelection
                ? SystemMouseCursors.basic
                : SystemMouseCursors.precise,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onSecondaryTap: () =>
                  context.read<ScreenshotCubit>().cancelAreaSelection(),
              onPanStart: (d) => setState(() {
                _hasSelection = false;
                _finalRect = null;
                _startPoint = d.localPosition;
                _currentPoint = d.localPosition;
              }),
              onPanUpdate: (d) {
                if (!_hasSelection) {
                  setState(() => _currentPoint = d.localPosition);
                }
              },
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
                  _buildInstructionPill(size),
                  if (!_hasSelection && selRect != null && selRect.width > 24)
                    _buildDimensionBadge(selRect, size),
                  if (_hasSelection && selRect != null)
                    _buildFloatingToolbar(selRect, size),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInstructionPill(Size size) {
    return Positioned(
      top: 14,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: math.max(0.0, size.width - 24)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.crop_rounded, size: 15, color: AppColors.accent),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _hasSelection
                      ? 'Choose destination below • Esc to cancel'
                      : 'Drag to select area • Esc to cancel',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () =>
                    context.read<ScreenshotCubit>().cancelAreaSelection(),
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
    );
  }

  Widget _buildDimensionBadge(Rect selRect, Size size) {
    final topPos = (selRect.bottom + 8 < size.height - 30)
        ? selRect.bottom + 8.0
        : (math.max(8.0, selRect.top - 28.0)).toDouble();

    return Positioned(
      left: selRect.left + (selRect.width / 2) - 45,
      top: topPos,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.7)),
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
    );
  }

  Widget _buildFloatingToolbar(Rect selRect, Size size) {
    const toolbarWidth = 275.0;
    const toolbarHeight = 40.0;
    final maxLeft = math.max(12.0, size.width - toolbarWidth - 12.0).toDouble();
    final left = (selRect.left + (selRect.width / 2) - (toolbarWidth / 2))
        .clamp(12.0, maxLeft);
    final fitsBelow = selRect.bottom + 10 + toolbarHeight < size.height;
    final top = fitsBelow
        ? selRect.bottom + 10.0
        : (math.max(10.0, selRect.top - 10.0 - toolbarHeight)).toDouble();

    return Positioned(
      left: left,
      top: top,
      child: CropActionToolbar(
        onSelect: (dest) => _onSelectDestination(dest, size),
        onCancel: () => context.read<ScreenshotCubit>().cancelAreaSelection(),
      ),
    );
  }
}
