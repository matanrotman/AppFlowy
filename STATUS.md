# Project Status

*The current snapshot only — replace sections when they change, don't append to them. Detailed history lives in each feature's spec, under its own "Session Log."*

**Last updated:** 2026-07-15

## Active feature
RTL/LTR support (`specs/rtl-support.md`) — Phase 1 and Phase 2 (document-content direction) are both **fully implemented, committed, and verified** (`cea574bef`, `5d856b3f7`, `66f747ba4`, plus today's fix commits — see "Where things stand"). No open Phase 2 bugs remain from this round. Next: decide whether to start `specs/tables.md` (RTL table paste) or meeting transcription (`specs/meeting-transcription.md`, still queued/untouched).

## Where things stand
- Repo is forked (`origin` = matanrotman/AppFlowy) and cloned, with `upstream` = AppFlowy-IO/AppFlowy.
- **Upstream sync (checked 2026-07-12):** local `main` was fully in sync with `upstream/main` as of that check. Re-check due given time elapsed.
- **A second fork now exists and needs its own upkeep**: the editor package is forked to `matanrotman/appflowy-editor` (branch `rtl-direction-aware-selection-menu`), pinned in `pubspec.yaml`, needed because the block-insert menu's positioning logic has no direction-awareness hook upstream. Keep this in sync alongside the main AppFlowy fork; flag anything here that looks upstream-worthy for both repos.
- **Sidebar RTL Phase 1 — committed and signed off.** The sidebar docks left or right, manually or auto-following the interface language, via Settings > Workspace > **"Interface layout"**. Full rationale and file list in `specs/rtl-support.md`'s Session Log.
- **Document RTL Phase 2 — fully committed and verified, all known bugs fixed (2026-07-15):**
  - Auto-detect block direction (first-strong-character, like Google Docs) and mixed-direction Unicode bidi — implemented, verified working.
  - Block-insert ("+"/slash) menu direction — implemented via the editor fork (`03719b8a`), now with a headless test (`selection_menu_service_test.dart`) confirming LTR/RTL genuinely resolve differently. A separate, unrelated finding — clicking "+" on an existing non-empty block creates a new block below rather than opening the menu in place — turned out to be existing, by-design editor behavior (Notion-style "+"), not a bug; not in scope.
  - Icon-margin gap: bumped 4px → 12px in `editor_configuration.dart` (a pre-existing, separate ~5px gap elsewhere made the original addition too subtle against 18-24px icons — ~9px total before, ~17px now). A new fork-side test proves the `SizedBox` mechanism produces a real, undiminished gap; the exact pixel value is still a human/visual call worth a glance next time this is on screen.
  - Two cursor/caret bugs — fixed in the editor fork (commit `1e7219de`: explicit `TextAffinity.upstream` for the mid-character bidi-boundary split; empty-RTL-line caret correction based on real content width) and now genuinely verified via a new headless test (`caret_bidi_test.dart`, 6 passing cases) rather than trusted on sight. The `pubspec.lock`/pub-cache landmine that had kept this fix out of the actual build (see below) is also fixed.
  - Floating text-selection toolbar now anchors to the selection's *extent* (where the user's cursor currently is) instead of always its *start* — fixed app-side in `desktop_floating_toolbar.dart` via a new `selection_extent_rect.dart` helper, with a unit test covering forward and backward multi-paragraph selections. Not RTL-specific.
  - Pub-cache/pubspec landmine found and cleaned up: `pubspec.lock` was pinned to an older fork commit than what was actually pushed, and someone had hand-patched the stale pub-cache checkout in place to informally test the newer code rather than properly re-resolving — fragile, since a future `pub upgrade` would have silently discarded it. Fixed via `flutter pub upgrade appflowy_editor` plus deleting 7 stale checkouts.
  - Separate, unscoped finding (not actively fixed/verified this round, logged for later): a block created via Enter-split from an RTL sibling stays RTL even when pure English is then typed into it. Very likely already fixed as a side effect of the more robust direction lookup (see fork commit `1e7219de`) and covered by existing fork tests — worth a quick confirmation next time this comes up, not urgent.
  - **All verification this session was headless** (`flutter test`/`flutter analyze` only, no live app driving) since the user needed their screen for other work: fork's full suite (902 tests) green, app repo's `test/unit_test/document/` (60 tests) green, `flutter analyze` clean in both repos.
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
No open work on RTL support right now. Decide whether to start `specs/tables.md` (RTL table paste, first phase already scoped: auto-detect + right-align a pasted RTL table) or switch to meeting transcription.

When the user is next at the screen: a short manual-check list is worth a couple minutes —
1. Hover a block's first word — does the icon gap feel comfortable, or does the `SizedBox(width: 12)` in `editor_configuration.dart` need another nudge?
2. Type mixed Hebrew/English text and check the cursor doesn't visually split a character at the boundary.
3. Start a new line in Hebrew and check the cursor appears where typing will land, not off to the side.
4. Select text requiring scrolling and check the formatting toolbar appears near where the selection ends, not still up at the start.

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
