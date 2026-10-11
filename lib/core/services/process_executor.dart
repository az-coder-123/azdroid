import 'dart:io';

/// Abstraction for system process execution to facilitate unit testing and isolation.
abstract class ProcessExecutor {
  /// Executes a system command with arguments and optional timeout.
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    Duration? timeout,
  });
}

/// Default implementation delegating to [Process.run].
class DefaultProcessExecutor implements ProcessExecutor {
  const DefaultProcessExecutor();

  @override
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    Duration? timeout,
  }) async {
    final future = Process.run(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      includeParentEnvironment: includeParentEnvironment,
    );

    if (timeout != null) {
      return future.timeout(
        timeout,
        onTimeout: () => ProcessResult(
          -1,
          -1,
          '',
          'Process timed out after ${timeout.inSeconds} seconds',
        ),
      );
    }

    return future;
  }
}
