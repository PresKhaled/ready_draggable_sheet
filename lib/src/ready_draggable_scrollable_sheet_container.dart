import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/material.dart';

import '../ready_draggable_sheet.dart';
import 'components/HorizontalSeparator.dart';

class ReadyDraggableScrollableSheetContainer {
  final ReadyDraggableScrollableSheetController controller;
  // final BuildContext context;
  final double? fixedHeight;
  final Widget? header;
  final EdgeInsets contentMargin;
  final List<Flexible> content;
  final bool withBarrier;
  final bool openFromTop;

  /// 0.0..1.0
  final double initialChildSize;

  /// 0.0..1.0
  final double minChildSize;
  final bool snap;
  final Set<double>? snapSizes;
  final BorderRadius? borderRadius;
  final Map<String, Color> Function()? colors;
  final void Function()? onClosed;
  ////////////////////////////////////////
  late OverlayEntry _contentOverlayEntry;
  final ValueNotifier<bool> _contentOfOverlayEntryIsProcessed = ValueNotifier<bool>(false);

  ReadyDraggableScrollableSheetContainer({
    required this.controller,
    this.fixedHeight,
    // required this.context,
    this.header,
    this.contentMargin = EdgeInsets.zero,
    required this.content,
    this.initialChildSize = 1.0,
    this.minChildSize = 0.0,
    this.snap = true,
    this.snapSizes,
    this.openFromTop = false,
    this.withBarrier = true,
    this.borderRadius,
    this.onClosed,
    this.colors,
  })  : assert(initialChildSize >= 0.0 && initialChildSize <= 1.0),
        assert(minChildSize >= 0.0 && minChildSize <= 1.0) {
    /////////////////////////////
    Widget? horizontalSeparatorWidget, headerWidget, contentWidget;
    Size? horizontalSeparatorSize, headerSize, contentSize;
    final Widget contentContainer = Padding(
      padding: contentMargin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: content,
      ),
    );

    /// Used to calculate the sizes of the sheet parts (widgets).
    OverlayEntry getContentEntry() {
      return OverlayEntry(
        builder: (BuildContext context) {
          final GlobalKey horizontalSeparatorKey = GlobalKey(), headerKey = GlobalKey(), contentKey = GlobalKey();
          final double screenHeight = MediaQueryData.fromView(PlatformDispatcher.instance.implicitView!).size.height; // MediaQuery.of(context).size.height;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            horizontalSeparatorWidget = horizontalSeparatorKey.currentWidget!;
            horizontalSeparatorSize = (horizontalSeparatorKey.currentContext!.findRenderObject() as RenderBox).size;

            if (header != null) {
              headerWidget = headerKey.currentWidget!;
              headerSize = (headerKey.currentContext!.findRenderObject() as RenderBox).size;
            }

            contentWidget = contentKey.currentWidget!;
            contentSize = (contentKey.currentContext!.findRenderObject() as RenderBox).size;

            _contentOfOverlayEntryIsProcessed.value = true;
          });

          return SafeArea(
            child: Transform.translate(
              offset: Offset(0, screenHeight), // Hide from the visible area of the screen.
              child: Scaffold(
                body: SizedBox(
                  width: ((ReadyDraggableScrollablePreferences.getWidth_ != null) ? ReadyDraggableScrollablePreferences.getWidth_!(context) : null),
                  height: screenHeight,
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Horizontal separator (Top or bottom drag bar).
                        IntrinsicHeight(
                          key: horizontalSeparatorKey,
                          child: const HorizontalSeparator(),
                        ),
                        // Header
                        if (header != null)
                          IntrinsicHeight(
                            key: headerKey,
                            child: header!,
                          ),
                        // Content
                        Flexible(
                          key: contentKey,
                          child: contentContainer,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    _contentOverlayEntry = getContentEntry();

    void push_() {
      final ReadyDraggableScrollableSheetRoute route = ReadyDraggableScrollableSheetRoute(
        settings: RouteSettings(name: controller.routeName),
        opaque: false,
        builder: (BuildContext context) {
          double sheetHeight = 0.0;

          // - All (_Size) equals null when [fixedHeight] is set -

          if (horizontalSeparatorSize != null) {
            sheetHeight += horizontalSeparatorSize!.height;
          }
          if (headerSize != null) {
            sheetHeight += headerSize!.height;
          }
          if (contentSize != null) {
            sheetHeight += contentSize!.height;
          }

          final Widget horizontalSeparator = (horizontalSeparatorWidget ?? const HorizontalSeparator());

          return ReadyDraggableScrollableSheet(
            controller: controller,
            width: ((ReadyDraggableScrollablePreferences.getWidth_ != null) ? ReadyDraggableScrollablePreferences.getWidth_!(context) : null),
            height: (fixedHeight ?? sheetHeight),
            builder: (BuildContext context, ScrollController scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                child: RotatedBox(
                  quarterTurns: (openFromTop ? 2 : 0),
                  child: SizedBox(
                    height: fixedHeight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: ((fixedHeight == null) ? MainAxisSize.min : MainAxisSize.max), // Shrink/Fill
                      children: [
                        // Horizontal separator.
                        if (!openFromTop) horizontalSeparator,

                        // Header
                        if (headerWidget != null) headerWidget!,

                        // Content
                        (contentWidget ??
                            Expanded(
                              child: contentContainer,
                            )),

                        // Bottom drag bar.
                        if (openFromTop) horizontalSeparator,
                      ],
                    ),
                  ),
                ),
              );
            },
            initialChildSize: initialChildSize,
            minChildSize: minChildSize,
            snap: snap,
            snapSizes: snapSizes,
            openFromTop: openFromTop,
            borderRadius: borderRadius,
            colors: colors,
            onClosed: () {
              if (onClosed != null) onClosed!();
            },
          );
        },
        withBarrier: withBarrier,
        onBarrierTapped: () => controller.close(),
      );

      controller.associateRoute = route; // Mandatory

      Navigator.of(
        ReadyDraggableScrollablePreferences.contextReference_!.value,
      ).push(route);
    }

    void open_() {
      late final VoidCallback listener;

      listener = () {
        if (_contentOfOverlayEntryIsProcessed.value) {
          _contentOverlayEntry.remove();

          push_();

          _contentOfOverlayEntryIsProcessed.removeListener(listener);
          _contentOfOverlayEntryIsProcessed.value = false;
        }
      };

      if (fixedHeight == null) {
        _contentOfOverlayEntryIsProcessed.addListener(listener);

        _contentOverlayEntry = getContentEntry();

        Overlay.of(
          ReadyDraggableScrollablePreferences.contextReference_!.value,
        ).insert(_contentOverlayEntry);
      } else {
        push_();
      }
    }

    controller.statusOfSheet.addListener(() {
      final bool statusOfSheet = controller.statusOfSheet.value;

      // Open
      if (statusOfSheet) {
        open_();
      } else {
        // Close
        if (_contentOverlayEntry.mounted) {
          _contentOverlayEntry.dispose();
        }
      }
    });
  }

  Future<void> dispose() async {
    return;

    await controller.maybeClose(
      immediately: true,
    );

    // _overlayEntry.dispose();
    controller.dispose();
  }
}
