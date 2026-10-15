import 'package:flutter/material.dart';
import 'package:wifi_desk/core/theme/app_colors.dart';
import 'package:wifi_desk/features/logging/presentation/widgets/log_tag_dropdown_menu.dart';

/// Tag filter input field providing freeform typing, live autocomplete,
/// and a dropdown selector of all active apps and modules detected in the logs.
class LogTagFilterInput extends StatefulWidget {
  const LogTagFilterInput({
    super.key,
    required this.controller,
    required this.tagCounts,
    required this.onChanged,
  });

  final TextEditingController controller;
  final Map<String, int> tagCounts;
  final ValueChanged<String> onChanged;

  @override
  State<LogTagFilterInput> createState() => _LogTagFilterInputState();
}

class _LogTagFilterInputState extends State<LogTagFilterInput> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _selectTag(String tag) {
    widget.controller.text = tag;
    widget.onChanged(tag);
  }

  void _clearTag() {
    widget.controller.clear();
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      textEditingController: widget.controller,
      focusNode: _focusNode,
      optionsBuilder: (TextEditingValue textEditingValue) {
        final query = textEditingValue.text.trim().toLowerCase();
        if (query.isEmpty) return const Iterable<String>.empty();
        return widget.tagCounts.keys
            .where((tag) => tag.toLowerCase().contains(query))
            .take(10);
      },
      onSelected: _selectTag,
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8,
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(8),
            clipBehavior: Clip.antiAlias,
            child: Container(
              width: 260,
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
                  final tag = options.elementAt(index);
                  final count = widget.tagCounts[tag] ?? 0;
                  return InkWell(
                    onTap: () => onSelected(tag),
                    hoverColor: AppColors.surfaceCard,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              tag,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
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
            return TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: widget.onChanged,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Tag (e.g. Activity)',
                hintStyle: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
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
                        tooltip: 'Clear Tag',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 24,
                          minHeight: 24,
                        ),
                        onPressed: _clearTag,
                      ),
                    LogTagDropdownMenu(
                      selectedTag: controller.text,
                      tagCounts: widget.tagCounts,
                      onTagSelected: _selectTag,
                      onClearTag: _clearTag,
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
