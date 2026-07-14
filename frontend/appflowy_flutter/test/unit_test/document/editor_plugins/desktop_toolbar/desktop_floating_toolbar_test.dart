import 'package:appflowy/plugins/document/presentation/editor_plugins/desktop_toolbar/desktop_floating_toolbar.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Regression test for the floating toolbar landing at a stale position
// after a selection that requires auto-scroll to reveal.
//
// `DesktopFloatingToolbar` used to compute its position once,
// synchronously, in initState(). But initState() runs during a frame's
// BUILD phase, which happens BEFORE that same frame's LAYOUT phase. When
// this widget is (re)created in the same frame a scroll offset changes --
// exactly what happens when the outer FloatingToolbar's scroll-change
// handler tears down and recreates it via a Duration.zero (synchronous)
// debounce -- reading render-object geometry at that point reads whatever
// layout was left over from the PREVIOUS frame, since the scrolled
// content hasn't been laid out at its new position yet this frame.
//
// Mounted via a real root OverlayEntry (matching how the app's outer
// FloatingToolbar actually displays DesktopFloatingToolbar), not a
// hand-rolled Stack -- Positioned's left/top read GLOBAL coordinates from
// selectionExtentRect, which is only meaningful inside a root overlay.

const _selectedPath = [25];

void main() {
  setUp(() {
    getIt.registerSingleton<FloatingToolbarController>(
      FloatingToolbarController(),
    );
  });

  tearDown(() {
    getIt.unregister<FloatingToolbarController>();
  });

  testWidgets(
    'toolbar lands at the settled position, not a stale pre-scroll one, '
    'when mounted in the same frame a scroll offset changes',
    (tester) async {
      final document = Document(
        root: pageNode(
          children: [
            for (var i = 0; i < 30; i++) paragraphNode(text: 'paragraph $i'),
          ],
        ),
      );
      final editorState = EditorState(document: document);
      // Default (shrinkWrap: false) -- matches production desktop exactly:
      // a ScrollablePositionedList, scrolled via editorScrollController's
      // own jumpTo(), not a manually-attached ScrollController.
      final editorScrollController = EditorScrollController(
        editorState: editorState,
      );

      // A selection far down the document -- off-screen in the 300px
      // viewport below until something scrolls it into view.
      editorState.selection = Selection.single(
        path: _selectedPath,
        startOffset: 0,
        endOffset: 9,
      );

      final navigatorKey = GlobalKey<NavigatorState>();
      OverlayEntry? toolbarEntry;

      void mountToolbar() {
        toolbarEntry?.remove();
        toolbarEntry = OverlayEntry(
          builder: (context) => DesktopFloatingToolbar(
            editorState: editorState,
            onDismiss: () {},
            enableAnimation: false,
            child: Container(
              key: const Key('toolbarChild'),
              width: 40,
              height: 40,
              color: Colors.blue,
            ),
          ),
        );
        navigatorKey.currentState!.overlay!.insert(toolbarEntry!);
      }

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: Scaffold(
            body: SizedBox(
              height: 300,
              child: AppFlowyEditor(
                editorState: editorState,
                editorScrollController: editorScrollController,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to reveal the selection AND mount the toolbar in the same
      // synchronous block, before any pump() -- this reproduces the same
      // ordering the real app produces when a scroll-offset change tears
      // down and recreates DesktopFloatingToolbar via the outer widget's
      // OverlayEntry teardown/rebuild cycle.
      editorScrollController.jumpTo(offset: _selectedPath.first.toDouble());
      mountToolbar();

      // One frame: build phase mounts the new DesktopFloatingToolbar;
      // layout phase then catches the scrolled content up to its new
      // position. By the end of this single pump(), layout has already
      // settled (jumpTo is instantaneous, not animated).
      await tester.pump();
      final selectable =
          editorState.document.nodeAtPath(_selectedPath)!.selectable!;
      final settledExtentRect = selectable.transformRectToGlobal(
        selectable.getCursorRectInPosition(
          Position(path: _selectedPath, offset: 9),
        )!,
      );

      // Let any deferred (post-frame-callback) position update apply.
      await tester.pumpAndSettle();

      final toolbarChildRect =
          tester.getTopLeft(find.byKey(const Key('toolbarChild')));
      expect(
        (toolbarChildRect.dy - settledExtentRect.top).abs() < 60,
        true,
        reason: 'toolbar child $toolbarChildRect should land near the '
            'settled, post-scroll selection extent $settledExtentRect '
            '(within about one line height), not a stale pre-scroll '
            'position',
      );
    },
  );
}
