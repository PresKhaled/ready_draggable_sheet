import 'dart:async';

import 'package:flutter/material.dart';

class ReadyDraggableScrollableSheetController extends ChangeNotifier {
  final String? label;
  final String? routeName;
  final ValueNotifier<DraggableScrollableController?> draggableScrollableController = ValueNotifier<DraggableScrollableController?>(null);
  final ValueNotifier<double?> currentSheetPixels = ValueNotifier<double?>(null);
  final ValueNotifier<bool?> sheetIsBeingOpened = ValueNotifier<bool?>(null);
  final ValueNotifier<bool?> sheetIsBeingClosed = ValueNotifier<bool?>(null);
  final ValueNotifier<bool> sheetClosingSignal = ValueNotifier<bool>(false);
  final ValueNotifier<Route?> _associatedRoute = ValueNotifier<Route?>(null);
  final ValueNotifier<bool> _statusOfSheet = ValueNotifier<bool>(false);
  bool _animating = false;
  bool _disposed = false;

  ReadyDraggableScrollableSheetController({
    this.label,
    this.routeName,
  });

  ValueNotifier<bool> get statusOfSheet => _statusOfSheet;
  bool get attached => statusOfSheet.hasListeners;
  bool get open_ => _statusOfSheet.value;

  set associateRoute(Route? route) => _associatedRoute.value = route;

  Future<bool> open() async {
    _ensureNotDisposed();

    final Completer<bool> completer = Completer();
    final bool opened = _statusOfSheet.value;

    if (!opened) {
      late final VoidCallback listener;

      listener = () {
        if (sheetIsBeingOpened.value == false) {
          completer.complete(true); // Opened

          sheetIsBeingOpened.removeListener(listener);
        }
      };

      sheetIsBeingOpened.addListener(listener);
      _statusOfSheet.value = true;
      notifyListeners();

      return await completer.future;
    }

    throw Exception('The [RDraggableBottomSheet] is already opened.');
  }

  Future<bool> animateTo(double pageFraction) async {
    _ensureNotDisposed();

    if (!open_) {
      throw Exception('The [ReadyDraggableScrollableSheet#$label] must be open to use this method.');
    }

    if (draggableScrollableController.value == null || !(draggableScrollableController.value!.isAttached)) {
      return false; // Signal
    }

    if (_animating) return false; // Signal

    _animating = true;

    await draggableScrollableController.value!.animateTo(
      pageFraction,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );

    _animating = false;

    return true; // Signal
  }

  Future<bool> close(
    BuildContext context, {
    bool immediately = false,
  }) async {
    _ensureNotDisposed();

    final Route? associatedRoute = _associatedRoute.value;

    if (associatedRoute == null) {
      throw Exception('The [ReadyDraggableScrollableSheet#$label] must be associated with a route by executing [associateRoute()] to close.');
    }

    final Completer<bool> completer = Completer();
    final bool opened = _statusOfSheet.value;

    if (opened) {
      if (!immediately) {
        late final VoidCallback listener;

        listener = () {
          if (sheetIsBeingClosed.value == false) {
            completer.complete(true); // Closed

            sheetIsBeingClosed.removeListener(listener);
          }
        };

        sheetIsBeingClosed.addListener(listener);

        sheetClosingSignal.value = true;

        await completer.future;
      }

      if (context.mounted) {
        Navigator.of(context).removeRoute(
          associatedRoute,
        );
      }

      _statusOfSheet.value = false;
      sheetClosingSignal.value = false;
      sheetIsBeingClosed.value = false;

      return true; // Signal
    }

    throw Exception('The [ReadyDraggableScrollableSheet#$label] must be open to be closed.');
  }

  Future<bool> maybeClose(
    BuildContext context, {
    bool immediately = false,
  }) async {
    _ensureNotDisposed();

    if (open_) {
      return await close(
        context,
        immediately: immediately,
      );
    }

    return false;
  }

  void _ensureNotDisposed() {
    if (_disposed) throw Exception('This controller cannot be used after [dispose()] has been performed.');
  }

  @override
  void dispose() {
    super.dispose();

    _disposed = true;

    sheetIsBeingOpened.value = null;
    sheetIsBeingClosed.value = null;
    draggableScrollableController.value?.dispose();
    draggableScrollableController.value = null;
  }
}
