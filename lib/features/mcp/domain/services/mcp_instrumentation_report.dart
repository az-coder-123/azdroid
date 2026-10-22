import 'package:desk_droid/core/extensions/line_split_extension.dart';

/// One test reported by `am instrument -r`.
typedef McpTestOutcome = ({String name, String status, String? detail});

/// Reads the raw output of `am instrument -w -r` (Espresso, UI Automator,
/// and Flutter integration tests all report through it).
///
/// Each test emits `INSTRUMENTATION_STATUS: key=value` lines followed by
/// `INSTRUMENTATION_STATUS_CODE`: 1 started, 0 passed, -1 error, -2 failed,
/// -3 ignored, -4 assumption failed. A run that cannot start reports
/// `INSTRUMENTATION_FAILED` or `INSTRUMENTATION_RESULT: shortMsg=…`.
class McpInstrumentationReport {
  McpInstrumentationReport.parse(String output) {
    final values = <String, String>{};
    String? lastKey;
    for (final line in output.splitLines()) {
      final status = _status.firstMatch(line);
      if (status != null) {
        lastKey = status[1];
        values[lastKey!] = status[2]!;
        continue;
      }
      final code = _statusCode.firstMatch(line);
      if (code != null) {
        _record(int.parse(code[1]!), values);
        values.clear();
        lastKey = null;
        continue;
      }
      final result = _result.firstMatch(line);
      if (result != null) {
        if (result[1] == 'shortMsg' || result[1] == 'longMsg') {
          runError ??= result[2];
        }
        continue;
      }
      final failed = _failed.firstMatch(line);
      if (failed != null) {
        runError ??= 'Instrumentation failed: ${failed[1]}';
        continue;
      }
      // Stack traces span several lines after `stack=`.
      if (lastKey != null && !line.startsWith('INSTRUMENTATION_')) {
        values[lastKey] = '${values[lastKey]}\n$line';
      }
    }
  }

  static final RegExp _status = RegExp(r'^INSTRUMENTATION_STATUS: (\w+)=(.*)');
  static final RegExp _statusCode = RegExp(
    r'^INSTRUMENTATION_STATUS_CODE: (-?\d+)',
  );
  static final RegExp _result = RegExp(r'^INSTRUMENTATION_RESULT: (\w+)=(.*)');
  static final RegExp _failed = RegExp(r'^INSTRUMENTATION_FAILED: (.*)');

  static const Map<int, String> _statuses = {
    0: 'passed',
    -1: 'error',
    -2: 'failed',
    -3: 'ignored',
    -4: 'assumption failed',
  };

  final List<McpTestOutcome> tests = [];

  /// Why the run itself failed (crash, missing runner), if it did.
  String? runError;

  int count(String status) => tests.where((t) => t.status == status).length;

  bool get succeeded =>
      runError == null &&
      tests.isNotEmpty &&
      tests.every((t) => t.status != 'failed' && t.status != 'error');

  void _record(int code, Map<String, String> values) {
    final status = _statuses[code];
    if (status == null) return; // 1 = started; 2 = in-progress output.
    final cls = values['class'] ?? '?';
    final stack = values['stack']?.trim();
    tests.add((
      name: '$cls#${values['test'] ?? '?'}',
      status: status,
      detail: stack == null || stack.isEmpty
          ? null
          : stack.splitLines().take(8).join('\n'),
    ));
  }

  /// A summary listing every failure with the top of its stack trace.
  String summarize() {
    final lines = [
      if (runError != null) 'Run failed: $runError',
      'Tests: ${tests.length} — passed ${count('passed')}, failed '
          '${count('failed')}, errors ${count('error')}, ignored '
          '${count('ignored') + count('assumption failed')}',
      for (final t in tests.where(
        (t) => t.status == 'failed' || t.status == 'error',
      ))
        '✗ ${t.name} (${t.status})${t.detail == null ? '' : '\n${t.detail}'}',
    ];
    return lines.join('\n');
  }
}
