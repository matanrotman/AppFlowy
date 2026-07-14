import 'package:appflowy/plugins/document/presentation/editor_plugins/desktop_toolbar/selection_extent_rect.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Regression test for the floating selection toolbar appearing at the
// selection's *start* instead of near where the user's cursor currently
// is. `DesktopFloatingToolbar` used to anchor on
// `editorState.selectionRects().first`, which is always the rect at the
// selection's start regardless of which direction the user dragged --
// most noticeable when the selection spans off-screen and requires
// scrolling to reach the toolbar. `selectionExtentRect` fixes this by
// resolving the rect directly from `selection.end`'s Position instead.

Future<EditorState> _pumpThreeParagraphEditor(WidgetTester tester) async {
  final document = Document(
    root: pageNode(
      children: [
        paragraphNode(text: 'first paragraph'),
        paragraphNode(text: 'second paragraph'),
        paragraphNode(text: 'third paragraph'),
      ],
    ),
  );
  final editorState = EditorState(document: document);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AppFlowyEditor(editorState: editorState),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return editorState;
}

void main() {
  group('selectionExtentRect', () {
    testWidgets('returns null when there is no selection', (tester) async {
      final editorState = await _pumpThreeParagraphEditor(tester);
      expect(selectionExtentRect(editorState), isNull);
    });

    testWidgets(
        'forward selection (dragged top-to-bottom): extent is near the LAST paragraph',
        (tester) async {
      final editorState = await _pumpThreeParagraphEditor(tester);

      editorState.selection = Selection(
        start: Position(path: [0], offset: 0),
        end: Position(path: [2], offset: 5),
      );
      await tester.pumpAndSettle();

      final extentRect = selectionExtentRect(editorState);
      expect(extentRect, isNotNull);

      final firstParagraphRect = editorState.document
          .nodeAtPath([0])!
          .selectable!
          .transformRectToGlobal(
            editorState.document
                .nodeAtPath([0])!
                .selectable!
                .getCursorRectInPosition(Position(path: [0], offset: 0))!,
          );
      final lastParagraphRect = editorState.document
          .nodeAtPath([2])!
          .selectable!
          .transformRectToGlobal(
            editorState.document
                .nodeAtPath([2])!
                .selectable!
                .getCursorRectInPosition(Position(path: [2], offset: 5))!,
          );

      // The extent rect should sit at the same vertical position as the
      // LAST paragraph (where the drag ended), not the first.
      expect(
        (extentRect!.top - lastParagraphRect.top).abs() <
            (extentRect.top - firstParagraphRect.top).abs(),
        true,
        reason: 'extent rect $extentRect should be near the last paragraph '
            '$lastParagraphRect, not the first $firstParagraphRect',
      );
    });

    testWidgets(
        'backward selection (dragged bottom-to-top): extent is near the FIRST paragraph',
        (tester) async {
      final editorState = await _pumpThreeParagraphEditor(tester);

      // Raw start/end reflect drag order, not document order: the user
      // began dragging at the last paragraph and ended at the first.
      editorState.selection = Selection(
        start: Position(path: [2], offset: 5),
        end: Position(path: [0], offset: 0),
      );
      await tester.pumpAndSettle();

      final extentRect = selectionExtentRect(editorState);
      expect(extentRect, isNotNull);

      final firstParagraphRect = editorState.document
          .nodeAtPath([0])!
          .selectable!
          .transformRectToGlobal(
            editorState.document
                .nodeAtPath([0])!
                .selectable!
                .getCursorRectInPosition(Position(path: [0], offset: 0))!,
          );
      final lastParagraphRect = editorState.document
          .nodeAtPath([2])!
          .selectable!
          .transformRectToGlobal(
            editorState.document
                .nodeAtPath([2])!
                .selectable!
                .getCursorRectInPosition(Position(path: [2], offset: 5))!,
          );

      // The extent rect should sit at the same vertical position as the
      // FIRST paragraph (where the backward drag ended) -- this is exactly
      // the case a naive `selectionRects().first` would get wrong, since
      // that always picks the rect at the raw/document start regardless of
      // drag direction... except `selectionRects()` itself already
      // reorders for inter-node selections, so what this really guards
      // against is a regression to indexing instead of resolving from
      // `selection.end` directly.
      expect(
        (extentRect!.top - firstParagraphRect.top).abs() <
            (extentRect.top - lastParagraphRect.top).abs(),
        true,
        reason: 'extent rect $extentRect should be near the first paragraph '
            '$firstParagraphRect (where the backward drag ended), not the '
            'last $lastParagraphRect',
      );
    });
  });
}
