import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'package:defer_pointer/defer_pointer.dart';

import '../ready_draggable_sheet.dart';

class ReadyDraggableScrollableSheet extends StatefulWidget {
  final ReadyDraggableScrollableSheetController controller;
  final double? width;
  final double? height;
  final Widget Function(BuildContext context, ScrollController scrollController) builder;

  /// 0.0..1.0
  final double initialChildSize;

  /// 0.0..1.0
  final double minChildSize;
  final bool snap;
  final Set<double>? snapSizes;
  final bool openFromTop;
  final bool withShadow;
  final bool withLinearSeparator;
  final BorderRadius? borderRadius;
  final Map<String, Color> Function()? colors;
  final VoidCallback? onClosed;

  const ReadyDraggableScrollableSheet({
    super.key,
    required this.controller,
    this.width,
    this.height,
    required this.builder,
    this.initialChildSize = 0.5,
    this.minChildSize = 0.5,
    this.snap = true,
    this.snapSizes,
    this.openFromTop = false,
    this.withShadow = true,
    this.withLinearSeparator = false,
    this.colors,
    this.borderRadius,
    this.onClosed,
  })  : assert(initialChildSize >= 0.0 && initialChildSize <= 1.0),
        assert(minChildSize >= 0.0 && minChildSize <= 1.0);

  static ReadyDraggableScrollableSheet? of(BuildContext context) {
    if (!context.mounted) return null;

    return context.findAncestorWidgetOfExactType<ReadyDraggableScrollableSheet>();
  }

  @override
  State<ReadyDraggableScrollableSheet> createState() => _ReadyDraggableScrollableSheetState();
}

class _ReadyDraggableScrollableSheetState extends State<ReadyDraggableScrollableSheet> with TickerProviderStateMixin {
  late final DraggableScrollableController draggableScrollableController = DraggableScrollableController();
  final GlobalKey _scaffoldKey = GlobalKey();
  double height = 0.0;
  late final AnimationController _animationControllerTranslate; // Open/Close
  void Function(AnimationStatus)? _animationControllerTranslateListener;
  VoidCallback? _closingSignalListener;
  bool _closing = false;
  final MediaQueryData mediaQueryData = MediaQueryData.fromView(PlatformDispatcher.instance.implicitView!);
  late final Size screenSize = mediaQueryData.size;
  late final double screenHeight = (screenSize.height - mediaQueryData.padding.top);
  final DeferredPointerHandlerLink _deferredPointerHandlerLink = DeferredPointerHandlerLink();

  // Hiding the sheet.
  Future<void> _hide() async {
    if (_closing) return;

    _closing = true;

    if (_animationControllerTranslate.isAnimating) {
      _animationControllerTranslate.stop();
    }

    await _animationControllerTranslate.reverse();

    // Mandatory signal.
    widget.controller.sheetIsBeingClosed.value = false;

    if (widget.onClosed != null) widget.onClosed!();
  }

  @override
  void initState() {
    super.initState();

    height = (widget.height ?? (screenHeight / 2));

    _animationControllerTranslate = BottomSheet.createAnimationController(this);

    // Opening and closing states.
    _animationControllerTranslateListener = (AnimationStatus status) {
      // print(status);

      if (status == AnimationStatus.forward) {
        widget.controller.sheetIsBeingOpened.value = true;
      } else if (status == AnimationStatus.reverse) {
        widget.controller.sheetIsBeingClosed.value = true;
      }

      if (status == AnimationStatus.completed) {
        widget.controller.sheetIsBeingOpened.value = false; // Complete
      } else if (status == AnimationStatus.dismissed) {
        widget.controller.sheetIsBeingClosed.value = false; // Complete
      }
    };
    _animationControllerTranslate.addStatusListener(_animationControllerTranslateListener!);

    _animationControllerTranslate.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.draggableScrollableController.value = draggableScrollableController; // Assign the local controller.

      // Listen for the closing signal from outside this widget.
      _closingSignalListener = () {
        if (widget.controller.sheetClosingSignal.value) {
          _hide();
        }
      };
      widget.controller.sheetClosingSignal.addListener(_closingSignalListener!);
    });
  }

  @override
  void dispose() {
    widget.controller.sheetClosingSignal.removeListener(_closingSignalListener!);
    _animationControllerTranslate.removeStatusListener(_animationControllerTranslateListener!);
    if (_animationControllerTranslate.isAnimating) {
      _animationControllerTranslate.stop();
    }
    _animationControllerTranslate.dispose();

    // [!_closing] = The sheet closes immediately.
    if (widget.onClosed != null && !_closing) widget.onClosed!();

    super.dispose(); // NOTE: Leave it at the end.
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvoked: (status) async {
        if (_closing || status) return; // Closing or already closed.

        if (widget.controller.attached) {
          await widget.controller.close(context);
        }
      },
      child: DeferredPointerHandler(
        link: _deferredPointerHandlerLink,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            child: SizedBox(
              width: (widget.width ?? MediaQuery.of(context).size.width),
              child: AnimatedBuilder(
                animation: _animationControllerTranslate,
                builder: (BuildContext context, Widget? child) {
                  late final double dimensionY;

                  final double currentHeight = (height * _animationControllerTranslate.value);

                  if (!widget.openFromTop) {
                    dimensionY = -currentHeight;
                  } else {
                    dimensionY = currentHeight;
                  }

                  return Transform.translate(
                    offset: Offset(0, dimensionY),
                    child: child!,
                  );
                },
                child: Transform.translate(
                  offset: Offset(
                    0,
                    (!widget.openFromTop ? height : -screenHeight), // Start after the end of the screen/Start before the start of the screen.
                  ),
                  child: RotatedBox(
                    quarterTurns: (widget.openFromTop ? 2 : 0),
                    child: SizedBox(
                      height: height,
                      child: NotificationListener<DraggableScrollableNotification>(
                        onNotification: (DraggableScrollableNotification notification) {
                          // NOTE: Do not return "true", to listen to the notifications next times the sheet is opened. (maintainState is true)

                          // TODO: Simultaneously adjusting the degree of transparency of the barrier according to the position of the sheet.

                          if (notification.depth != 0) return false;

                          widget.controller.currentSheetPixels.value = (notification.extent * height);
                          widget.controller.currentSheetPixels.notifyListeners();

                          // Close the sheet when swiping down (by the app or user) completely.
                          if ((notification.extent <= 0 || notification.extent <= precisionErrorTolerance) && !_closing) {
                            widget.controller.close(context);
                          }

                          return false;
                        },
                        child: DraggableScrollableSheet(
                          controller: draggableScrollableController,
                          initialChildSize: widget.initialChildSize,
                          minChildSize: widget.minChildSize,
                          snap: widget.snap,
                          snapSizes: (widget.snapSizes?.toList() ??
                              {
                                widget.minChildSize,
                                widget.initialChildSize,
                                1.0,
                              }.toList()),
                          builder: (BuildContext context, ScrollController scrollController) {
                            const Radius borderRadiusCorner = Radius.circular(12.0);
                            final Map<String, Color>? passedColors = ((widget.colors != null) ? widget.colors!() : null);
                            final Color foregroundColor = (passedColors?['foreground-color'] ?? themeData.colorScheme.onSurfaceVariant);

                            return DeferPointer(
                              link: _deferredPointerHandlerLink,
                              child: Material(
                                elevation: (widget.withShadow ? 5 : 0),
                                shape: RoundedRectangleBorder(
                                  side: (widget.withLinearSeparator
                                      ? BorderSide(
                                          width: 0.5,
                                          color: foregroundColor,
                                          strokeAlign: 1, // Mandatory
                                        )
                                      : BorderSide.none),
                                  borderRadius: (widget.borderRadius ??
                                      (!widget.openFromTop
                                          ? const BorderRadius.only(
                                              topRight: borderRadiusCorner,
                                              topLeft: borderRadiusCorner,
                                            )
                                          : const BorderRadius.only(
                                              bottomRight: borderRadiusCorner,
                                              bottomLeft: borderRadiusCorner,
                                            ))),
                                ),
                                color: (passedColors?['background-color'] ?? themeData.colorScheme.surfaceVariant),
                                child: Scaffold(
                                  key: _scaffoldKey,
                                  extendBodyBehindAppBar: true,
                                  backgroundColor: Colors.transparent,
                                  body: Theme(
                                    data: themeData.copyWith(
                                      listTileTheme: themeData.listTileTheme.copyWith(
                                        textColor: foregroundColor,
                                        iconColor: foregroundColor,
                                      ),
                                      iconButtonTheme: IconButtonThemeData(
                                        style: themeData.iconButtonTheme.style?.copyWith(
                                          foregroundColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
                                            if (states.contains(MaterialState.disabled)) return themeData.disabledColor;

                                            return foregroundColor;
                                          }),
                                        ),
                                      ),
                                    ),
                                    child: DefaultTextStyle(
                                      style: TextStyle(color: foregroundColor),
                                      child: Builder(
                                        builder: (BuildContext context) => widget.builder(context, scrollController),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
