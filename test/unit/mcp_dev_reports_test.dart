import 'dart:io';

import 'package:desk_droid/features/mcp/data/services/mcp_app_start_ops.dart';
import 'package:desk_droid/features/mcp/data/services/mcp_instrumentation_ops.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_frame_stats.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_instrumentation_report.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_thermal_report.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('frame stats', () {
    test('a real Android 13 scroll at 90 Hz reads about 90 fps', () {
      // Settings scrolled on a Moto g play (2026-10-22); the last frames
      // are still pending (INT64_MAX).
      final stats = McpFrameStats.parse(
        File('test/fixtures/mcp/surfaceflinger_latency_android13.txt')
            .readAsStringSync(),
      )!;
      expect(stats.refreshRateHz, closeTo(90, 0.1));
      expect(stats.frameCount, 125);
      expect(stats.fps, closeTo(90.45, 0.1));
    });

    test('idle gaps are not slow frames and do not lower fps', () {
      const ms = 1000000;
      final presents = [0, 16, 33, 50, 1050, 1066, 1083, 1150];
      final out = [
        '16666666',
        for (final t in presents) '1\t${t * ms + 1}\t1',
        '0\t9223372036854775807\t0',
        '0\t0\t0',
      ].join('\n');
      final stats = McpFrameStats.parse(out)!;
      expect(stats.frameCount, presents.length);
      expect(stats.drawnIntervals, 6); // the 1000 ms pause is idle
      expect(stats.slowFrames, 1); // 67 ms > 2 refresh periods
      expect(stats.maxFrameMs, 67);
    });

    test('a non-latency output is rejected', () {
      expect(McpFrameStats.parse('Unknown layer'), isNull);
    });
  });

  test('thermal: Android 10 output with status and sensors', () {
    const out = '''
IsStatusOverride: false
Thermal Status: 2
Cached temperatures:
	Temperature{mValue=38.0, mType=3, mName=SKIN_T, mStatus=0}
	Temperature{mValue=48.3, mType=0, mName=CPU_T, mStatus=2}
HAL Ready: true
Current temperatures from HAL:
	Temperature{mValue=49.0, mType=0, mName=CPU_T, mStatus=2}
''';
    final report = McpThermalReport.summarize(out)!;
    expect(report, startsWith('Thermal status: 2 (moderate): the system'));
    expect(report, contains('• CPU_T: 48.3 °C'));
    expect(McpThermalReport.summarize('no service'), isNull);
  });

  group('instrumentation', () {
    const run = '''
INSTRUMENTATION_STATUS: class=com.example.LoginTest
INSTRUMENTATION_STATUS: current=1
INSTRUMENTATION_STATUS: test=signsIn
INSTRUMENTATION_STATUS_CODE: 1
INSTRUMENTATION_STATUS: class=com.example.LoginTest
INSTRUMENTATION_STATUS: test=signsIn
INSTRUMENTATION_STATUS_CODE: 0
INSTRUMENTATION_STATUS: class=com.example.LoginTest
INSTRUMENTATION_STATUS: test=rejectsBadPassword
INSTRUMENTATION_STATUS_CODE: 1
INSTRUMENTATION_STATUS: class=com.example.LoginTest
INSTRUMENTATION_STATUS: stack=java.lang.AssertionError: expected error banner
	at com.example.LoginTest.rejectsBadPassword(LoginTest.kt:42)
INSTRUMENTATION_STATUS: stream=
Error in rejectsBadPassword(com.example.LoginTest):
INSTRUMENTATION_STATUS: test=rejectsBadPassword
INSTRUMENTATION_STATUS_CODE: -2
INSTRUMENTATION_RESULT: stream=

Time: 3.2
FAILURES!!!
INSTRUMENTATION_CODE: -1
''';

    test('counts results and keeps the failing stack', () {
      final report = McpInstrumentationReport.parse(run);
      expect(report.tests, hasLength(2));
      expect(report.count('passed'), 1);
      expect(report.count('failed'), 1);
      expect(report.succeeded, isFalse);
      final summary = report.summarize();
      expect(summary, contains('passed 1, failed 1'));
      expect(summary, contains('✗ com.example.LoginTest#rejectsBadPassword'));
      expect(summary, contains('LoginTest.kt:42'));
    });

    test('a crashed run reports why', () {
      final report = McpInstrumentationReport.parse(
        'INSTRUMENTATION_RESULT: shortMsg=Process crashed.\n'
        'INSTRUMENTATION_CODE: 0\n',
      );
      expect(report.runError, 'Process crashed.');
      expect(report.succeeded, isFalse);
    });

    test('finds the runner for a target package', () {
      expect(
        McpInstrumentationOps.parseRunners(
          'instrumentation:com.example.test/androidx.test.runner.'
          'AndroidJUnitRunner (target=com.example)\n',
        ),
        {
          'com.example':
              'com.example.test/androidx.test.runner.AndroidJUnitRunner',
        },
      );
    });
  });

  test('app start timing from am start -W', () {
    const out = '''
Starting: Intent { cmp=com.android.settings/.Settings }
Status: ok
LaunchState: COLD
Activity: com.android.settings/.Settings
TotalTime: 812
WaitTime: 830
Complete
''';
    final summary = McpAppStartOps.summarize(out)!;
    expect(summary, contains('TotalTime): 812 ms'));
    expect(summary, contains('Launch state: COLD'));
    expect(summary, isNot(contains('Status')));
    expect(McpAppStartOps.summarize('Error: Activity not started'), isNull);
    // Android 13, warm start right after HOME: no TotalTime at all.
    final warm = McpAppStartOps.summarize(
      'Status: ok\nLaunchState: UNKNOWN (0)\nWaitTime: 113\nComplete\n',
    )!;
    expect(warm, contains('WaitTime): 113 ms'));
    expect(warm, contains('no first frame'));
    // Measured on Android 13 with Settings already in front.
    expect(
      McpAppStartOps.summarize(
        'Status: ok\nLaunchState: UNKNOWN (0)\nTotalTime: 0\nWaitTime: 19\n',
      ),
      contains('no first frame'),
    );
  });
}
