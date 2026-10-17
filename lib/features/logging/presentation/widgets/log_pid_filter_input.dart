import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/features/logging/presentation/widgets/log_pid_dropdown_menu.dart';
import 'package:desk_droid/features/logging/presentation/widgets/log_tag_dropdown_menu.dart';
import 'package:flutter/material.dart';

/// Process ID (PID) filter input field providing number input, live autocomplete,
/// and a dropdown selector of all active processes detected in the log buffer.
class LogPidFilterInput extends StatefulWidget {
  const LogPidFilterInput({
    super.key,
    required this.controller,
    required this.pidCounts,
    this.pidPrimaryTags = const {},
    required this.onChanged,
  });

  final TextEditingController controller;
  final Map<int, int> pidCounts;
  final Map<int, String> pidPrimaryTags;
  final ValueChanged<int?> onChanged;

  @override
  State<LogPidFilterInput> createState() => _LogPidFilterInputState();
}

class _LogPidFilterInputState extends State<LogPidFilterInput> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _selectPid(int pid) {
    widget.controller.text = pid.toString();
    widget.onChanged(pid);
  }

  void _clearPid() {
    widget.controller.clear();
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<int>(
      textEditingController: widget.controller,
      focusNode: _focusNode,
      optionsBuilder: (TextEditingValue textEditingValue) {
        final query = textEditingValue.text.trim();
        if (query.isEmpty) return const Iterable<int>.empty();
        return widget.pidCounts.keys
            .where((pid) => pid.toString().contains(query))
            .take(8);
      },
      onSelected: _selectPid,
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8,
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(8),
            clipBehavior: Clip.antiAlias,
            child: Container(
              width: 200,
              constraints: const BoxConstraints(maxHeight: 220),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final pid = options.elementAt(index);
                  final count = widget.pidCounts[pid] ?? 0;
                  final primaryTag = widget.pidPrimaryTags[pid] ?? '';

                  return InkWell(
                    onTap: () => onSelected(pid),
                    hoverColor: AppColors.surfaceCard,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          Text(
                            '$pid',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (primaryTag.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                primaryTag,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ] else
                            const Spacer(),
                          const SizedBox(width: 6),
                          LogTagCountBadge(count: count),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            final hasText = value.text.isNotEmpty;
            final currentPid = int.tryParse(value.text.trim());

            return TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: TextInputType.number,
              onChanged: (val) {
                final pid = int.tryParse(val.trim());
                widget.onChanged(pid);
              },
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
                fontFamily: 'monospace',
              ),
              decoration: InputDecoration(
                hintText: 'PID',
                hintStyle: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontFamily: 'sans-serif',
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 0,
                ),
                filled: true,
                fillColor: AppColors.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: AppColors.borderSubtle),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: AppColors.borderSubtle),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(
                    color: AppColors.accent,
                    width: 1.5,
                  ),
                ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasText)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 14),
                        tooltip: 'Clear PID',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        onPressed: _clearPid,
                      ),
                    LogPidDropdownMenu(
                      selectedPid: currentPid,
                      pidCounts: widget.pidCounts,
                      pidPrimaryTags: widget.pidPrimaryTags,
                      onPidSelected: _selectPid,
                      onClearPid: _clearPid,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
