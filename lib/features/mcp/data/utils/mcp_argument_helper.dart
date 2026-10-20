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
    if (containsKey(key) && this[key] != null) {
      final val = this[key];
      return val.toString().trim();
    }
    for (final alias in aliases) {
      if (containsKey(alias) && this[alias] != null) {
        return this[alias].toString().trim();
      }
    }
    return null;
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
    final raw = this[key] ?? _findAliasValue(aliases);
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
    final raw = this[key] ?? _findAliasValue(aliases);
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

  dynamic _findAliasValue(List<String> aliases) {
    for (final a in aliases) {
      if (containsKey(a) && this[a] != null) return this[a];
    }
    return null;
  }
}
