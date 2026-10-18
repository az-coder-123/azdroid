import 'package:equatable/equatable.dart';

/// Mirroring choices the user makes once and expects to be remembered.
class MirroringPreferences extends Equatable {
  const MirroringPreferences({this.stayAwake = defaultStayAwake});

  /// Default for [stayAwake]: a mirrored phone that falls asleep looks like
  /// a frozen app, so it stays awake unless the user turns this off.
  static const bool defaultStayAwake = true;

  /// Keep the phone awake while it is mirrored; its own settings come back
  /// when mirroring stops.
  final bool stayAwake;

  MirroringPreferences copyWith({bool? stayAwake}) =>
      MirroringPreferences(stayAwake: stayAwake ?? this.stayAwake);

  @override
  List<Object?> get props => [stayAwake];
}
