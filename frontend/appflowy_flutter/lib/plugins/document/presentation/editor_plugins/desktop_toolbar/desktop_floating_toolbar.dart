import 'package:appflowy/plugins/document/presentation/editor_plugins/base/toolbar_extension.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

import 'selection_extent_rect.dart';
import 'toolbar_animation.dart';

class DesktopFloatingToolbar extends StatefulWidget {
  const DesktopFloatingToolbar({
    super.key,
    required this.editorState,
    required this.child,
    required this.onDismiss,
    this.enableAnimation = true,
  });

  final EditorState editorState;
  final Widget child;
  final VoidCallback onDismiss;
  final bool enableAnimation;

  @override
  State<DesktopFloatingToolbar> createState() => _DesktopFloatingToolbarState();
}

class _DesktopFloatingToolbarState extends State<DesktopFloatingToolbar> {
  EditorState get editorState => widget.editorState;

  _Position? position;
  final toolbarController = getIt<FloatingToolbarController>();

  @override
  void initState() {
    super.initState();
    final selection = editorState.selection;
    if (selection == null || selection.isCollapsed) {
      return;
    }
    toolbarController._addCallback(dismiss);
    // Anchor to the selection's extent (where the user's cursor actually
    // is right now), not its start — using selectionRects().first here
    // used to always pick the start, regardless of which direction the
    // user dragged, so the toolbar appeared back where the selection began
    // instead of near where the user currently is (most noticeable when
    // the selection requires scrolling).
    //
    // FIXED (2026-07-14, confirmed via a widget test that pumps this
    // widget for real: desktop_floating_toolbar_test.dart): the bug
    // wasn't in selectionExtentRect's math, it was a timing issue. This
    // widget is recreated inside a fresh OverlayEntry whenever the outer
    // FloatingToolbar's scroll-offset listener fires, using a
    // Duration.zero (synchronous) debounce — so a scroll event can
    // recreate this widget in the very same frame the scroll happens.
    // initState() runs during that frame's BUILD phase, which happens
    // BEFORE its LAYOUT phase — so reading render-object geometry
    // (selectionExtentRect -> localToGlobal) synchronously here reads
    // whatever layout was left over from the PREVIOUS frame, not the
    // freshly-scrolled position. Deferring to a post-frame callback reads
    // it only after this frame's layout has actually settled.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final extentRect = selectionExtentRect(editorState);
      if (extentRect == null) return;
      setState(() {
        position = calculateSelectionMenuOffset(extentRect);
      });
    });
  }

  @override
  void dispose() {
    toolbarController._removeCallback(dismiss);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (position == null) return Container();
    return Positioned(
      left: position!.left,
      top: position!.top,
      right: position!.right,
      child: widget.enableAnimation
          ? ToolbarAnimationWidget(child: widget.child)
          : widget.child,
    );
  }

  void dismiss() {
    widget.onDismiss.call();
  }

  _Position calculateSelectionMenuOffset(
    Rect rect,
  ) {
    const toolbarHeight = 40, topLimit = toolbarHeight + 8;
    final bool isLongMenu = onlyShowInSingleSelectionAndTextType(editorState);
    final editorOffset =
        editorState.renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
    final editorSize = editorState.renderBox?.size ?? Size.zero;
    final menuWidth =
        isLongMenu ? (isNarrowWindow(editorState) ? 490.0 : 660.0) : 420.0;
    final editorRect = editorOffset & editorSize;
    final left = rect.left, leftStart = 50;
    final top =
        rect.top < topLimit ? rect.bottom + topLimit : rect.top - topLimit;
    if (left + menuWidth > editorRect.right) {
      return _Position(
        editorRect.right - menuWidth,
        top,
        null,
      );
    } else if (rect.left - leftStart > 0) {
      return _Position(rect.left - leftStart, top, null);
    } else {
      return _Position(rect.left, top, null);
    }
  }
}

class _Position {
  _Position(this.left, this.top, this.right);

  final double? left;
  final double? top;
  final double? right;
}

class FloatingToolbarController {
  final Set<VoidCallback> _dismissCallbacks = {};
  final Set<VoidCallback> _displayListeners = {};

  void _addCallback(VoidCallback callback) {
    _dismissCallbacks.add(callback);
    for (final listener in Set.of(_displayListeners)) {
      listener.call();
    }
  }

  void _removeCallback(VoidCallback callback) =>
      _dismissCallbacks.remove(callback);

  bool get isToolbarShowing => _dismissCallbacks.isNotEmpty;

  void addDisplayListener(VoidCallback listener) =>
      _displayListeners.add(listener);

  void removeDisplayListener(VoidCallback listener) =>
      _displayListeners.remove(listener);

  void hideToolbar() {
    if (_dismissCallbacks.isEmpty) return;
    for (final callback in _dismissCallbacks) {
      callback.call();
    }
  }
}
