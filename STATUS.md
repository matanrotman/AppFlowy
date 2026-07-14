# Project Status

*The current snapshot only — replace sections when they change, don't append to them. Detailed history lives in each feature's spec, under its own "Session Log."*

**Last updated:** 2026-07-15

## Active feature
RTL/LTR support (`specs/rtl-support.md`) — Phase 1 (app chrome direction) and most of Phase 2 (document-content direction) are **implemented and committed** (`cea574bef`, `5d856b3f7`, `66f747ba4`). Several Phase 2 bugs are open and are this session's focus (see "Next step"). Meeting transcription (`specs/meeting-transcription.md`) is still queued, untouched.

## Where things stand
- Repo is forked (`origin` = matanrotman/AppFlowy) and cloned, with `upstream` = AppFlowy-IO/AppFlowy.
- **Upstream sync (checked 2026-07-12):** local `main` was fully in sync with `upstream/main` as of that check. Re-check due given time elapsed.
- **A second fork now exists and needs its own upkeep**: the editor package is forked to `matanrotman/appflowy-editor` (branch `rtl-direction-aware-selection-menu`), pinned in `pubspec.yaml`, needed because the block-insert menu's positioning logic has no direction-awareness hook upstream. Keep this in sync alongside the main AppFlowy fork; flag anything here that looks upstream-worthy for both repos.
- **Sidebar RTL Phase 1 — committed and signed off.** The sidebar docks left or right, manually or auto-following the interface language, via Settings > Workspace > **"Interface layout"**. Full rationale and file list in `specs/rtl-support.md`'s Session Log.
- **Document RTL Phase 2 — mostly committed (`66f747ba4`), but with known open bugs being worked this session:**
  - Auto-detect block direction (first-strong-character, like Google Docs) and mixed-direction Unicode bidi — implemented, verified working.
  - Block-insert ("+"/slash) menu direction — implemented via the editor fork (`03719b8a`). A separate, unrelated finding — clicking "+" on an existing non-empty block creates a new block below rather than opening the menu in place — turned out to be existing, by-design editor behavior (Notion-style "+"), not a bug; not in scope. The RTL-direction part is being re-verified with a real headless test this session (see "Next step").
  - Icon-margin tweak (hover "+"/drag icon spacing): the first committed value (4px) had **no visible effect** — user confirmed live. Root cause diagnosed: a pre-existing, separate ~5px gap elsewhere made the 4px addition (9px total) too subtle against 18-24px icons. A bigger value plus a proper headless test (proving the SizedBox mechanism actually produces a real gap, not just a number in code) are this session's fix — see "Next step". The final pixel value is still a human/visual call the user should glance at when free.
  - Two cursor/caret bugs — **fix already written** in the editor fork (commit `1e7219de`: explicit `TextAffinity.upstream` for the mid-character bidi-boundary split; empty-RTL-line caret correction now based on real content width instead of a placeholder-text check that skipped the common case) — but **never verified**, and the app's `pubspec.lock` was still pinned to the *older* fork commit (`03719b8a`), so the fix wasn't even in the build being tested. A stray hand-patched pub-cache checkout for the old commit was also found (informal, undocumented local testing) — fragile, being cleaned up properly via `flutter pub upgrade appflowy_editor` this session. A prior fix attempt earlier caused a scary regression (RTL text stopped accepting clicks-to-place-cursor) that turned out to reproduce even on the reverted "safe" commit — most likely session flakiness, not a real regression, but being verified with an actual headless test this time instead of trusted on sight.
  - Floating text-selection toolbar appears above the selection's *start* instead of near where the selection currently ends, especially when scrolling is involved. Root cause diagnosed (app-side, not RTL-specific): `desktop_floating_toolbar.dart` anchors on `selectionRects().first` (always the drag-start rect) instead of `.last` (the drag-extent rect, i.e. where the user currently is) — one-line fix, being added with a unit test this session.
  - Separate, unscoped finding (not being fixed this round, logged for later): a block created via Enter-split from an RTL sibling stays RTL even when pure English is then typed into it — direction doesn't re-evaluate for a freshly-split empty node. (Likely already improved by `1e7219de`'s more robust direction lookup — worth a quick check next time this comes up, but not actively verified this session since it wasn't one of the 4 items asked for.)
- **`Podfile.lock` CocoaPods version bump is committed** (`ca128648d`, 1.16.2 → 1.17.0) — no longer an uncommitted loose end. Working tree is otherwise clean.
- **Incident history**: a live-testing session on 2026-07-13 caused unintended content changes in a real, populated user document during click-drag testing; user fixed it manually. Process fix adopted since: all live UI testing (typing/selecting/dragging) happens in a disposable scratch page created for that purpose, never in existing content.
- Local macOS build is confirmed working end-to-end: `flutter run -d macos` builds and launches AppFlowy (Rust core + Flutter UI), reaching the welcome/login screen and into documents.
- Toolchain installed on this Mac:
  - Rust via rustup, with the pinned `1.85` toolchain (`frontend/rust-toolchain.toml`) plus a `stable` default toolchain (needed to build `cargo-make`/`duckscript_cli`, which require newer rustc than 1.85).
  - `cargo-make` and `duckscript_cli` (binary name `duck`) via `cargo install`.
  - Flutter **3.27.4** installed via `git clone` at `~/flutter` (not Homebrew — Homebrew's cask installs the latest Flutter, e.g. 3.44, whose `leak_tracker` version conflicts with AppFlowy's pinned dependency).
  - CocoaPods, sqlite3, protobuf via Homebrew.
  - `~/.config` ownership was fixed (was root-owned, blocking Flutter) — required a manual `sudo chown` from the user.
- Rust build must be run with the correct cargo-make profile: `cargo make --profile development-mac-arm64 appflowy-core-dev-macos` (from `frontend/`). Without `--profile`, `TARGET_OS` isn't set and the post-build copy step fails even though compilation succeeds.
- Code generation (locale keys + freezed models) must be run before `flutter run` works: `cargo make code_generation` (from `frontend/`). Skipping it causes real compile errors (`LocaleKeys` undefined, switch-exhaustiveness errors).

## Next step
User needs their screen for other work, so this round is being verified **headlessly** (`flutter test`/`flutter analyze` from the terminal) instead of by driving the visible app. Plan (`/Users/matanrotman/.claude/plans/commit-remote-what-you-generic-moon.md`):
1. Fix the `pubspec.lock`/pub-cache landmine (`flutter pub upgrade appflowy_editor`) so the app actually builds against the fork's latest fix commit.
2. Write headless tests (in `appflowy-editor-fork`'s `flutter test` suite, which already has the right harness) proving each of the 4 bugs is actually fixed: cursor-splits-mid-character, cursor-far-from-text, icon-margin gap mechanism, menu-direction (retroactive test for the already-committed fix).
3. Fix the floating-toolbar-position bug (app-side, one-line root cause already found) with its own unit test.
4. Reconcile an uncommitted, unverified `slash_command.dart` tweak against the fork's more robust underlying fix, keeping only what's still needed.
5. Commit everything with real evidence behind it, push both repos.
6. Leave a short plain-language manual-check list for the user to eyeball whenever free — a couple of these (the icon gap's exact pixel value) are inherently visual judgment calls no automated test can fully settle.

## Open questions
- Whether to build out a "who has access" sharing-scope badge and a workspace icon/name in the content-pane toolbar — user explicitly deferred this (not existing UI, out of scope for now) but may revisit.
- `specs/tables.md` (RTL table paste) exists as a written spec but is untouched — not scheduled yet.

## Local build quick-reference
Run from `~/Projects/AppFlowy/frontend`, with `~/flutter/bin`, `~/.cargo/bin`, and `~/.pub-cache/bin` on PATH:
```
cargo make --profile development-mac-arm64 appflowy-core-dev-macos   # Rust core
cargo make code_generation                                            # locale keys + freezed (only needed after clean/pubspec changes)
cd appflowy_flutter && flutter run -d macos                           # launch the app
```
