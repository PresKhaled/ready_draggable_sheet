import 'package:flutter/material.dart';
import 'package:ready_draggable_sheet/src/ready_draggable_scrollable_sheet.dart';

import '../ready_draggable_sheet.dart';
import 'components/RHorizontalSeparator.dart';

class ReadyDraggableScrollableSheetContainer {
  final ReadyDraggableScrollableSheetController controller;
  final BuildContext context;
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
  final GlobalKey _horizontalSeparatorKey = GlobalKey(), _headerKey = GlobalKey(), _contentKey = GlobalKey();

  ReadyDraggableScrollableSheetContainer({
    required this.controller,
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
    // Used to calculate the sizes of the sheet parts (widgets).
    _overlayEntry = OverlayEntry(
      builder: (BuildContext context) {
        final double screenHeight = MediaQuery.of(context).size.height;

        WidgetsBinding.instance.addPostFrameCallback((_) {
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
                        key: _horizontalSeparatorKey,
                        child: const RHorizontalSeparator(),
                      ),
                      // Header
                      if (header != null)
                        IntrinsicHeight(
                          key: _headerKey,
                          child: header!,
                        ),
                      // Content
                      Flexible(
                        key: _contentKey,
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

    void open_() {
      late final VoidCallback listener;

      listener = () {
        if (_contentOfOverlayEntryIsProcessed.value) {
          _overlayEntry.remove();
          // _overlayEntry.dispose();

          final ReadyDraggableScrollableSheetRoute route = ReadyDraggableScrollableSheetRoute(
            settings: RouteSettings(name: controller.routeName),
            builder: (BuildContext context) {
              double sheetHeight = 0.0;

              sheetHeight += (_horizontalSeparatorKey.currentContext!.findRenderObject() as RenderBox).size.height;

              if (_headerKey.currentWidget != null) {
                sheetHeight += (_headerKey.currentContext!.findRenderObject() as RenderBox).size.height;
              }

              sheetHeight += (_contentKey.currentContext!.findRenderObject() as RenderBox).size.height;

              return ReadyDraggableScrollableSheet(
                controller: controller,
                height: sheetHeight,
                builder: (BuildContext context, ScrollController scrollController) {
                  return SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Horizontal separator.
                        if (!openFromTop) _horizontalSeparatorKey.currentWidget!,

                        // Header
                        if (header != null) _headerKey.currentWidget!,

                        // Content
                        _contentKey.currentWidget!,

                        // Bottom drag bar.
                        if (openFromTop) _horizontalSeparatorKey.currentWidget!,
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

          Navigator.of(context).push(route);

          _contentOfOverlayEntryIsProcessed.removeListener(listener);
          _contentOfOverlayEntryIsProcessed.value = false;
        }
      };

      _contentOfOverlayEntryIsProcessed.addListener(listener);

      Overlay.of(context).insert(_overlayEntry);
    }

    controller.statusOfSheet.addListener(() {
      final bool statusOfSheet = controller.statusOfSheet.value;

      if (statusOfSheet) open_(); // Open
    });
  }

  Future<void> dispose() async {
    // controller.dispose();
  }
}
