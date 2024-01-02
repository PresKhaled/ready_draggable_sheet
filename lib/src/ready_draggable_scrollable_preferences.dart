import 'package:flutter/material.dart' show BuildContext, ValueNotifier;

class ReadyDraggableScrollablePreferences {
  static ValueNotifier<BuildContext>? contextReference_;

  static final ReadyDraggableScrollablePreferences _instance = ReadyDraggableScrollablePreferences._();
  factory ReadyDraggableScrollablePreferences({
    ValueNotifier<BuildContext>? contextReference,
  }) {
    contextReference_ ??= contextReference;

    assert(contextReference_ != null);

    return _instance;
  }
  ReadyDraggableScrollablePreferences._();
}
