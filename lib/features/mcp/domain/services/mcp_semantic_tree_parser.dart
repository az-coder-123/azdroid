import 'package:desk_droid/features/mcp/domain/entities/mcp_semantic_element.dart';
import 'package:xml/xml.dart';

/// Service for parsing Android UI accessibility XML into pruned semantic elements.
class McpSemanticTreeParser {
  const McpSemanticTreeParser();

  static final _boundsRegex = RegExp(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]');

  /// Parses raw XML and filters out non-interactive layout containers.
  List<McpSemanticElement> parse(
    String xmlContent, {
    int? screenWidth,
    int? screenHeight,
  }) {
    if (xmlContent.trim().isEmpty) return const [];

    try {
      final doc = XmlDocument.parse(xmlContent);
      final rawNodes = doc.findAllElements('node');
      final elements = <McpSemanticElement>[];
      var nextId = 1;

      for (final node in rawNodes) {
        final boundsStr = node.getAttribute('bounds') ?? '';
        final boundsMatch = _boundsRegex.firstMatch(boundsStr);
        if (boundsMatch == null) continue;

        final left = int.parse(boundsMatch.group(1)!);
        final top = int.parse(boundsMatch.group(2)!);
        final right = int.parse(boundsMatch.group(3)!);
        final bottom = int.parse(boundsMatch.group(4)!);

        final width = right - left;
        final height = bottom - top;
        if (width <= 0 || height <= 0) continue;

        // Skip completely off-screen elements if screen dimensions are known.
        if (screenWidth != null && screenWidth > 0) {
          if (right <= 0 || left >= screenWidth) continue;
        }
        if (screenHeight != null && screenHeight > 0) {
          if (bottom <= 0 || top >= screenHeight) continue;
        }

        final text = (node.getAttribute('text') ?? '').trim();
        final contentDesc = (node.getAttribute('content-desc') ?? '').trim();
        final resourceId = (node.getAttribute('resource-id') ?? '').trim();
        final className = (node.getAttribute('class') ?? '').trim();
        final pkg = (node.getAttribute('package') ?? '').trim();
        final rawClickable = node.getAttribute('clickable') == 'true';
        final scrollable = node.getAttribute('scrollable') == 'true';
        final checkable = node.getAttribute('checkable') == 'true';
        final checked = node.getAttribute('checked') == 'true';
        final enabled = node.getAttribute('enabled') != 'false';

        // Inherited clickability: In declarative frameworks like Jetpack Compose
        // and Flutter, child text elements are often rendered with clickable="false"
        // while their parent container (Tab, Button, Card, Row) holds the click listener.
        final effectiveClickable =
            rawClickable ||
            ((text.isNotEmpty || contentDesc.isNotEmpty) &&
                _hasClickableAncestor(node));

        if (!_isSemanticallyMeaningful(
          className: className,
          text: text,
          contentDesc: contentDesc,
          resourceId: resourceId,
          clickable: effectiveClickable,
          scrollable: scrollable,
          checkable: checkable,
          hasMeaningfulDescendants: _hasMeaningfulDescendants(node),
        )) {
          continue;
        }

        final centerX = (left + right) ~/ 2;
        final centerY = (top + bottom) ~/ 2;
        final normX = (screenWidth != null && screenWidth > 0)
            ? double.parse((centerX / screenWidth).toStringAsFixed(4))
            : 0.0;
        final normY = (screenHeight != null && screenHeight > 0)
            ? double.parse((centerY / screenHeight).toStringAsFixed(4))
            : 0.0;

        elements.add(
          McpSemanticElement(
            id: nextId++,
            text: text,
            resourceId: resourceId,
            className: className,
            package: pkg,
            contentDesc: contentDesc,
            clickable: effectiveClickable,
            scrollable: scrollable,
            checkable: checkable,
            checked: checked,
            enabled: enabled,
            bounds: boundsStr,
            centerX: centerX,
            centerY: centerY,
            normX: normX,
            normY: normY,
          ),
        );
      }

      return elements;
    } catch (_) {
      return const [];
    }
  }

  /// Traverses up the ancestor chain to determine if any containing node is clickable.
  bool _hasClickableAncestor(XmlElement node) {
    var parent = node.parentElement;
    while (parent != null && parent.name.local == 'node') {
      if (parent.getAttribute('clickable') == 'true') {
        return true;
      }
      parent = parent.parentElement;
    }
    return false;
  }

  /// Checks if this node contains any descendant node with non-empty text or content description.
  bool _hasMeaningfulDescendants(XmlElement node) {
    for (final desc in node.findAllElements('node')) {
      final t = (desc.getAttribute('text') ?? '').trim();
      final d = (desc.getAttribute('content-desc') ?? '').trim();
      if (t.isNotEmpty || d.isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  /// Determines whether a UI node carries semantic value for AI agents.
  bool _isSemanticallyMeaningful({
    required String className,
    required String text,
    required String contentDesc,
    required String resourceId,
    required bool clickable,
    required bool scrollable,
    required bool checkable,
    required bool hasMeaningfulDescendants,
  }) {
    // If an element is an anonymous empty container (no text, no content-desc, no resourceId)
    // and its children already contain meaningful text/content, prune this redundant wrapper
    // so agents see the direct informative child nodes.
    if (text.isEmpty && contentDesc.isEmpty && resourceId.isEmpty) {
      if (hasMeaningfulDescendants) {
        return false;
      }
    }

    if (clickable || scrollable || checkable) return true;
    if (text.isNotEmpty || contentDesc.isNotEmpty) return true;

    final shortClass = className.split('.').last.toLowerCase();
    if (shortClass.contains('edittext') ||
        shortClass.contains('button') ||
        shortClass.contains('switch') ||
        shortClass.contains('checkbox') ||
        shortClass.contains('radio') ||
        shortClass.contains('seekbar') ||
        shortClass.contains('composeview')) {
      return true;
    }

    return false;
  }

  /// Formats pruned elements into a compact indexed digest string for LLMs.
  String formatDigest(List<McpSemanticElement> elements) {
    if (elements.isEmpty) {
      return 'No interactive or text elements detected on screen.';
    }

    final buffer = StringBuffer();
    buffer.writeln('=== Screen UI Tree (${elements.length} elements) ===');
    for (final el in elements) {
      buffer.writeln(el.toDigestLine());
    }
    buffer.writeln(
      '\nTip: Use android_click_element(id: N) to tap any element.',
    );
    return buffer.toString().trim();
  }

  /// Searches elements for a query matching text, resourceId, or contentDesc.
  McpSemanticElement? findByQuery(
    List<McpSemanticElement> elements, {
    String? text,
    String? resourceId,
    String? contentDesc,
  }) {
    final t = text?.toLowerCase();
    final r = resourceId?.toLowerCase();
    final d = contentDesc?.toLowerCase();

    for (final el in elements) {
      if (t != null && t.isNotEmpty && el.text.toLowerCase().contains(t)) {
        return el;
      }
      if (r != null &&
          r.isNotEmpty &&
          el.resourceId.toLowerCase().contains(r)) {
        return el;
      }
      if (d != null &&
          d.isNotEmpty &&
          el.contentDesc.toLowerCase().contains(d)) {
        return el;
      }
    }
    return null;
  }
}
