import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Reads an optional provider from the widget tree.
extension OptionalReadContext on BuildContext {
  /// Returns the nearest [T] provided above this context, or `null` when the
  /// widget is mounted in a subtree that does not provide [T].
  ///
  /// Only [ProviderNotFoundException] is handled; any other error propagates.
  T? tryRead<T>() {
    try {
      return read<T>();
    } on ProviderNotFoundException {
      return null;
    }
  }
}
