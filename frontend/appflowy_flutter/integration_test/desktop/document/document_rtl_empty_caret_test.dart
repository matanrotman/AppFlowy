import 'package:appflowy/plugins/document/application/document_appearance_cubit.dart';
import 'package:appflowy/plugins/document/presentation/editor_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/util.dart';

/// Real-macOS-render regression for the empty RTL line "very far cursor" bug.
///
/// Run on the real target, never headless `flutter test`.
///
/// Reproduces the user's exact scenario: document default text direction = RTL
/// (Settings > Workspace). Every line — including empty ones and the first
/// line — is RTL and shows the LTR English "Type '/'…" placeholder. The caret
/// used to render at the LEFT end of that hint instead of the line's RTL start
/// (the right).
///
/// IMPORTANT: measures the actual rendered [Cursor] widget's global rect, NOT
/// editorState.selectionRects() — the latter's transformRectToGlobal
/// mis-reports the caret for this shrink-wrapped RTL block, hiding the bug.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // The caret widget ([Cursor]) is in appflowy_editor/src and not exported,
  // so match it by runtime type name.
  final cursorFinder =
      find.byWidgetPredicate((w) => w.runtimeType.toString() == 'Cursor');

  double caretLeft(WidgetTester tester) =>
      tester.getRect(cursorFinder.first).left;

  group('RTL empty-line caret (rtl default direction)', () {
    testWidgets('empty first line caret sits where RTL typing lands',
        (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      // Match the user's setting: default document direction = RTL.
      final ctx = tester.element(find.byType(WidgetsApp).first);
      await ctx.read<DocumentAppearanceCubit>().syncDefaultTextDirection('rtl');
      await tester.pumpAndSettle();

      await tester.createNewPageWithNameUnderParent(name: 'rtl_default_doc');
      await tester.pumpAndSettle();

      // First line is empty + RTL, showing the English "Type '/'…" hint.
      await tester.editor.tapLineOfEditorAt(0);
      await tester.pumpAndSettle();
      expect(cursorFinder, findsWidgets, reason: 'expected a caret on screen');
      final emptyCaret = caretLeft(tester);

      // Type one Hebrew character; its caret lands at the RTL start (right).
      await tester.ime.insertText('א');
      await tester.pumpAndSettle();
      final typedCaret = caretLeft(tester);

      final editorRect = tester.getRect(find.byType(AppFlowyEditorPage));
      final diff = (emptyCaret - typedCaret).abs();
      debugPrint('RTLDIAG emptyCaret=${emptyCaret.toStringAsFixed(1)} '
          'typedCaret=${typedCaret.toStringAsFixed(1)} '
          'diff=${diff.toStringAsFixed(1)} '
          'editorL=${editorRect.left.toStringAsFixed(1)} '
          'editorR=${editorRect.right.toStringAsFixed(1)}');

      // (1) No jump: the empty-line caret must sit within ~one glyph of where
      // typing actually lands. Reverting either fix breaks this (empty and
      // typed diverge by a placeholder-width).
      expect(
        diff < 40,
        true,
        reason: 'empty RTL caret $emptyCaret should be near the post-typing '
            'caret $typedCaret (within ~one character), not stranded to the '
            'left of the English placeholder',
      );

      // (2) Correct side: both must be near the content-area RIGHT edge (the
      // RTL start), not stranded on the left. This guards the "both regress
      // together" case that (1) alone would miss — pre-fix both sat a
      // placeholder-width (~300px) left of the right edge.
      final rightThreshold = editorRect.left + editorRect.width * 0.75;
      expect(
        typedCaret > rightThreshold && emptyCaret > rightThreshold,
        true,
        reason: 'RTL carets (empty=$emptyCaret, typed=$typedCaret) should be '
            'in the right quarter of the editor (> $rightThreshold), where '
            'RTL text begins — not stranded left of the content edge',
      );
    });
  });
}
