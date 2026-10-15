import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/features/intent_dispatcher/presentation/cubit/intent_dispatcher_cubit.dart';
import 'package:desk_droid/features/intent_dispatcher/presentation/cubit/intent_dispatcher_state.dart';

/// Renders success and error feedback banners for dispatched intents.
class IntentStatusBanner extends StatelessWidget {
  const IntentStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IntentDispatcherCubit, IntentDispatcherState>(
      builder: (context, state) {
        if (state is IntentDispatcherSuccess) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.statusSuccess.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.statusSuccess.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.statusSuccess,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    state.result.message,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.statusSuccess,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        if (state is IntentDispatcherFailure) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.statusError.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.statusError.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.statusError,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    state.errorMessage,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.statusError,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
