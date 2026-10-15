import 'package:desk_droid/core/services/adb_service.dart';
import 'package:desk_droid/core/services/app_logger.dart';
import 'package:desk_droid/core/services/process_executor.dart';
import 'package:desk_droid/features/intent_dispatcher/domain/entities/intent_request_entity.dart';
import 'package:desk_droid/features/intent_dispatcher/domain/entities/intent_result_entity.dart';

/// Abstract datasource contract executing `am start` commands via ADB.
abstract class IntentDatasource {
  Future<IntentResultEntity> dispatchIntent(
    String deviceSerial,
    IntentRequestEntity request,
  );
}

/// Concrete implementation of [IntentDatasource] using `adb shell am start`.
class IntentDatasourceImpl implements IntentDatasource {
  IntentDatasourceImpl({
    AdbService? adbService,
    ProcessExecutor? processExecutor,
  }) : _adbService = adbService ?? AdbService(),
       _executor = processExecutor ?? const DefaultProcessExecutor();

  final AdbService _adbService;
  final ProcessExecutor _executor;

  @override
  Future<IntentResultEntity> dispatchIntent(
    String deviceSerial,
    IntentRequestEntity request,
  ) async {
    final adb = await _adbService.resolveAdbPath();
    if (adb == null) {
      return const IntentResultEntity(
        success: false,
        message: 'ADB binary not found on macOS system.',
      );
    }

    final args = <String>['-s', deviceSerial, 'shell', 'am', 'start'];

    if (request.action.trim().isNotEmpty) {
      args.addAll(['-a', request.action.trim()]);
    }

    if (request.dataUri != null && request.dataUri!.trim().isNotEmpty) {
      args.addAll(['-d', request.dataUri!.trim()]);
    }

    if (request.packageName != null && request.packageName!.trim().isNotEmpty) {
      args.addAll(['-p', request.packageName!.trim()]);
    }

    if (request.componentName != null &&
        request.componentName!.trim().isNotEmpty) {
      args.addAll(['-n', request.componentName!.trim()]);
    }

    if (request.category != null && request.category!.trim().isNotEmpty) {
      args.addAll(['-c', request.category!.trim()]);
    }

    // Attach typed intent extras
    for (final entry in request.extras.entries) {
      final key = entry.key.trim();
      final val = entry.value;
      if (key.isEmpty) continue;

      if (val is bool) {
        args.addAll(['--ez', key, val.toString()]);
      } else if (val is int) {
        args.addAll(['--ei', key, val.toString()]);
      } else if (val is double) {
        args.addAll(['--ef', key, val.toString()]);
      } else {
        args.addAll(['--es', key, val.toString()]);
      }
    }

    try {
      final result = await _executor.run(
        adb,
        args,
        timeout: const Duration(seconds: 5),
      );

      final stdout = result.stdout.toString().trim();
      final stderr = result.stderr.toString().trim();
      final combined = '$stdout\n$stderr'.trim();

      // Check for common Android am start errors
      final isError =
          result.exitCode != 0 ||
          stdout.contains('Error:') ||
          stderr.contains('Error:') ||
          combined.contains('Exception') ||
          combined.contains('Activity not found') ||
          combined.contains('SecurityException');

      if (isError) {
        final errorLine = stdout
            .split('\n')
            .firstWhere(
              (line) => line.contains('Error:') || line.contains('Exception'),
              orElse: () =>
                  stderr.isNotEmpty ? stderr : 'Intent dispatch failed.',
            );
        return IntentResultEntity(
          success: false,
          message: errorLine.trim(),
          rawOutput: combined,
        );
      }

      return IntentResultEntity(
        success: true,
        message: 'Intent successfully dispatched.',
        rawOutput: stdout,
      );
    } catch (e, stack) {
      AppLogger.warning(
        'Failed to dispatch intent to $deviceSerial',
        error: e,
        stackTrace: stack,
      );
      return IntentResultEntity(
        success: false,
        message: 'Exception executing intent: $e',
      );
    }
  }
}
