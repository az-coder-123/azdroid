import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wifi_desk/core/di/injection.dart';
import 'package:wifi_desk/core/services/app_logger.dart';
import 'package:wifi_desk/core/services/network_info_service.dart';
import 'package:wifi_desk/core/theme/app_colors.dart';
import 'package:wifi_desk/features/discovery/domain/entities/device_entity.dart';
import 'package:wifi_desk/features/discovery/presentation/cubit/pairing_cubit.dart';
import 'package:wifi_desk/features/discovery/presentation/cubit/pairing_state.dart';
import 'package:wifi_desk/features/discovery/presentation/widgets/pairing/pairing_dialog_header.dart';
import 'package:wifi_desk/features/discovery/presentation/widgets/pairing/pairing_host_ip_banner.dart';
import 'package:wifi_desk/features/discovery/presentation/widgets/pairing/pairing_manual_code_tab.dart';
import 'package:wifi_desk/features/discovery/presentation/widgets/pairing/pairing_qr_code_tab.dart';
import 'package:wifi_desk/features/discovery/presentation/widgets/pairing/pairing_status_banner.dart';
import 'package:wifi_desk/features/discovery/presentation/widgets/pairing/pairing_tab_switcher.dart';

/// Modal dialog providing interactive step-by-step wireless pairing for Android 11+
/// supporting both automated QR Code scanning and manual 6-digit PIN entry.
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
  int _selectedTabIndex = 0; // 0: QR Code, 1: Manual PIN
  String? _hostMacIp;
  late String _qrPairingCode;
  static const String _qrServiceName = 'wifidesk';

  late final TextEditingController _ipController;
  late final TextEditingController _portController;
  late final TextEditingController _codeController;

  @override
  void initState() {
    super.initState();
    _generateRandomQrCode();
    _loadHostIp();

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

  void _generateRandomQrCode() {
    final rng = Random();
    _qrPairingCode = (100000 + rng.nextInt(900000)).toString();
  }

  Future<void> _loadHostIp() async {
    try {
      final ip = await sl<NetworkInfoService>().getLocalIpAddress();
      if (mounted && ip != null) {
        setState(() => _hostMacIp = ip);
      }
    } catch (e, stack) {
      AppLogger.warning(
        'Failed to load host Mac IP for pairing dialog',
        error: e,
        stackTrace: stack,
      );
    }
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  String get _qrPayload => 'WIFI:T:ADB;S:$_qrServiceName;P:$_qrPairingCode;;';

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
                    PairingHostIpBanner(hostMacIp: _hostMacIp),
                    const SizedBox(height: 16),
                    PairingTabSwitcher(
                      selectedTabIndex: _selectedTabIndex,
                      isSubmitting: isSubmitting,
                      onSelectTab: (idx) =>
                          setState(() => _selectedTabIndex = idx),
                    ),
                    const SizedBox(height: 18),
                    if (_selectedTabIndex == 0)
                      PairingQrCodeTab(
                        qrPayload: _qrPayload,
                        pairingCode: _qrPairingCode,
                        onRegenerateCode: () => setState(_generateRandomQrCode),
                      )
                    else
                      PairingManualCodeTab(
                        isSubmitting: isSubmitting,
                        hostMacIp: _hostMacIp,
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
                        if (_selectedTabIndex == 1) ...[
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
                            label: Text(
                              isSubmitting ? 'Pairing...' : 'Pair & Connect',
                            ),
                          ),
                        ],
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
}
