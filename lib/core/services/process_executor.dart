import 'dart:io';

import 'package:desk_droid/core/services/process_output_encoding.dart';

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

  /// Starts a system process and returns the running [Process] handle.
  Future<Process> start(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    ProcessStartMode mode = ProcessStartMode.normal,
  });
}

/// Default implementation delegating to [Process.run] and [Process.start].
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
    final encoding = processOutputEncodingFor(executable);
    final future = Process.run(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      includeParentEnvironment: includeParentEnvironment,
      stdoutEncoding: encoding,
      stderrEncoding: encoding,
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

  @override
  Future<Process> start(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    ProcessStartMode mode = ProcessStartMode.normal,
  }) {
    return Process.start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      includeParentEnvironment: includeParentEnvironment,
      mode: mode,
    );
  }
}
