import 'package:desk_droid/features/updater/domain/entities/semantic_version.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SemanticVersion', () {
    test('parses basic dotted versions with optional v prefix', () {
      final v1 = SemanticVersion.tryParse('1.4.0');
      expect(v1, isNotNull);
      expect(v1!.major, 1);
      expect(v1.minor, 4);
      expect(v1.patch, 0);
      expect(v1.build, 0);

      final v2 = SemanticVersion.tryParse('v1.4.1');
      expect(v2, isNotNull);
      expect(v2!.major, 1);
      expect(v2.minor, 4);
      expect(v2.patch, 1);
      expect(v2.build, 0);
    });

    test('parses versions with build numbers after plus', () {
      final v = SemanticVersion.tryParse('1.4.0+7');
      expect(v, isNotNull);
      expect(v!.major, 1);
      expect(v.minor, 4);
      expect(v.patch, 0);
      expect(v.build, 7);
    });

    test('parses pre-release strings safely without crash', () {
      final v = SemanticVersion.tryParse('v2.0.0-rc.1+12');
      expect(v, isNotNull);
      expect(v!.major, 2);
      expect(v.minor, 0);
      expect(v.patch, 0);
    });

    test('returns null on invalid or empty inputs', () {
      expect(SemanticVersion.tryParse(null), isNull);
      expect(SemanticVersion.tryParse(''), isNull);
      expect(SemanticVersion.tryParse('   '), isNull);
      expect(SemanticVersion.tryParse('not-a-version'), isNull);
    });

    test('compares numerical version precedence correctly', () {
      final v1_4_0 = SemanticVersion.tryParse('1.4.0')!;
      final v1_4_1 = SemanticVersion.tryParse('1.4.1')!;
      final v1_10_0 = SemanticVersion.tryParse('1.10.0')!;
      final v2_0_0 = SemanticVersion.tryParse('2.0.0')!;

      // 1.4.1 is newer than 1.4.0
      expect(v1_4_1.isGreaterThan(v1_4_0), isTrue);
      expect(v1_4_0.isGreaterThan(v1_4_1), isFalse);

      // Numerical 1.10.0 must be greater than 1.4.0 (avoid lexicographical bugs)
      expect(v1_10_0.isGreaterThan(v1_4_1), isTrue);
      expect(v1_10_0.isGreaterThan(v1_4_0), isTrue);

      // Major bump takes precedence
      expect(v2_0_0.isGreaterThan(v1_10_0), isTrue);
    });

    test('evaluates equality and string formatting', () {
      const a = SemanticVersion(1, 4, 0, 7);
      final b = SemanticVersion.tryParse('1.4.0+7');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a.toString(), equals('v1.4.0+7'));

      const c = SemanticVersion(1, 4, 1);
      expect(c.toString(), equals('v1.4.1'));
    });
  });
}
