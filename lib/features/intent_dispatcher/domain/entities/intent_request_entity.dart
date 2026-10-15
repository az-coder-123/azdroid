import 'package:equatable/equatable.dart';

/// Represents an Android Intent dispatch request with action, data URI, component, and extras.
class IntentRequestEntity extends Equatable {
  const IntentRequestEntity({
    this.action = defaultAction,
    this.dataUri,
    this.packageName,
    this.componentName,
    this.category,
    this.extras = const {},
  });

  /// Standard Android action to display data to the user.
  static const String defaultAction = 'android.intent.action.VIEW';

  /// Intent action (e.g. android.intent.action.VIEW, android.intent.action.MAIN).
  final String action;

  /// Explicit URI (e.g. https://example.com, myapp://checkout).
  final String? dataUri;

  /// Optional target package name to limit intent resolution.
  final String? packageName;

  /// Optional explicit component name (e.g. com.example/.MainActivity).
  final String? componentName;

  /// Optional intent category (e.g. android.intent.category.BROWSABLE).
  final String? category;

  /// Key-value extras passed to the target Activity (String, int, or bool values).
  final Map<String, dynamic> extras;

  IntentRequestEntity copyWith({
    String? action,
    String? dataUri,
    String? packageName,
    String? componentName,
    String? category,
    Map<String, dynamic>? extras,
  }) {
    return IntentRequestEntity(
      action: action ?? this.action,
      dataUri: dataUri ?? this.dataUri,
      packageName: packageName ?? this.packageName,
      componentName: componentName ?? this.componentName,
      category: category ?? this.category,
      extras: extras ?? this.extras,
    );
  }

  @override
  List<Object?> get props => [
    action,
    dataUri,
    packageName,
    componentName,
    category,
    extras,
  ];
}
