import 'package:flutter/material.dart';
import 'package:ready_draggable_sheet/src/ready_draggable_scrollable_sheet.dart';
import 'dart:ui' show PlatformDispatcher;
import '../ready_draggable_sheet.dart';
import 'components/RHorizontalSeparator.dart';

class ReadyDraggableScrollableSheetContainer {
  final ReadyDraggableScrollableSheetController controller;
  final BuildContext context;
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
  late final OverlayEntry _overlayEntry;
  final ValueNotifier<bool> _contentOfOverlayEntryIsProcessed = ValueNotifier<bool>(false);

  ReadyDraggableScrollableSheetContainer({
    required this.controller,
    this.fixedHeight,
    required this.context,
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

    // Used to calculate the sizes of the sheet parts (widgets).
    _overlayEntry = OverlayEntry(
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
                        child: const RHorizontalSeparator(),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: content,
                        ),
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

    void push_() {
      final ReadyDraggableScrollableSheetRoute route = ReadyDraggableScrollableSheetRoute(
        settings: RouteSettings(name: controller.routeName),
        opaque: false,
        builder: (BuildContext context) {
          double sheetHeight = 0.0;

          if (horizontalSeparatorSize != null) {
            sheetHeight += horizontalSeparatorSize!.height;
          }
          if (headerSize != null) {
            sheetHeight += headerSize!.height;
          }
          if (contentSize != null) {
            sheetHeight += contentSize!.height;
          }

          return ReadyDraggableScrollableSheet(
            controller: controller,
            height: (fixedHeight ?? sheetHeight),
            builder: (BuildContext context, ScrollController scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Horizontal separator.
                    if (!openFromTop) horizontalSeparatorWidget!,

                    // Header
                    if (headerWidget != null) headerWidget!,

                    // Content
                    contentWidget!,

                    // Bottom drag bar.
                    if (openFromTop) horizontalSeparatorWidget!,
                  ],
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
        onBarrierTapped: () => controller.close(context),
      );

      controller.associateRoute = route; // Mandatory

      Navigator.of(context).push(route);
    }

    void open_() {
      late final VoidCallback listener;

      listener = () {
        if (_contentOfOverlayEntryIsProcessed.value) {
          _overlayEntry.remove();

          push_();

          _contentOfOverlayEntryIsProcessed.removeListener(listener);
          _contentOfOverlayEntryIsProcessed.value = false;
        }
      };

      if (fixedHeight == null) {
        _contentOfOverlayEntryIsProcessed.addListener(listener);

        Overlay.of(context).insert(_overlayEntry);
      } else {
        push_();
      }
    }

    controller.statusOfSheet.addListener(() {
      final bool statusOfSheet = controller.statusOfSheet.value;

      if (statusOfSheet) open_(); // Open
    });
  }

  Future<void> dispose() async {
    if (context.mounted) {
      await controller.maybeClose(context, immediately: true,);
    }

    _overlayEntry.dispose();
    controller.dispose();
  }
}
