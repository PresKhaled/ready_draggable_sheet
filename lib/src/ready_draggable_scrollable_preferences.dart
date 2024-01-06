import 'package:flutter/material.dart' show BuildContext, ValueNotifier;

class ReadyDraggableScrollablePreferences {
  static ValueNotifier<BuildContext>? contextReference_;
  static double Function(BuildContext context)? getWidth_;

  static final ReadyDraggableScrollablePreferences _instance = ReadyDraggableScrollablePreferences._();
  factory ReadyDraggableScrollablePreferences({
    ValueNotifier<BuildContext>? contextReference,
    double Function(BuildContext context)? getWidth,
  }) {
    contextReference_ ??= contextReference;
    getWidth_ ??= getWidth;

    assert(contextReference_ != null);

    return _instance;
  }
  ReadyDraggableScrollablePreferences._();
}
