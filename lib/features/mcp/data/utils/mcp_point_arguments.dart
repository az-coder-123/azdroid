import 'package:desk_droid/features/mcp/data/utils/mcp_argument_helper.dart';
import 'package:desk_droid/features/mcp/data/utils/mcp_point.dart';

/// Reads screen points from MCP tool arguments, keeping the unit the client
/// chose (see [McpPoint] for the resolution rules).
extension McpPointArguments on Map<String, dynamic> {
  /// The point under [xKey]/[yKey], each axis taken from (first match wins):
  /// 1. `<key>Ratio`, `<key>_ratio`, `<key>Percent`, `<key>_percent`
  /// 2. `<key>Pixel`, `<key>_pixel`, `<key>Px`, `<key>_px`
  /// 3. `<key>`, the [xAliases]/[yAliases], `<key>Coord` (unit inferred)
  ///
  /// Throws [McpArgumentException] when either axis is missing.
  McpPoint getPoint({
    String xKey = 'x',
    String yKey = 'y',
    List<String> xAliases = const [],
    List<String> yAliases = const [],
  }) {
    final x = _axis(xKey, xAliases);
    final y = _axis(yKey, yAliases);
    if (x != null && y != null) return McpPoint(x, y);
    final missing = x == null ? xKey : yKey;
    final aliases = x == null ? xAliases : yAliases;
    final accepted = [
      '${missing}Ratio',
      '${missing}Pixel',
      missing,
      ...aliases,
    ].join(', ');
    throw McpArgumentException(
      "Missing or invalid coordinate parameter for '$missing' "
      '(accepted: $accepted).',
    );
  }

  /// Like [getPoint], but `null` when either axis is missing.
  McpPoint? getOptionalPoint({
    String xKey = 'x',
    String yKey = 'y',
    List<String> xAliases = const [],
    List<String> yAliases = const [],
  }) {
    final x = _axis(xKey, xAliases);
    final y = _axis(yKey, yAliases);
    return x != null && y != null ? McpPoint(x, y) : null;
  }

  McpAxis? _axis(String key, List<String> aliases) {
    final ratio = getOptionalDouble(
      '${key}Ratio',
      aliases: ['${key}_ratio', '${key}Percent', '${key}_percent'],
    );
    if (ratio != null) return McpAxis(ratio, McpUnit.ratio);
    final pixel = getOptionalDouble(
      '${key}Pixel',
      aliases: ['${key}_pixel', '${key}Px', '${key}_px'],
    );
    if (pixel != null) return McpAxis(pixel, McpUnit.pixel);
    final raw = getOptionalDouble(key, aliases: [...aliases, '${key}Coord']);
    return raw == null ? null : McpAxis(raw, McpUnit.auto);
  }
}
