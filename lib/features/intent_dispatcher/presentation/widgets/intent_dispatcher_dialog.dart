import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:desk_droid/core/di/injection.dart';
import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/features/intent_dispatcher/domain/entities/intent_request_entity.dart';
import 'package:desk_droid/features/intent_dispatcher/domain/repositories/intent_repository.dart';
import 'package:desk_droid/features/intent_dispatcher/presentation/cubit/intent_dispatcher_cubit.dart';
import 'package:desk_droid/features/intent_dispatcher/presentation/widgets/intent_advanced_options.dart';
import 'package:desk_droid/features/intent_dispatcher/presentation/widgets/intent_dispatcher_footer.dart';
import 'package:desk_droid/features/intent_dispatcher/presentation/widgets/intent_dispatcher_header.dart';
import 'package:desk_droid/features/intent_dispatcher/presentation/widgets/intent_extras_editor.dart';
import 'package:desk_droid/features/intent_dispatcher/presentation/widgets/intent_presets_bar.dart';
import 'package:desk_droid/features/intent_dispatcher/presentation/widgets/intent_status_banner.dart';

/// Modal dialog for configuring and firing Android Intents, Deep Links, and Extras.
class IntentDispatcherDialog extends StatefulWidget {
  const IntentDispatcherDialog({required this.deviceSerial, super.key});

  final String deviceSerial;

  /// Shows the Intent Dispatcher dialog.
  static Future<void> show(BuildContext context, String deviceSerial) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => BlocProvider<IntentDispatcherCubit>(
        create: (_) =>
            IntentDispatcherCubit(repository: sl<IntentRepository>()),
        child: IntentDispatcherDialog(deviceSerial: deviceSerial),
      ),
    );
  }

  @override
  State<IntentDispatcherDialog> createState() => _IntentDispatcherDialogState();
}

class _IntentDispatcherDialogState extends State<IntentDispatcherDialog> {
  final _uriController = TextEditingController(text: 'https://flutter.dev');
  final _actionController = TextEditingController(
    text: IntentRequestEntity.defaultAction,
  );
  final _packageController = TextEditingController();
  final _componentController = TextEditingController();
  Map<String, dynamic> _extras = {};

  @override
  void dispose() {
    _uriController.dispose();
    _actionController.dispose();
    _packageController.dispose();
    _componentController.dispose();
    super.dispose();
  }

  void _applyPreset(IntentPreset preset) {
    setState(() {
      _actionController.text = preset.action;
      _uriController.text = preset.dataUri;
    });
  }

  void _dispatch(BuildContext context) {
    final request = IntentRequestEntity(
      action: _actionController.text.trim(),
      dataUri: _uriController.text.trim().isNotEmpty
          ? _uriController.text.trim()
          : null,
      packageName: _packageController.text.trim().isNotEmpty
          ? _packageController.text.trim()
          : null,
      componentName: _componentController.text.trim().isNotEmpty
          ? _componentController.text.trim()
          : null,
      extras: _extras,
    );

    context.read<IntentDispatcherCubit>().dispatchIntent(
      widget.deviceSerial,
      request,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final dialogWidth = (size.width * 0.85).clamp(360.0, 620.0);
    final dialogHeight = (size.height * 0.85).clamp(380.0, 660.0);

    return Dialog(
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: const BorderSide(color: AppColors.border),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: dialogHeight,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.0),
          child: Column(
            children: [
              IntentDispatcherHeader(
                deviceSerial: widget.deviceSerial,
                onClose: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quick Preset Templates',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      IntentPresetsBar(onSelectPreset: _applyPreset),
                      const SizedBox(height: 18),

                      const Text(
                        'Data URI / Deep Link URL',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _uriController,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'e.g. myapp://checkout?id=99',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 16),
                            onPressed: () => _uriController.clear(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      const Text(
                        'Intent Action',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _actionController,
                        style: const TextStyle(fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: 'e.g. android.intent.action.VIEW',
                        ),
                      ),
                      const SizedBox(height: 14),

                      IntentAdvancedOptions(
                        packageController: _packageController,
                        componentController: _componentController,
                      ),
                      const SizedBox(height: 18),

                      const Text(
                        'Intent Extras (Parameters)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      IntentExtrasEditor(
                        extras: _extras,
                        onExtrasChanged: (updated) =>
                            setState(() => _extras = updated),
                      ),

                      const SizedBox(height: 16),
                      const IntentStatusBanner(),
                    ],
                  ),
                ),
              ),
              IntentDispatcherFooter(onDispatch: () => _dispatch(context)),
            ],
          ),
        ),
      ),
    );
  }
}
