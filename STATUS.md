# Project Status

*The current snapshot only — replace sections when they change, don't append to them. Detailed history lives in each feature's spec, under its own "Session Log."*

**Last updated:** 2026-07-15 (empty-line cursor FIXED + confirmed live; stale-build root cause found)

## Active feature
RTL/LTR support (`specs/rtl-support.md`). Phase 1 (sidebar) done and signed off. Phase 2 (document-content direction) is in good shape: auto-detect direction, bidi, block-insert menu direction, icon-margin gap, and now the **empty-line cursor** are all done.

## The big finding this session (read this first)
**Several "still broken" bugs were actually already fixed — the user was testing a STALE dock app.** The floating toolbar is the clearest case: it works in a fresh build, and was only broken in the user's installed app because that app predates the fix. This very likely explains the whole multi-session loop: **our fixes were real but never reached the app the user actually tests in.**

Two process rules that came out of it, both now essential:
1. **Verify against the REAL macOS render path, never headless `flutter test`.** Run `flutter test integration_test/desktop/document/<file>.dart -d macos`. Plain `flutter test` forces a fixed-width fake font (Ahem) that collapses RTL glyph geometry, so RTL caret/position bugs are invisible to it — this is why prior headless "fixes" went green while the app stayed broken. (It gets worse: even on the real target, `editorState.selectionRects()` mis-reports the caret for the shrink-wrapped empty RTL block — measure the actual rendered `Cursor` widget's global rect instead.)
2. **The user runs a RELEASE build; dev builds are a different workspace.** Data dirs (macOS): `flutter run` (debug) → `…/com.appflowy.appflowy.flutter/data_dev*`; a release build → `…/data*`; integration tests → a throwaway `.sandbox`. The user's real pages are in `data_beta.appflowy.cloud` (release + AppFlowy Cloud). So a `flutter run` app does NOT show their pages, and only a **release** build lands fixes on their real workspace.

## Bug status
- **Empty-line cursor ("creating a new line has a very far cursor") — FIXED, confirmed live by the user.** Root cause was the user's setting **`kDocumentAppearanceDefaultTextDirection = rtl`** (document default direction RTL). That made every empty line RTL while showing the LTR English "Type '/'…" placeholder, and two stacked bugs stranded the caret/text far left:
  1. The empty-line caret resolved to logical offset 0 of the LTR placeholder run (its *left* end). The old "correction" was a permanent no-op (it read `_renderParagraph.size.width`, a real 0.0 for empty text, before the placeholder width in a `??` chain). Fixed by SETTING the caret dx to the placeholder paragraph's own (right-aligned) width — the RTL start.
  2. Typing then "jumped left" because the invisible placeholder was kept full-width, inflating the right-aligned RTL block so real text rendered a placeholder-width left of the content edge. Fixed by collapsing the placeholder to an empty span (keeps line height, takes no width) when the line has text.
  Both fixes are in the editor fork's `appflowy_rich_text.dart`. Committed: fork `ba6c4fcb`, app `6ff1967c4`, pin resynced (no drift). Real-target regression test: `integration_test/desktop/document/document_rtl_empty_caret_test.dart`.
- **Floating selection toolbar — WORKING in current code; earlier "broken" was the stale dock app.** User confirmed it works in a fresh build. No new code needed. (The debounce-split fix from a prior session was real; it just never reached the user's stale app.)
- **Mid-character cursor in embedded dates — DEFERRED to next session** (user's choice). Deterministic repro is already encoded in the fork's `caret_bidi_test.dart` skipped test. Blocker is an *oracle* — the user needs to look at the one anomalous boundary (right after the comma in an embedded date like `20.4.26,`) and say what "correct" is. Plan next time: capture a real-render screenshot of that spot, get the user's judgment, then fix to match.

## Where things stand
- Repo forked (`origin` = matanrotman/AppFlowy), `upstream` = AppFlowy-IO/AppFlowy.
- **Fork-sync (checked 2026-07-15):** app `main` 0 behind / 20 ahead of `upstream/main`. Editor fork branch `rtl-direction-aware-selection-menu` is **36 behind, 10 ahead** of its own upstream (`AppFlowy-IO/appflowy-editor`, which has tagged 6.1.0; our pin still reports 5.2.0). Pin ↔ pushed-HEAD: **in sync** (`ba6c4fcb`).
- **Editor fork upstream merge — DEFERRED to a dedicated session.** 36 commits behind + a major version jump touching the exact files we edit; too risky to fold into a bug-fix session.
- **A release build is being produced this session** so the user can swap their dock app to the fixed code while keeping their pages (same `data_beta.appflowy.cloud` workspace). See "Next step".
- **Incident history (still governs live testing):** a 2026-07-13 live-drag test corrupted a real user document. Rule since: all live typing/selecting/dragging happens in a disposable scratch page, never in existing content.
- Local build confirmed working: `flutter run -d macos` (debug) and now a release build too.
- Toolchain (unchanged): Rust rustup w/ pinned 1.85 + stable default; `cargo-make` + `duckscript_cli` (`duck`); **Flutter 3.27.4** git-cloned at `~/flutter` (not Homebrew); CocoaPods/sqlite3/protobuf via Homebrew.
- Rust core (dev): `cargo make --profile development-mac-arm64 appflowy-core-dev-macos` (from `frontend/`). Release core: `cargo make --profile production-mac-arm64 appflowy-core-release`.
- Code generation before `flutter run`: `cargo make code_generation` (from `frontend/`).

## Next step
1. **Finish the release build + swap the user's dock app** (in progress). Build the release macOS app from the fixed code (pin `ba6c4fcb`), then walk the user through pointing their dock at `build/macos/Build/Products/Release/AppFlowy.app` (their `data_beta.appflowy.cloud` workspace is untouched — same data folder). This is what makes the fixes real for daily use and stops the stale-build loop.
2. **Mid-character cursor bug** — capture a real-render screenshot of the caret right after the comma in an embedded date, get the user's judgment on correct placement, fix to match, un-skip the `caret_bidi_test.dart` case.
3. **Editor-fork upstream merge** — dedicated session: merge `6.1.0`/upstream into `rtl-direction-aware-selection-menu` in an isolated worktree, resolve conflicts preserving the ~10 RTL commits, re-run the real-target tests as the regression net, re-pin.

## Open questions
- Sharing-scope badge / workspace icon in the content-pane toolbar — user deferred (out of scope for now).
- `specs/tables.md` (RTL table paste) — written spec, untouched, not scheduled.

## Local build quick-reference
Run from `~/Projects/AppFlowy/frontend`, with `~/flutter/bin`, `~/.cargo/bin`, `~/.pub-cache/bin` on PATH:
```
# Dev run (debug; uses data_dev* workspace):
cargo make --profile development-mac-arm64 appflowy-core-dev-macos
cargo make code_generation
cd appflowy_flutter && flutter run -d macos

# Release build (uses the real data* workspace — the user's daily app):
cargo make --profile production-mac-arm64 appflowy-core-release
cd appflowy_flutter && flutter build macos --release

# Real-target regression test (the ONLY trustworthy way to check RTL geometry):
flutter test integration_test/desktop/document/document_rtl_empty_caret_test.dart -d macos
```
