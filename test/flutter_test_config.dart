import 'dart:async';

import 'package:desk_droid/features/mcp/data/services/mcp_fast_input.dart';
import 'package:desk_droid/features/mcp/data/services/mcp_unsupported_exception.dart';

/// Runs before every test file (flutter_test convention).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Unit tests never start a scrcpy session on a real device: taps and
  // swipes take the adb path unless a test installs its own opener
  // (test/unit/mcp_fast_input_test.dart).
  McpFastInput.opener = (_, _) async =>
      throw const McpUnsupportedOnDeviceException('scrcpy is off in tests');
  await testMain();
}
