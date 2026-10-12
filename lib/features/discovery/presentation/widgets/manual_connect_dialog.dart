import 'package:flutter/material.dart';
import 'package:wifi_desk/core/constants/socket_config.dart';
import 'package:wifi_desk/core/di/injection.dart';
import 'package:wifi_desk/core/services/app_logger.dart';
import 'package:wifi_desk/core/services/network_info_service.dart';
import 'package:wifi_desk/core/theme/app_colors.dart';
import 'package:wifi_desk/core/theme/app_typography.dart';

/// Simple modal dialog allowing manual IP and port input for direct connection.
class ManualConnectDialog extends StatefulWidget {
  const ManualConnectDialog({super.key, required this.onConnect});

  final void Function(String ipAddress, int port) onConnect;

  /// Static helper to display the manual connection modal.
  static Future<void> show(
    BuildContext context, {
    required void Function(String ipAddress, int port) onConnect,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => ManualConnectDialog(onConnect: onConnect),
    );
  }

  @override
  State<ManualConnectDialog> createState() => _ManualConnectDialogState();
}

class _ManualConnectDialogState extends State<ManualConnectDialog> {
  late final TextEditingController _ipController;
  late final TextEditingController _portController;
  String? _errorMessage;
  String? _hostMacIp;

  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController();
    _portController = TextEditingController(
      text: SocketConfig.defaultAdbWirelessPort.toString(),
    );
    _loadHostIp();
  }

  Future<void> _loadHostIp() async {
    try {
      final ip = await sl<NetworkInfoService>().getLocalIpAddress();
      if (mounted && ip != null) {
        setState(() => _hostMacIp = ip);
      }
    } catch (e, stack) {
      AppLogger.warning(
        'Failed to load host Mac IP for manual connect dialog',
        error: e,
        stackTrace: stack,
      );
    }
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  void _submit() {
    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim());

    if (ip.isEmpty) {
      setState(() => _errorMessage = 'Please provide the phone IP address.');
      return;
    }

    if (port == null || port <= 0 || port > 65535) {
      setState(() => _errorMessage = 'Please enter a valid port (1 - 65535).');
      return;
    }

    widget.onConnect(ip, port);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.link_rounded,
                    color: AppColors.accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Direct IP Connect', style: AppTypography.title),
                      SizedBox(height: 2),
                      Text(
                        'Connect via local Wi-Fi endpoint',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Mac Subnet Indicator Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _ipController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Phone IP (IP Điện thoại)',
                      hintText: _hostMacIp != null
                          ? 'e.g. ${_hostMacIp!.substring(0, _hostMacIp!.lastIndexOf('.') + 1)}xxx'
                          : '192.168.1.100',
                      helperText: 'View in phone Wi-Fi settings',
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _portController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Port (Cổng)',
                      hintText: '5555',
                      helperText: 'Default 5555',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                ),
              ],
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: AppTypography.caption.copyWith(
                  color: AppColors.statusError,
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: const Text('Connect'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
