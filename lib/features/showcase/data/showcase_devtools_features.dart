import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/features/showcase/domain/entities/app_feature_item.dart';
import 'package:flutter/material.dart';

/// Developer tools and diagnostic features presented in the showcase dialog.
const List<AppFeatureItem> showcaseDevToolsFeatures = [
  AppFeatureItem(
    id: 'logcat_console',
    title: 'Professional Logcat Console',
    subtitle: 'IDE-grade Android log inspection with live filterable stream (Cmd+Shift+L)',
    category: FeatureCategory.devTools,
    icon: Icons.terminal_rounded,
    badgeText: '⌘⇧L • 5k Buffer',
    badgeColor: AppColors.statusWarning,
    highlights: [
      'Live stream batched every 100 ms into a 5,000-line ring buffer.',
      'Multi-tier filtering by Tag, PID, and Log Level (Verbose to Fatal).',
      'Stack trace detail drawer, star bookmarks, and non-blocking file recording.',
    ],
    proTip: 'Press Cmd+Shift+L or click the terminal icon on the dock.',
    docFileName: 'device-logcat-console.md',
  ),
  AppFeatureItem(
    id: 'apk_installer',
    title: '1-Click APK Sideload & Manager',
    subtitle: 'Install Android packages instantly without terminal commands (Cmd+Shift+I)',
    category: FeatureCategory.devTools,
    icon: Icons.install_mobile_rounded,
    badgeText: '⌘⇧I • 1-Click Sideload',
    badgeColor: AppColors.statusSuccess,
    highlights: [
      'Select or drag APK files for automated inspection and installation.',
      'Preview package name, version, app label, icon, and SDK levels.',
      'Launch the application directly on device upon successful installation.',
    ],
    proTip: 'Press Cmd+Shift+I to open the APK installer.',
    docFileName: 'apk-sideload-manager.md',
  ),
  AppFeatureItem(
    id: 'intent_dispatcher',
    title: 'Deep Link & Intent Dispatcher',
    subtitle: 'Fire custom Android intents, schemes, and deep links with typed extras (Cmd+Shift+D)',
    category: FeatureCategory.devTools,
    icon: Icons.alt_route_rounded,
    badgeText: '⌘⇧D • URL Schemes',
    badgeColor: AppColors.accent,
    highlights: [
      'Quick presets for Web URLs, Google Play Market, Geo Maps, and Tel dialer.',
      'Supports custom app schemes, package targeting, and activity components.',
      'Interactive key-value Intent Extras editor supporting String, Int, and Bool.',
    ],
    proTip: 'Press Cmd+Shift+D while mirroring to test deep links.',
    docFileName: 'deep-link-intent-dispatcher.md',
  ),
  AppFeatureItem(
    id: 'mcp_ai_server',
    title: 'MCP AI Agent Server (Model Context Protocol)',
    subtitle: '58 headless tools for Claude Desktop, Cursor, and Antigravity AI agents',
    category: FeatureCategory.devTools,
    icon: Icons.smart_toy_rounded,
    badgeText: '58 Tools • AI Agent',
    badgeColor: AppColors.accent,
    highlights: [
      'Pure Dart JSON-RPC 2.0 server communicating via stdio (bin/deskdroid_mcp.dart).',
      'Semantic UI parsing prunes 97% of DOM noise for fast, accurate AI clicks.',
      'Supports taps, text injection, swipes, dumpsys telemetry, and macro batches.',
      'The hub icon in the device list shows the server state, AI client setup, and connected sessions.',
    ],
    proTip: 'Connect Azdroid to Claude Desktop or Cursor to automate mobile testing with AI.',
    docFileName: 'mcp-ai-agent-server.md',
  ),
];
