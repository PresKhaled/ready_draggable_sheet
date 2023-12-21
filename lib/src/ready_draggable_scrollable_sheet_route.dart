import 'package:flutter/material.dart';

class ReadyDraggableScrollableSheetRoute<T> extends ModalRoute<T> {
  final Widget Function(BuildContext context) builder;
  final bool withBarrier;
  final VoidCallback? onBarrierTapped;
  late final bool _maintainState;
  late final bool _opaque;
  late final String? _barrierLabel;
  late final bool _barrierDismissible;
  late final Color? _barrierColor;

  ReadyDraggableScrollableSheetRoute({
    super.settings,
    super.filter,
    super.traversalEdgeBehavior,
    required this.builder,
    bool maintainState = true,
    bool opaque = true,
    this.withBarrier = true,
    this.onBarrierTapped,
    bool barrierDismissible = true,
    String? barrierLabel,
    Color? barrierColor,
  }) {
    _maintainState = maintainState;
    _opaque = opaque;
    _barrierLabel = barrierLabel;
    _barrierDismissible = barrierDismissible;
    _barrierColor = (barrierColor ?? Colors.black54);

    if (withBarrier) assert(barrierDismissible ^ (onBarrierTapped == null));
  }

  @override
  String? get barrierLabel => _barrierLabel;

  @override
  bool get barrierDismissible => _barrierDismissible;

  @override
  Color? get barrierColor => _barrierColor;

  @override
  Widget buildModalBarrier() {
    if (!withBarrier) return const Offstage();

    late final Widget barrier;

    if (barrierColor!.alpha != 0 && !offstage) {
      // changedInternalState is called if barrierColor or offstage updates
      assert(barrierColor != barrierColor!.withOpacity(0.0));
      final Animation<Color?> color = animation!.drive(
        ColorTween(
          begin: barrierColor!.withOpacity(0.0),
          end: barrierColor, // changedInternalState is called if barrierColor updates
        ).chain(CurveTween(curve: barrierCurve)), // changedInternalState is called if barrierCurve updates
      );
      barrier = AnimatedModalBarrier(
        color: color,
        dismissible: barrierDismissible, // changedInternalState is called if barrierDismissible updates
        onDismiss: (barrierDismissible
            ? () {
                controller!.reverse();
                onBarrierTapped!();
              }
            : null),
        semanticsLabel: barrierLabel, // changedInternalState is called if barrierLabel updates
        barrierSemanticsDismissible: semanticsDismissible,
      );
    } else {
      barrier = ModalBarrier(
        dismissible: barrierDismissible, // changedInternalState is called if barrierDismissible updates
        onDismiss: (barrierDismissible ? onBarrierTapped! : null),
        semanticsLabel: barrierLabel, // changedInternalState is called if barrierLabel updates
        barrierSemanticsDismissible: semanticsDismissible,
      );
    }

    return barrier;
  }

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return builder(context);
  }

  @override
  Duration get transitionDuration => const Duration(milliseconds: 250);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 200);

  @override
  bool get maintainState => _maintainState;

  @override
  bool get opaque => _opaque;
}
