import 'package:desk_droid/core/extensions/optional_read_extension.dart';
import 'package:desk_droid/features/discovery/presentation/cubit/host_context_cubit.dart';
import 'package:desk_droid/features/discovery/presentation/cubit/host_context_state.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Rebuilds with the nearest [HostContextCubit] state.
///
/// Falls back to an empty [HostContextState] when no cubit is provided, so
/// discovery widgets stay usable in isolation (previews, widget tests).
class HostContextBuilder extends StatelessWidget {
  const HostContextBuilder({required this.builder, super.key});

  final Widget Function(BuildContext context, HostContextState state) builder;

  @override
  Widget build(BuildContext context) {
    final cubit = context.tryRead<HostContextCubit>();
    if (cubit == null) return builder(context, const HostContextState());
    return BlocBuilder<HostContextCubit, HostContextState>(
      bloc: cubit,
      builder: builder,
    );
  }
}
