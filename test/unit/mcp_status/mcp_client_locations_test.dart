import 'package:desk_droid/core/platform/host_os.dart';
import 'package:desk_droid/core/platform/host_paths.dart';
import 'package:desk_droid/core/platform/mcp_client_locations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  List<McpClientLocation> locationsFor(HostOs os, Map<String, String> env) =>
      McpClientLocations.forHost(
        os: os,
        paths: SystemHostPaths(os: os, environment: env, systemTempPath: 't'),
        environment: env,
      ).clients;

  test('macOS paths of Claude Desktop, Cursor, and Antigravity', () {
    final paths = {
      for (final c in locationsFor(HostOs.macos, {'HOME': '/Users/dev'}))
        c.name: c.configPath,
    };
    expect(paths, {
      'Claude Desktop': '/Users/dev/Library/Application Support/Claude/claude_desktop_config.json',
      'Cursor': '/Users/dev/.cursor/mcp.json',
      'Antigravity': '/Users/dev/.gemini/antigravity/mcp_config.json',
    });
  });

  test('Windows uses APPDATA for Claude and the profile for the others', () {
    final paths = {
      for (final c in locationsFor(HostOs.windows, {
        'USERPROFILE': r'C:\Users\dev',
        'APPDATA': r'C:\Users\dev\AppData\Roaming',
      }))
        c.name: c.configPath,
    };
    expect(
      paths['Claude Desktop'],
      r'C:\Users\dev\AppData\Roaming\Claude\claude_desktop_config.json',
    );
    expect(paths['Cursor'], r'C:\Users\dev\.cursor\mcp.json');
  });
}
