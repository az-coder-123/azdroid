import 'package:flutter/material.dart';

/// Represents a distinct navigational category in the user guide handbook.
class GuideCategory {
  const GuideCategory({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
}
