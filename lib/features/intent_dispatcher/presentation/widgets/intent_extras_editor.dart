import 'package:flutter/material.dart';
import 'package:wifi_desk/core/theme/app_colors.dart';

/// Interactive editor widget for adding, inspecting, and removing typed Intent extras.
class IntentExtrasEditor extends StatefulWidget {
  const IntentExtrasEditor({
    required this.extras,
    required this.onExtrasChanged,
    super.key,
  });

  final Map<String, dynamic> extras;
  final ValueChanged<Map<String, dynamic>> onExtrasChanged;

  @override
  State<IntentExtrasEditor> createState() => _IntentExtrasEditorState();
}

class _IntentExtrasEditorState extends State<IntentExtrasEditor> {
  final _keyController = TextEditingController();
  final _valController = TextEditingController();
  String _selectedType = 'String';

  @override
  void dispose() {
    _keyController.dispose();
    _valController.dispose();
    super.dispose();
  }

  void _addExtra() {
    final key = _keyController.text.trim();
    final rawVal = _valController.text.trim();
    if (key.isEmpty) return;

    dynamic parsedVal;
    if (_selectedType == 'Int') {
      parsedVal = int.tryParse(rawVal) ?? 0;
    } else if (_selectedType == 'Bool') {
      parsedVal = rawVal.toLowerCase() == 'true' || rawVal == '1';
    } else {
      parsedVal = rawVal;
    }

    final updated = Map<String, dynamic>.from(widget.extras)..[key] = parsedVal;
    widget.onExtrasChanged(updated);

    _keyController.clear();
    _valController.clear();
  }

  void _removeExtra(String key) {
    final updated = Map<String, dynamic>.from(widget.extras)..remove(key);
    widget.onExtrasChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.extras.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: widget.extras.entries.map((e) {
              final typeLabel = e.value is int
                  ? 'Int'
                  : e.value is bool
                  ? 'Bool'
                  : 'Str';
              return Chip(
                backgroundColor: AppColors.surfaceElevated,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                label: Text(
                  '${e.key} ($typeLabel): "${e.value}"',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textPrimary,
                  ),
                ),
                deleteIcon: const Icon(Icons.close_rounded, size: 12),
                deleteIconColor: AppColors.textSecondary,
                onDeleted: () => _removeExtra(e.key),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],

        // Row to add a new extra
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: _keyController,
                style: const TextStyle(fontSize: 12),
                decoration: const InputDecoration(
                  hintText: 'Key (e.g. userId)',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 4,
              child: TextField(
                controller: _valController,
                style: const TextStyle(fontSize: 12),
                decoration: const InputDecoration(
                  hintText: 'Value',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                ),
                onSubmitted: (_) => _addExtra(),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedType,
                  isDense: true,
                  items: const [
                    DropdownMenuItem(
                      value: 'String',
                      child: Text('String', style: TextStyle(fontSize: 11)),
                    ),
                    DropdownMenuItem(
                      value: 'Int',
                      child: Text('Int', style: TextStyle(fontSize: 11)),
                    ),
                    DropdownMenuItem(
                      value: 'Bool',
                      child: Text('Bool', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedType = val);
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(
                Icons.add_circle_outline_rounded,
                size: 20,
                color: AppColors.accent,
              ),
              tooltip: 'Add Extra',
              onPressed: _addExtra,
            ),
          ],
        ),
      ],
    );
  }
}
