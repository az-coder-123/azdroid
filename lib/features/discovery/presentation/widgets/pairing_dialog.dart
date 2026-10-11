import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:wifi_desk/core/di/injection.dart';
import 'package:wifi_desk/core/services/network_info_service.dart';
import 'package:wifi_desk/core/theme/app_colors.dart';
import 'package:wifi_desk/core/theme/app_typography.dart';
import 'package:wifi_desk/features/discovery/domain/entities/device_entity.dart';
import 'package:wifi_desk/features/discovery/presentation/cubit/pairing_cubit.dart';
import 'package:wifi_desk/features/discovery/presentation/cubit/pairing_state.dart';

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
  final String _qrServiceName = 'wifidesk';

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
    } catch (_) {}
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  String get _qrPayload => 'WIFI:T:ADB;S:$_qrServiceName;P:$_qrPairingCode;;';

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
              width: 500,
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                            Icons.qr_code_scanner_rounded,
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
                    const SizedBox(height: 16),

                    // Host Mac IP & Subnet Context Banner
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.wifi_rounded,
                            size: 16,
                            color: AppColors.statusSuccess,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _hostMacIp != null
                                  ? 'Mac Wi-Fi IP: $_hostMacIp'
                                  : 'Detecting Mac Wi-Fi IP...',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            'Must match Phone Wi-Fi',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Pairing Method Segmented Tab Switcher
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      padding: const EdgeInsets.all(3),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildTabButton(
                              index: 0,
                              icon: Icons.qr_code_2_rounded,
                              label: 'Scan QR Code',
                              isSubmitting: isSubmitting,
                            ),
                          ),
                          Expanded(
                            child: _buildTabButton(
                              index: 1,
                              icon: Icons.pin_rounded,
                              label: 'Manual 6-Digit PIN',
                              isSubmitting: isSubmitting,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Tab Views
                    if (_selectedTabIndex == 0)
                      _buildQrCodeTab()
                    else
                      _buildManualCodeTab(isSubmitting: isSubmitting),

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
                        if (_selectedTabIndex == 1) ...[
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

  Widget _buildTabButton({
    required int index,
    required IconData icon,
    required String label,
    required bool isSubmitting,
  }) {
    final isSelected = _selectedTabIndex == index;
    return InkWell(
      onTap: isSubmitting
          ? null
          : () => setState(() => _selectedTabIndex = index),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrCodeTab() {
    return Column(
      children: [
        // Instructions for QR scanning
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How to pair using QR code:',
                style: AppTypography.subtitle.copyWith(fontSize: 12),
              ),
              const SizedBox(height: 6),
              _buildStepItem(
                '1',
                'Open Settings ➔ Developer Options ➔ Wireless Debugging.',
              ),
              _buildStepItem(
                '2',
                'Tap "Pair device with QR code" (Ghép nối bằng mã QR).',
              ),
              _buildStepItem(
                '3',
                'Point your phone camera at the QR code below to scan.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // QR Code Container with High-Contrast White Background
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: QrImageView(
              data: _qrPayload,
              version: QrVersions.auto,
              size: 180.0,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Colors.black,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Colors.black,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // PIN & Refresh Helper
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Pairing PIN: ',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              _qrPairingCode,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: AppColors.accentLight,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 16),
              tooltip: 'Generate New QR Code',
              onPressed: () => setState(_generateRandomQrCode),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildManualCodeTab({required bool isSubmitting}) {
    return Column(
      children: [
        // Instructional Guide Banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Manual PIN Entry Guide:',
                style: AppTypography.subtitle.copyWith(fontSize: 12),
              ),
              const SizedBox(height: 6),
              _buildStepItem(
                '1',
                'Open Settings ➔ Developer Options ➔ Wireless Debugging.',
              ),
              _buildStepItem(
                '2',
                'Tap "Pair device with pairing code" (Ghép nối bằng mã ghép nối).',
              ),
              _buildStepItem(
                '3',
                'Enter the phone IP, pairing port, and 6-digit code shown on screen.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Form Fields: Phone IP & Port
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: _ipController,
                enabled: !isSubmitting,
                decoration: InputDecoration(
                  labelText: 'Phone IP (Địa chỉ IP điện thoại)',
                  hintText: _hostMacIp != null
                      ? 'e.g. ${_hostMacIp!.substring(0, _hostMacIp!.lastIndexOf('.') + 1)}xxx'
                      : '192.168.1.100',
                  helperText: 'View on phone under Wireless Debugging',
                  isDense: true,
                  border: const OutlineInputBorder(),
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
                  helperText: 'Port displayed with PIN',
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
            labelText: '6-Digit Pairing Code (Mã ghép nối)',
            hintText: '123456',
            counterText: '',
            isDense: true,
            border: OutlineInputBorder(),
          ),
        ),
      ],
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
