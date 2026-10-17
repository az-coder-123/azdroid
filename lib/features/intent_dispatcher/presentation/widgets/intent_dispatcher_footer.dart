import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/features/intent_dispatcher/presentation/cubit/intent_dispatcher_cubit.dart';
import 'package:desk_droid/features/intent_dispatcher/presentation/cubit/intent_dispatcher_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Modal dialog action buttons for cancelling or triggering intent dispatch.
class IntentDispatcherFooter extends StatelessWidget {
  const IntentDispatcherFooter({required this.onDispatch, super.key});

  final VoidCallback onDispatch;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          BlocBuilder<IntentDispatcherCubit, IntentDispatcherState>(
            builder: (context, state) {
              final isSending = state is IntentDispatcherSending;
              return ElevatedButton.icon(
                icon: isSending
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 14),
                label: Text(isSending ? 'Dispatching...' : 'Dispatch Intent'),
                onPressed: isSending ? null : onDispatch,
              );
            },
          ),
        ],
      ),
    );
  }
}
