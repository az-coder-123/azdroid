import 'package:desk_droid/features/streaming/presentation/widgets/phone_display_placement.dart';
import 'package:flutter/material.dart';

/// Lays out the phone [display] and the vertical [sideToolbar] in one row.
///
/// The toolbar keeps its natural width and the display gets the rest, so the
/// row cannot overflow whatever the toolbar's real width is (it differs with
/// platform visual density). The display box always has the stream's
/// [aspectRatio], which input mapping relies on.
class MirroringCentralViewport extends StatelessWidget {
  const MirroringCentralViewport({
    super.key,
    required this.aspectRatio,
    required this.display,
    required this.sideToolbar,
    this.leftToolbar,
  });

  /// Gap between the phone display and the side toolbar.
  static const double toolbarGap = 16.0;

  /// Stream width / height after rotation.
  final double aspectRatio;
  final Widget display;
  final Widget sideToolbar;
  final Widget? leftToolbar;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, window) => Row(
        children: [
          if (leftToolbar != null) ...[
            leftToolbar!,
            const SizedBox(width: toolbarGap),
          ],
          Expanded(
            child: LayoutBuilder(
              builder: (context, area) {
                final leftOffset = leftToolbar != null
                    ? (window.maxWidth - area.maxWidth) / 2
                    : 0.0;
                final rect = placePhoneDisplay(
                  area: area.biggest,
                  windowWidth: window.maxWidth,
                  aspectRatio: aspectRatio,
                  leftOffset: leftOffset,
                );
                return Stack(
                  children: [Positioned.fromRect(rect: rect, child: display)],
                );
              },
            ),
          ),
          const SizedBox(width: toolbarGap),
          sideToolbar,
        ],
      ),
    );
  }
}
