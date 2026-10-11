import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wifi_desk/core/di/injection.dart';
import 'package:wifi_desk/core/theme/app_colors.dart';
import 'package:wifi_desk/core/theme/app_typography.dart';
import 'package:wifi_desk/features/discovery/domain/entities/device_entity.dart';
import 'package:wifi_desk/features/discovery/presentation/cubit/pairing_cubit.dart';
import 'package:wifi_desk/features/discovery/presentation/cubit/pairing_state.dart';

/// Modal dialog providing interactive step-by-step wireless pairing for Android 11+.
class PairingDialog extends StatefulWidget {
  const PairingDialog({super.key, this.initialDevice, this.onPairingSuccess});

  final DeviceEntity? initialDevice;
  final VoidCallback? onPairingSuccess;

  /// Convenience static helper to display the pairing modal.
  static Future<void> show(
    BuildContext context, {
    DeviceEntity? initialDevice,
    VoidCallback? onPairingSuccess,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => PairingDialog(
        initialDevice: initialDevice,
        onPairingSuccess: onPairingSuccess,
      ),
    );
  }

  @override
  State<PairingDialog> createState() => _PairingDialogState();
}

class _PairingDialogState extends State<PairingDialog> {
  late final TextEditingController _ipController;
  late final TextEditingController _portController;
  late final TextEditingController _codeController;

  @override
  void initState() {
    super.initState();
    final device = widget.initialDevice;
    _ipController = TextEditingController(
      text: device != null && device.ipAddress != '127.0.0.1'
          ? device.ipAddress
          : '',
    );
    _portController = TextEditingController(
      text: (device?.pairingPort ?? 37123).toString(),
    );
    _codeController = TextEditingController();
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PairingCubit>(
      create: (_) => sl<PairingCubit>(),
      child: BlocConsumer<PairingCubit, PairingState>(
        listener: (context, state) {
          if (state is PairingSuccess) {
            widget.onPairingSuccess?.call();
            Future.delayed(const Duration(milliseconds: 900), () {
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            });
          }
        },
        builder: (context, state) {
          final isSubmitting = state is PairingSubmitting;

          return Dialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.0),
              side: const BorderSide(color: AppColors.border),
            ),
            child: Container(
              width: 480,
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dialog Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.phonelink_setup_rounded,
                            color: AppColors.accent,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Pair Wireless Device',
                                style: AppTypography.title,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Android 11+ Wireless Debugging Pairing',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: isSubmitting
                              ? null
                              : () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Instructional Guide Banner
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quick Setup Guide:',
                            style: AppTypography.subtitle.copyWith(
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _buildStepItem(
                            '1',
                            'Open Settings ➔ Developer Options ➔ Wireless Debugging.',
                          ),
                          _buildStepItem(
                            '2',
                            'Select "Pair device with pairing code".',
                          ),
                          _buildStepItem(
                            '3',
                            'Enter the 6-digit code and pairing port displayed on phone.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Form Fields: IP & Port
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _ipController,
                            enabled: !isSubmitting,
                            decoration: const InputDecoration(
                              labelText: 'IP Address',
                              hintText: '192.168.1.100',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _portController,
                            enabled: !isSubmitting,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Pairing Port',
                              hintText: '37123',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Form Field: 6-Digit Pairing Code
                    TextField(
                      controller: _codeController,
                      enabled: !isSubmitting,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: AppTypography.title.copyWith(
                        letterSpacing: 8.0,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: const InputDecoration(
                        labelText: '6-Digit Pairing Code',
                        hintText: '123456',
                        counterText: '',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Status / Error Banners
                    if (state is PairingFailure) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.statusError.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.statusError.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppColors.statusError,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                state.error,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.statusError,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (state is PairingSuccess) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.statusSuccess.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.statusSuccess.withValues(
                              alpha: 0.4,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline_rounded,
                              color: AppColors.statusSuccess,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                state.message,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.statusSuccess,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: isSubmitting
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: isSubmitting
                              ? null
                              : () {
                                  final port =
                                      int.tryParse(
                                        _portController.text.trim(),
                                      ) ??
                                      0;
                                  context.read<PairingCubit>().pair(
                                    ipAddress: _ipController.text,
                                    port: port,
                                    pairingCode: _codeController.text,
                                  );
                                },
                          icon: isSubmitting
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.check_rounded, size: 18),
                          label: Text(
                            isSubmitting ? 'Pairing...' : 'Pair & Connect',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStepItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number. ',
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.accent,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
