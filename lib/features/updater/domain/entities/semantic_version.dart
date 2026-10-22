/// Immutable value object representing a Semantic Version (MAJOR.MINOR.PATCH+BUILD).
///
/// Follows SemVer 2.0 principles to reliably compare application release versions.
class SemanticVersion implements Comparable<SemanticVersion> {
  const SemanticVersion(this.major, this.minor, this.patch, [this.build = 0]);

  final int major;
  final int minor;
  final int patch;
  final int build;

  /// Attempts to parse [raw] into a [SemanticVersion].
  ///
  /// Tolerates leading 'v' / 'V' and ignores trailing metadata / pre-release suffixes.
  /// Examples:
  /// - `v1.4.1` -> `1.4.1+0`
  /// - `1.4.0+7` -> `1.4.0+7`
  /// - `2.0.0-beta.1` -> `2.0.0+0`
  static SemanticVersion? tryParse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;

    var cleaned = raw.trim();
    if (cleaned.startsWith('v') || cleaned.startsWith('V')) {
      cleaned = cleaned.substring(1).trim();
    }

    int buildNumber = 0;
    if (cleaned.contains('+')) {
      final parts = cleaned.split('+');
      cleaned = parts.first;
      if (parts.length > 1) {
        buildNumber =
            int.tryParse(parts[1].split(RegExp(r'[^0-9]')).first) ?? 0;
      }
    }

    // Strip any pre-release hyphen identifiers for core numerical comparison
    if (cleaned.contains('-')) {
      cleaned = cleaned.split('-').first;
    }

    final segments = cleaned.split('.');
    if (segments.isEmpty) return null;

    final major = int.tryParse(segments[0]);
    if (major == null) return null;

    final minor = segments.length > 1 ? (int.tryParse(segments[1]) ?? 0) : 0;
    final patch = segments.length > 2 ? (int.tryParse(segments[2]) ?? 0) : 0;

    return SemanticVersion(major, minor, patch, buildNumber);
  }

  /// Returns true if this version is strictly newer than [other].
  bool isGreaterThan(SemanticVersion other) => compareTo(other) > 0;

  @override
  int compareTo(SemanticVersion other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    if (patch != other.patch) return patch.compareTo(other.patch);
    return build.compareTo(other.build);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SemanticVersion &&
          runtimeType == other.runtimeType &&
          major == other.major &&
          minor == other.minor &&
          patch == other.patch &&
          build == other.build;

  @override
  int get hashCode => Object.hash(major, minor, patch, build);

  @override
  String toString() {
    final base = 'v$major.$minor.$patch';
    return build > 0 ? '$base+$build' : base;
  }
}
