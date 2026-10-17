import 'package:desk_droid/core/constants/feedback_durations.dart';
import 'package:desk_droid/core/di/injection.dart';
import 'package:desk_droid/core/extensions/optional_read_extension.dart';
import 'package:desk_droid/core/models/device_entity.dart';
import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/features/discovery/presentation/cubit/host_context_cubit.dart';
import 'package:desk_droid/features/discovery/presentation/cubit/pairing_cubit.dart';
import 'package:desk_droid/features/discovery/presentation/cubit/pairing_state.dart';
import 'package:desk_droid/features/discovery/presentation/widgets/host_context_builder.dart';
import 'package:desk_droid/features/discovery/presentation/widgets/pairing/pairing_dialog_header.dart';
import 'package:desk_droid/features/discovery/presentation/widgets/pairing/pairing_host_ip_banner.dart';
import 'package:desk_droid/features/discovery/presentation/widgets/pairing/pairing_manual_code_tab.dart';
import 'package:desk_droid/features/discovery/presentation/widgets/pairing/pairing_status_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Modal dialog providing interactive step-by-step wireless pairing for Android 11+
/// using authentic 6-digit Wi-Fi pairing code and port entry.
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
    context.tryRead<HostContextCubit>()?.load();

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

  void _submitManualPair(BuildContext context) {
    final port = int.tryParse(_portController.text.trim()) ?? 0;
    context.read<PairingCubit>().pair(
      ipAddress: _ipController.text,
      port: port,
      pairingCode: _codeController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PairingCubit>(
      create: (_) => sl<PairingCubit>(),
      child: BlocConsumer<PairingCubit, PairingState>(
        listener: (context, state) {
          if (state is PairingSuccess) {
            widget.onPairingSuccess?.call();
            Future.delayed(FeedbackDurations.dialogAutoClose, () {
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            });
          }
        },
        builder: (context, state) {
          final isSubmitting = state is PairingSubmitting;

          return HostContextBuilder(
            builder: (context, host) => _buildDialog(
              context,
              state: state,
              isSubmitting: isSubmitting,
              hostMacIp: host.hostIpAddress,
            ),
          );
        },
      ),
    );
  }

  Widget _buildDialog(
    BuildContext context, {
    required PairingState state,
    required bool isSubmitting,
    required String? hostMacIp,
  }) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PairingDialogHeader(
                isSubmitting: isSubmitting,
                onClose: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 16),
              PairingHostIpBanner(hostMacIp: hostMacIp),
              const SizedBox(height: 16),
              PairingManualCodeTab(
                isSubmitting: isSubmitting,
                hostMacIp: hostMacIp,
                ipController: _ipController,
                portController: _portController,
                codeController: _codeController,
              ),
              const SizedBox(height: 16),
              PairingStatusBanner(state: state),
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
                        : () => _submitManualPair(context),
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
                    label: Text(isSubmitting ? 'Pairing...' : 'Pair & Connect'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
