import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:wifi_desk/features/logging/domain/entities/log_filter_criteria.dart';
import 'package:wifi_desk/features/logging/domain/entities/log_level.dart';

/// Predefined or user-defined log filter preset with quick activation.
class LogFilterPreset extends Equatable {
  const LogFilterPreset({
    required this.id,
    required this.name,
    this.icon,
    required this.criteria,
  });

  final String id;
  final String name;
  final IconData? icon;
  final LogFilterCriteria criteria;

  @override
  List<Object?> get props => [id, name, criteria];

  /// Standard built-in developer filter presets.
  static final List<LogFilterPreset> defaultPresets = [
    const LogFilterPreset(
      id: 'default',
      name: 'All Logs',
      icon: Icons.clear_all_rounded,
      criteria: LogFilterCriteria(),
    ),
    const LogFilterPreset(
      id: 'crash_hunter',
      name: 'Crashes & ANRs',
      icon: Icons.crisis_alert_rounded,
      criteria: LogFilterCriteria(
        selectedLevels: {LogLevel.error, LogLevel.fatal},
        textQuery: 'FATAL|ANR|Exception|Error',
        isRegex: true,
      ),
    ),
    const LogFilterPreset(
      id: 'network',
      name: 'Network & HTTP',
      icon: Icons.wifi_tethering_rounded,
      criteria: LogFilterCriteria(tagFilter: 'OkHttp'),
    ),
    const LogFilterPreset(
      id: 'audio_media',
      name: 'Audio & Media',
      icon: Icons.music_note_rounded,
      criteria: LogFilterCriteria(tagFilter: 'Audio'),
    ),
    const LogFilterPreset(
      id: 'system_core',
      name: 'Android System',
      icon: Icons.phone_android_rounded,
      criteria: LogFilterCriteria(tagFilter: 'ActivityManager'),
    ),
    const LogFilterPreset(
      id: 'starred',
      name: 'Starred Only',
      icon: Icons.star_rounded,
      criteria: LogFilterCriteria(bookmarksOnly: true),
    ),
  ];
}
