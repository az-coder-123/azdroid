import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/features/logging/presentation/cubit/device_log_cubit.dart';

/// Horizontal bar displaying active excluded tags with 1-click removal chips.
class LogExcludeTagsBar extends StatelessWidget {
  const LogExcludeTagsBar({
    super.key,
    required this.excludeTags,
    this.availableTags = const {},
  });

  final Set<String> excludeTags;
  final Map<String, int> availableTags;

  @override
  Widget build(BuildContext context) {
    if (excludeTags.isEmpty) return const SizedBox.shrink();

    final cubit = context.read<DeviceLogCubit>();

    return Container(
      padding: const EdgeInsets.only(top: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Icon(
              Icons.block_rounded,
              size: 13,
              color: AppColors.statusError,
            ),
            const SizedBox(width: 4),
            const Text(
              'Excluded:',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.statusError,
              ),
            ),
            const SizedBox(width: 6),
            for (final tag in excludeTags) ...[
              Container(
                padding: const EdgeInsets.only(
                  left: 6,
                  right: 2,
                  top: 1,
                  bottom: 1,
                ),
                decoration: BoxDecoration(
                  color: AppColors.statusError.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: AppColors.statusError.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '-$tag',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: AppColors.statusError,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    InkWell(
                      onTap: () => cubit.removeExcludeTag(tag),
                      borderRadius: BorderRadius.circular(10),
                      child: const Padding(
                        padding: EdgeInsets.all(2),
                        child: Icon(
                          Icons.close_rounded,
                          size: 12,
                          color: AppColors.statusError,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
            ],
            InkWell(
              onTap: cubit.clearExcludeTags,
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  'Clear all',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
