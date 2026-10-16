import 'package:equatable/equatable.dart';

/// Represents a pruned, interactive accessibility node on the Android screen.
class McpSemanticElement extends Equatable {
  const McpSemanticElement({
    required this.id,
    required this.text,
    required this.resourceId,
    required this.className,
    required this.package,
    required this.contentDesc,
    required this.clickable,
    required this.scrollable,
    required this.checkable,
    required this.checked,
    required this.enabled,
    required this.bounds,
    required this.centerX,
    required this.centerY,
    required this.normX,
    required this.normY,
  });

  final int id;
  final String text;
  final String resourceId;
  final String className;
  final String package;
  final String contentDesc;
  final bool clickable;
  final bool scrollable;
  final bool checkable;
  final bool checked;
  final bool enabled;
  final String bounds;
  final int centerX;
  final int centerY;
  final double normX;
  final double normY;

  /// Short class name (e.g. "Button" from "android.widget.Button").
  String get shortClass => className.split('.').last;

  /// Compact one-line representation for token-efficient LLM prompting.
  String toDigestLine() {
    final parts = <String>[];
    if (text.isNotEmpty) parts.add('text:"$text"');
    if (contentDesc.isNotEmpty) parts.add('desc:"$contentDesc"');
    if (resourceId.isNotEmpty) {
      final shortId = resourceId.contains(':id/')
          ? resourceId.split(':id/').last
          : resourceId;
      parts.add('id:"$shortId"');
    }
    if (clickable) parts.add('clickable:true');
    if (scrollable) parts.add('scrollable:true');
    if (checkable) parts.add('checked:$checked');
    parts.add('center:($centerX,$centerY)');

    return '[#$id] $shortClass ${parts.join(' ')}';
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'text': text,
    'resourceId': resourceId,
    'class': className,
    'package': package,
    'contentDesc': contentDesc,
    'clickable': clickable,
    'scrollable': scrollable,
    'bounds': bounds,
    'centerPixels': {'x': centerX, 'y': centerY},
    'normalized': {'x': normX, 'y': normY},
  };

  @override
  List<Object?> get props => [
    id,
    text,
    resourceId,
    className,
    bounds,
    centerX,
    centerY,
  ];
}
