import 'dart:io';

import 'package:desk_droid/core/constants/app_constants.dart';
import 'package:desk_droid/features/mcp/data/handlers/mcp_protocol_handler.dart';
import 'package:flutter_test/flutter_test.dart';

/// The version shown by the app and reported by the MCP server must match
/// the one the release script reads from pubspec.yaml.
void main() {
  test('AppConstants.appVersion matches the pubspec version name', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match = RegExp(
      r'^version:\s*([0-9.]+)\+',
      multiLine: true,
    ).firstMatch(pubspec);
    expect(match, isNotNull, reason: 'no version line in pubspec.yaml');
    expect(AppConstants.appVersion, match!.group(1));
  });

  test('the MCP server reports the app version', () {
    expect(McpProtocolHandler.serverVersion, AppConstants.appVersion);
  });
}
