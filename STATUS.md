# Project Status

*The current snapshot only — replace sections when they change, don't append to them. Detailed history lives in each feature's spec, under its own "Session Log."*

**Last updated:** 2026-07-15

## Active feature
RTL/LTR support (`specs/rtl-support.md`) — Phase 1 is done and signed off. Phase 2 (document-content direction) is **mostly done**: auto-detect direction, bidi, and the block-insert menu direction are solid. **Three bugs remain genuinely open** despite a full round of fix attempts + passing headless tests this session — see "Where things stand." The headless-test approach gave false confidence for these three; they need to be re-approached with more realistic test scenarios and a live confirmation, not just another green test run.

## Where things stand
- Repo is forked (`origin` = matanrotman/AppFlowy) and cloned, with `upstream` = AppFlowy-IO/AppFlowy.
- **Upstream sync (checked 2026-07-12):** local `main` was fully in sync with `upstream/main` as of that check. Re-check due given time elapsed.
- **A second fork now exists and needs its own upkeep**: the editor package is forked to `matanrotman/appflowy-editor` (branch `rtl-direction-aware-selection-menu`), pinned in `pubspec.yaml`, needed because the block-insert menu's positioning logic has no direction-awareness hook upstream. Keep this in sync alongside the main AppFlowy fork; flag anything here that looks upstream-worthy for both repos.
- **Sidebar RTL Phase 1 — committed and signed off.** The sidebar docks left or right, manually or auto-following the interface language, via Settings > Workspace > **"Interface layout"**. Full rationale and file list in `specs/rtl-support.md`'s Session Log.
- **Document RTL Phase 2 — status as of 2026-07-15, after a fix round + live re-check:**
  - Auto-detect block direction (first-strong-character, like Google Docs) and mixed-direction Unicode bidi — implemented, verified working. Solid.
  - Block-insert ("+"/slash) menu direction — implemented via the editor fork (`03719b8a`), now with a headless test confirming LTR/RTL genuinely resolve differently. Not flagged as broken by the user this round, but given the pattern below, worth a live glance before fully trusting it. A separate, unrelated finding — clicking "+" on an existing non-empty block creates a new block below rather than opening the menu in place — turned out to be existing, by-design editor behavior (Notion-style "+"), not a bug.
  - **Icon-margin gap — still too tight, user wants 30px.** Currently 12px (bumped from the original 4px, which had zero visible effect). Not changed further yet — user asked to just leave a `TODO` comment (done, in `editor_configuration.dart`) and bump it to 30px at the start of next session instead.
  - **Cursor renders mid-character/mid-token in real mixed text — still broken.** A live screenshot of a real, longer sentence (Hebrew with several embedded English/number/punctuation runs, e.g. a date like "20.4.26" mid-sentence) shows the cursor still splitting a token. The headless test added this session only covered one simple two-run boundary and passed — it didn't catch this. Root cause and repro sentence are documented directly in `appflowy_rich_text.dart` (fork) via a `NOT SUFFICIENT` comment.
  - **Cursor far from typing position on an empty RTL line — unconfirmed.** Not independently re-checked live this round; treat as still open until it is.
  - **Floating selection toolbar — still not working properly**, per live re-check. The app-side fix (anchor to selection extent, not start) has a headless test, but only for the extracted helper function in isolation, not the real widget — so it didn't catch whatever's actually still wrong. Flagged with a `NOT CONFIRMED WORKING` comment in `desktop_floating_toolbar.dart`.
  - **The lesson learned**: headless tests proved the underlying *mechanisms* work for the specific (simple) scenarios they encoded — they did not prove the bugs were gone in realistic content, and three of four ended up still broken on a live check. Next session needs tests built from the *actual* repro content, plus a real live look before calling anything done — "no screen needed" was about not driving the app continuously mid-session, not skipping a final confirmation.
  - Separate, unscoped finding (not actively re-checked, logged for later): a block created via Enter-split from an RTL sibling stays RTL even when pure English is then typed into it. Likely improved by this session's more robust direction lookup and covered by existing fork tests — worth a quick confirmation next time this comes up.
  - Pub-cache/pubspec landmine found and cleaned up: `pubspec.lock` was pinned to an older fork commit than what was actually pushed, and someone had hand-patched the stale pub-cache checkout in place to informally test the newer code rather than properly re-resolving — fragile, since a future `pub upgrade` would have silently discarded it. Fixed via `flutter pub upgrade appflowy_editor` plus deleting 7 stale checkouts. This part is solid and doesn't need revisiting.
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
Start next session by picking this back up — three real bugs remain, all with root-cause notes and `TODO`/`NOT SUFFICIENT`/`NOT CONFIRMED WORKING` comments already left at the exact code locations from this session:
1. **Icon-margin gap**: bump `editor_configuration.dart`'s `SizedBox(width: 12)` to `30`, then get a live look.
2. **Cursor mid-character in real mixed text**: reproduce live first using the exact repro sentence in `appflowy_rich_text.dart`'s comment (Hebrew + English clause + a date like "20.4.26" + more Hebrew), write a test against *that*, then fix. The existing simple two-run test isn't wrong, just insufficient — keep it, add to it.
3. **Floating toolbar position**: reproduce live first (a selection that genuinely requires scrolling) before assuming `selection_extent_rect.dart`'s logic itself is at fault — the gap might be in how/when `DesktopFloatingToolbar` invokes it, not the helper.
4. Re-check the empty-RTL-line cursor case live too, since it wasn't independently re-confirmed this round.

This time, write tests against realistic repro content (not minimal synthetic cases) and finish with one live check before considering anything done — this session's headless-only tests passed but missed the real failure modes for 3 of 4 bugs.

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
