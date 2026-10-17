import 'package:desk_droid/core/extensions/optional_read_extension.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _CounterCubit extends Cubit<int> {
  _CounterCubit() : super(0);
}

void main() {
  group('OptionalReadContext.tryRead', () {
    testWidgets('returns the provided instance', (tester) async {
      final cubit = _CounterCubit();
      _CounterCubit? found;

      await tester.pumpWidget(
        BlocProvider.value(
          value: cubit,
          child: Builder(
            builder: (context) {
              found = context.tryRead<_CounterCubit>();
              return const SizedBox();
            },
          ),
        ),
      );

      expect(found, same(cubit));
      await cubit.close();
    });

    testWidgets('returns null when nothing is provided', (tester) async {
      _CounterCubit? found = _CounterCubit();

      await tester.pumpWidget(
        Builder(
          builder: (context) {
            found = context.tryRead<_CounterCubit>();
            return const SizedBox();
          },
        ),
      );

      expect(found, isNull);
    });
  });
}
