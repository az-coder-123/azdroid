/// Defensive argument extraction and parsing utilities for MCP Tool Executors.
class McpArgumentException implements Exception {
  const McpArgumentException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Extension providing defensive, null-safe argument extraction from MCP payload maps.
extension McpArgumentMapExtension on Map<String, dynamic> {
  /// Extracts an optional String value, checking [key] and then fallback [aliases].
  String? getString(String key, {List<String> aliases = const []}) {
    final val = _findRawValue(key, aliases);
    return val?.toString().trim();
  }

  /// Extracts a required String value, throwing [McpArgumentException] if missing or empty.
  String getRequiredString(String key, {List<String> aliases = const []}) {
    final val = getString(key, aliases: aliases);
    if (val == null || val.isEmpty) {
      final allKeys = [key, ...aliases].join(', ');
      throw McpArgumentException(
        "Missing required parameter '$key' (accepted aliases: $allKeys).",
      );
    }
    return val;
  }

  /// Extracts a boolean value supporting booleans, strings ('true', 'yes', '1'), and defaults.
  bool getBool(
    String key, {
    List<String> aliases = const [],
    bool defaultValue = false,
  }) {
    final raw = getString(key, aliases: aliases);
    if (raw == null) return defaultValue;
    final lower = raw.toLowerCase();
    if (lower == 'true' ||
        lower == '1' ||
        lower == 'yes' ||
        lower == 'enable' ||
        lower == 'on') {
      return true;
    }
    if (lower == 'false' ||
        lower == '0' ||
        lower == 'no' ||
        lower == 'disable' ||
        lower == 'off') {
      return false;
    }
    return defaultValue;
  }

  /// Extracts an optional double value, returning null if missing or unparseable.
  double? getOptionalDouble(String key, {List<String> aliases = const []}) {
    final raw = _findRawValue(key, aliases);
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString().trim());
  }

  /// Extracts a double value with a fallback default.
  double getDouble(
    String key, {
    List<String> aliases = const [],
    double defaultValue = 0.0,
  }) => getOptionalDouble(key, aliases: aliases) ?? defaultValue;

  /// Extracts a required double value or throws [McpArgumentException].
  double getRequiredDouble(String key, {List<String> aliases = const []}) {
    final val = getOptionalDouble(key, aliases: aliases);
    if (val == null) {
      throw McpArgumentException(
        "Missing or invalid numeric parameter '$key'.",
      );
    }
    return val;
  }

  /// Extracts an optional integer value, returning null if missing or unparseable.
  int? getOptionalInt(String key, {List<String> aliases = const []}) {
    final raw = _findRawValue(key, aliases);
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw.toString().trim());
  }

  /// Extracts an integer value with a fallback default.
  int getInt(
    String key, {
    List<String> aliases = const [],
    int defaultValue = 0,
  }) => getOptionalInt(key, aliases: aliases) ?? defaultValue;

  /// Extracts a required integer value or throws [McpArgumentException].
  int getRequiredInt(String key, {List<String> aliases = const []}) {
    final val = getOptionalInt(key, aliases: aliases);
    if (val == null) {
      throw McpArgumentException(
        "Missing or invalid integer parameter '$key'.",
      );
    }
    return val;
  }

  /// Extracts a 2D coordinate point, resolving explicit ratios ('xRatio', 'xPercent')
  /// or normalized (0.0..1.0) values against [displayWidth] and [displayHeight].
  (double, double) getPoint({
    required int displayWidth,
    required int displayHeight,
    String xKey = 'x',
    String yKey = 'y',
    List<String> xAliases = const [],
    List<String> yAliases = const [],
  }) {
    final xRatio = getOptionalDouble(
      '${xKey}Ratio',
      aliases: [
        '${xKey}_ratio',
        '${xKey}Percent',
        '${xKey}_percent',
        'ratio${xKey.toUpperCase()}',
      ],
    );
    final yRatio = getOptionalDouble(
      '${yKey}Ratio',
      aliases: [
        '${yKey}_ratio',
        '${yKey}Percent',
        '${yKey}_percent',
        'ratio${yKey.toUpperCase()}',
      ],
    );

    if (xRatio != null && yRatio != null) {
      return (xRatio * displayWidth, yRatio * displayHeight);
    }

    final xPixel = getOptionalDouble(
      '${xKey}Pixel',
      aliases: ['${xKey}_pixel', '${xKey}Px', '${xKey}_px'],
    );
    final yPixel = getOptionalDouble(
      '${yKey}Pixel',
      aliases: ['${yKey}_pixel', '${yKey}Px', '${yKey}_px'],
    );

    if (xPixel != null && yPixel != null) {
      return (xPixel, yPixel);
    }

    final rawX = getRequiredDouble(xKey, aliases: xAliases);
    final rawY = getRequiredDouble(yKey, aliases: yAliases);

    final isNormalized = getBool('normalized', defaultValue: false);
    if (isNormalized || (xRatio != null || yRatio != null)) {
      final actualX = xRatio != null
          ? (xRatio * displayWidth)
          : (rawX <= 1.0 ? rawX * displayWidth : rawX);
      final actualY = yRatio != null
          ? (yRatio * displayHeight)
          : (rawY <= 1.0 ? rawY * displayHeight : rawY);
      return (actualX, actualY);
    }

    if (rawX > 0.0 && rawX < 1.0 && rawY > 0.0 && rawY < 1.0) {
      return (rawX * displayWidth, rawY * displayHeight);
    }

    return (rawX, rawY);
  }

  /// Parses coordinate pair with additive alias support:
  /// 1. Explicit normalized ratios: '${xKey}Ratio', '${xKey}_ratio', '${xKey}Percent'
  /// 2. Explicit physical pixels: '${xKey}Pixel', '${xKey}_pixel', '${xKey}Px'
  /// 3. Standard raw values: [xKey], [xAliases], '${xKey}Coord'
  ///
  /// Throws [McpArgumentException] if either coordinate is missing.
  (double, double) getPointPair({
    String xKey = 'x',
    String yKey = 'y',
    List<String> xAliases = const [],
    List<String> yAliases = const [],
  }) {
    final xVal =
        getOptionalDouble(
          '${xKey}Ratio',
          aliases: ['${xKey}_ratio', '${xKey}Percent', '${xKey}_percent'],
        ) ??
        getOptionalDouble(
          '${xKey}Pixel',
          aliases: ['${xKey}_pixel', '${xKey}Px', '${xKey}_px'],
        ) ??
        getOptionalDouble(xKey, aliases: [...xAliases, '${xKey}Coord']);

    final yVal =
        getOptionalDouble(
          '${yKey}Ratio',
          aliases: ['${yKey}_ratio', '${yKey}Percent', '${yKey}_percent'],
        ) ??
        getOptionalDouble(
          '${yKey}Pixel',
          aliases: ['${yKey}_pixel', '${yKey}Px', '${yKey}_px'],
        ) ??
        getOptionalDouble(yKey, aliases: [...yAliases, '${yKey}Coord']);

    if (xVal != null && yVal != null) {
      return (xVal, yVal);
    }

    if (xVal == null) {
      final allX = [
        '${xKey}Ratio',
        '${xKey}Pixel',
        xKey,
        ...xAliases,
      ].join(', ');
      throw McpArgumentException(
        "Missing or invalid coordinate parameter for '$xKey' (accepted: $allX).",
      );
    }

    final allY = ['${yKey}Ratio', '${yKey}Pixel', yKey, ...yAliases].join(', ');
    throw McpArgumentException(
      "Missing or invalid coordinate parameter for '$yKey' (accepted: $allY).",
    );
  }

  /// Parses an optional coordinate pair, returning (null, null) if neither coordinate is supplied.
  (double?, double?) getOptionalPointPair({
    String xKey = 'x',
    String yKey = 'y',
    List<String> xAliases = const [],
    List<String> yAliases = const [],
  }) {
    final xVal =
        getOptionalDouble(
          '${xKey}Ratio',
          aliases: ['${xKey}_ratio', '${xKey}Percent', '${xKey}_percent'],
        ) ??
        getOptionalDouble(
          '${xKey}Pixel',
          aliases: ['${xKey}_pixel', '${xKey}Px', '${xKey}_px'],
        ) ??
        getOptionalDouble(xKey, aliases: [...xAliases, '${xKey}Coord']);

    final yVal =
        getOptionalDouble(
          '${yKey}Ratio',
          aliases: ['${yKey}_ratio', '${yKey}Percent', '${yKey}_percent'],
        ) ??
        getOptionalDouble(
          '${yKey}Pixel',
          aliases: ['${yKey}_pixel', '${yKey}Px', '${yKey}_px'],
        ) ??
        getOptionalDouble(yKey, aliases: [...yAliases, '${yKey}Coord']);

    return (xVal, yVal);
  }

  dynamic _findRawValue(String key, List<String> aliases) {
    if (containsKey(key) && this[key] != null) return this[key];
    for (final alias in aliases) {
      if (containsKey(alias) && this[alias] != null) return this[alias];
    }

    final candidates = <String>{};
    for (final k in [key, ...aliases]) {
      final snake = k.replaceAllMapped(
        RegExp(r'[A-Z]'),
        (m) => '_${m[0]!.toLowerCase()}',
      );
      candidates.add(snake);
      candidates.add(snake.replaceAll('_', '-'));
      if (k.contains('_') || k.contains('-')) {
        candidates.add(_toCamelCase(k));
      }
    }

    for (final c in candidates) {
      if (containsKey(c) && this[c] != null) return this[c];
    }

    final cleanTarget = _stripKey(key);
    for (final entry in entries) {
      if (_stripKey(entry.key) == cleanTarget && entry.value != null) {
        return entry.value;
      }
    }

    for (final alias in aliases) {
      final cleanAlias = _stripKey(alias);
      for (final entry in entries) {
        if (_stripKey(entry.key) == cleanAlias && entry.value != null) {
          return entry.value;
        }
      }
    }

    return null;
  }

  static String _toCamelCase(String s) {
    final parts = s.split(RegExp(r'[_-]'));
    if (parts.isEmpty) return s;
    final first = parts.first.toLowerCase();
    final rest = parts
        .skip(1)
        .map(
          (p) => p.isEmpty
              ? ''
              : '${p[0].toUpperCase()}${p.substring(1).toLowerCase()}',
        );
    return '$first${rest.join()}';
  }

  static String _stripKey(String s) =>
      s.replaceAll('_', '').replaceAll('-', '').toLowerCase();
}
