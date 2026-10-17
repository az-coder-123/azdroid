import 'package:desk_droid/core/services/app_logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppLogger', () {
    test('info logs messages without throwing', () {
      expect(() => AppLogger.info('Informational event'), returnsNormally);
    });

    test('debug logs messages without throwing', () {
      expect(() => AppLogger.debug('Debug event'), returnsNormally);
    });

    test('warning logs messages with optional error and stack trace', () {
      expect(
        () => AppLogger.warning(
          'Warning event',
          error: Exception('Test error'),
          stackTrace: StackTrace.current,
        ),
        returnsNormally,
      );
    });

    test('error logs messages with required error details', () {
      expect(
        () => AppLogger.error(
          'Critical event',
          error: Exception('Critical failure'),
          stackTrace: StackTrace.current,
        ),
        returnsNormally,
      );
    });
  });
}
