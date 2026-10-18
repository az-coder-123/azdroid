import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/features/mcp_status/domain/entities/mcp_binary_status.dart';
import 'package:desk_droid/features/mcp_status/domain/entities/mcp_client_status.dart';
import 'package:desk_droid/features/mcp_status/domain/entities/mcp_server_status.dart';
import 'package:desk_droid/features/mcp_status/presentation/widgets/mcp_activity_labels.dart';
import 'package:flutter/material.dart';

/// Visual weight of an MCP status line.
enum McpTone {
  success(AppColors.statusSuccess),
  info(AppColors.statusInfo),
  warning(AppColors.statusWarning),
  error(AppColors.statusError),
  neutral(AppColors.textTertiary);

  const McpTone(this.color);

  final Color color;
}

/// A status line: what to show and how strongly.
typedef McpLabel = ({String text, McpTone tone});

/// User-facing wording for the MCP status, kept in one place so the toolbar
/// indicator and the panel always agree.
class McpStatusLabels {
  const McpStatusLabels._();

  /// One-line summary for the toolbar tooltip and the panel header.
  static McpLabel overall(McpServerStatus status) {
    final active = status.activity.activeByDevice.entries.firstOrNull;
    if (active != null) {
      return (
        text:
            '${McpActivityLabels.client(active.value.clientName)} is using '
            '${active.value.event.tool ?? 'a tool'} on ${active.key}',
        tone: McpTone.success,
      );
    }
    final sessions = status.runningSessions ?? 0;
    if (status.binary.isReady && sessions > 0) return sessionsLabel(sessions);
    return switch (status.binary.availability) {
      McpBinaryAvailability.missing => (
        text: 'Not included in this build',
        tone: McpTone.neutral,
      ),
      McpBinaryAvailability.needsRosetta => (
        text: 'Needs Rosetta 2 to run',
        tone: McpTone.warning,
      ),
      McpBinaryAvailability.notResponding => (
        text: 'Server does not respond',
        tone: McpTone.error,
      ),
      McpBinaryAvailability.ready when status.anyClientConfigured => (
        text: 'Ready, waiting for an AI client',
        tone: McpTone.info,
      ),
      McpBinaryAvailability.ready => (
        text: 'Ready, not set up in an AI client',
        tone: McpTone.warning,
      ),
    };
  }

  static McpLabel binary(McpBinaryStatus binary) =>
      switch (binary.availability) {
        McpBinaryAvailability.ready => (
          text: binary.runsTranslated
              ? 'Runs (through Rosetta 2)'
              : 'Runs and answers',
          tone: McpTone.success,
        ),
        McpBinaryAvailability.needsRosetta => (
          text: 'Intel-only build; install Rosetta 2',
          tone: McpTone.warning,
        ),
        McpBinaryAvailability.notResponding => (
          text: 'Starts but does not answer',
          tone: McpTone.error,
        ),
        McpBinaryAvailability.missing => (
          text: 'Not in this build (debug builds skip it)',
          tone: McpTone.neutral,
        ),
      };

  static McpLabel sessions(int? count) => count == null
      ? (text: 'Session count unavailable', tone: McpTone.neutral)
      : count == 0
      ? (text: 'No AI session connected', tone: McpTone.neutral)
      : sessionsLabel(count);

  static McpLabel sessionsLabel(int count) => (
    text: count == 1
        ? '1 AI session connected'
        : '$count AI sessions connected',
    tone: McpTone.success,
  );

  static McpLabel client(McpClientStatus client) => switch (client.setup) {
    McpClientSetup.configured => (text: 'Set up', tone: McpTone.success),
    McpClientSetup.configuredElsewhere => (
      text: 'Uses another copy',
      tone: McpTone.warning,
    ),
    McpClientSetup.notConfigured => (text: 'Not set up', tone: McpTone.neutral),
    McpClientSetup.clientNotFound => (
      text: 'Not installed',
      tone: McpTone.neutral,
    ),
    McpClientSetup.unreadable => (
      text: 'Config is not valid JSON',
      tone: McpTone.error,
    ),
  };

  /// Readable CPU list (`Intel (x86_64)`, `Apple Silicon (arm64)`).
  static String architectures(List<String> archs) => archs
      .map(
        (a) => switch (a) {
          'x86_64' => 'Intel (x86_64)',
          'arm64' => 'Apple Silicon (arm64)',
          _ => a,
        },
      )
      .join(' + ');
}
