import 'dart:math' as math;

import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/features/productivity/domain/entities/screenshot_destination.dart';
import 'package:desk_droid/features/productivity/presentation/cubit/screenshot_cubit.dart';
import 'package:desk_droid/features/productivity/presentation/utils/crop_handle_helper.dart';
import 'package:desk_droid/features/productivity/presentation/widgets/crop_dimension_badge.dart';
import 'package:desk_droid/features/productivity/presentation/widgets/crop_floating_toolbar.dart';
import 'package:desk_droid/features/productivity/presentation/widgets/crop_instruction_pill.dart';
import 'package:desk_droid/features/productivity/presentation/widgets/crop_mask_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Interactive draggable overlay displayed over the phone viewport when
/// regional screenshot mode is active, supporting 8-point resize and translation.
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
  Offset? _lastPanPosition;
  Rect? _finalRect;
  bool _hasSelection = false;
  CropHandle _activeHandle = CropHandle.none;
  CropHandle _hoveredHandle = CropHandle.none;

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

  void _onPanStart(DragStartDetails d) {
    if (_hasSelection && _finalRect != null) {
      final handle = CropHandleHelper.hitTest(d.localPosition, _finalRect!);
      if (handle != CropHandle.none) {
        setState(() {
          _activeHandle = handle;
          _lastPanPosition = d.localPosition;
        });
        return;
      }
    }
    setState(() {
      _hasSelection = false;
      _finalRect = null;
      _activeHandle = CropHandle.none;
      _startPoint = d.localPosition;
      _currentPoint = d.localPosition;
    });
  }

  void _onPanUpdate(DragUpdateDetails d, Size size) {
    if (_hasSelection &&
        _finalRect != null &&
        _activeHandle != CropHandle.none) {
      final delta = d.localPosition - (_lastPanPosition ?? d.localPosition);
      _lastPanPosition = d.localPosition;
      setState(() {
        _finalRect = CropHandleHelper.transformRect(
          currentRect: _finalRect!,
          handle: _activeHandle,
          delta: delta,
          bounds: size,
        );
      });
      return;
    }
    if (!_hasSelection) {
      setState(() => _currentPoint = d.localPosition);
    }
  }

  void _onPanEnd(Size size) {
    if (_hasSelection) {
      setState(() {
        _activeHandle = CropHandle.none;
        _lastPanPosition = null;
      });
      return;
    }
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

  MouseCursor _resolveCursor() {
    if (_activeHandle != CropHandle.none) {
      return CropHandleHelper.getCursor(_activeHandle);
    }
    if (_hasSelection) {
      return CropHandleHelper.getCursor(_hoveredHandle);
    }
    return SystemMouseCursors.precise;
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
            cursor: _resolveCursor(),
            onHover: (event) {
              if (_hasSelection && _finalRect != null) {
                final handle = CropHandleHelper.hitTest(
                  event.localPosition,
                  _finalRect!,
                );
                if (_hoveredHandle != handle) {
                  setState(() => _hoveredHandle = handle);
                }
              }
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onSecondaryTap: () =>
                  context.read<ScreenshotCubit>().cancelAreaSelection(),
              onPanStart: _onPanStart,
              onPanUpdate: (d) => _onPanUpdate(d, size),
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
                      showHandles: _hasSelection,
                    ),
                  ),
                  CropInstructionPill(
                    hasSelection: _hasSelection,
                    maxWidth: size.width,
                    onCancel: () =>
                        context.read<ScreenshotCubit>().cancelAreaSelection(),
                  ),
                  if (selRect != null && selRect.width > 24)
                    CropDimensionBadge(
                      selectionRect: selRect,
                      viewportHeight: size.height,
                    ),
                  if (_hasSelection &&
                      selRect != null &&
                      _activeHandle == CropHandle.none)
                    CropFloatingToolbar(
                      selectionRect: selRect,
                      viewportSize: size,
                      onSelectDestination: (dest) =>
                          _onSelectDestination(dest, size),
                      onCancel: () =>
                          context.read<ScreenshotCubit>().cancelAreaSelection(),
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
