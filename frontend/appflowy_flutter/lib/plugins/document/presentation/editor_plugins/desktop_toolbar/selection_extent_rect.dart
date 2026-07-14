import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

/// Returns the on-screen [Rect] at the current selection's *extent* — the
/// position the user's cursor is actually at right now, regardless of
/// which direction they dragged from.
///
/// Resolves directly from `selection.end`'s [Position] (mirroring how
/// [EditorState.selectionRects] itself resolves a collapsed selection's
/// rect), rather than indexing into [EditorState.selectionRects]'s
/// returned list. That list's ordering is only anchor-to-extent at the
/// *inter-node* level (via [EditorState.getNodesInSelection]'s reversal
/// logic) — rects *within* a single node come from Flutter's own
/// `RenderParagraph.getBoxesForSelection`, which is always in visual/text
/// order. So for a selection that starts and ends in the same block but
/// was dragged backward, indexing `.first`/`.last` would still pick the
/// wrong rect. Resolving directly from the `Position` sidesteps that.
Rect? selectionExtentRect(EditorState editorState) {
  final selection = editorState.selection;
  if (selection == null) {
    return null;
  }
  final selectable = editorState.getNodeAtPath(selection.end.path)?.selectable;
  if (selectable == null) {
    return null;
  }
  final rect = selectable.getCursorRectInPosition(
    selection.end,
    shiftWithBaseOffset: true,
  );
  if (rect == null) {
    return null;
  }
  return selectable.transformRectToGlobal(rect, shiftWithBaseOffset: true);
}
