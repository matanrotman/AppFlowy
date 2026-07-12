# Project Status

*The current snapshot only — replace sections when they change, don't append to them. Detailed history lives in each feature's spec, under its own "Session Log."*

**Last updated:** 2026-07-12

## Active feature
RTL/LTR support (`specs/rtl-support.md`) — Phase 1 (app chrome direction) is implemented and has been through two rounds of live testing/fixes. Meeting transcription (`specs/meeting-transcription.md`) is still queued, untouched.

## Where things stand
- Repo is forked (`origin` = matanrotman/AppFlowy) and cloned, with `upstream` = AppFlowy-IO/AppFlowy.
- **Upstream sync (checked 2026-07-12):** local `main` is fully in sync with `upstream/main` — 0 commits behind, and already contains the latest release tag 0.12.5. Nothing to merge. A weekly automated check runs every Sunday 8:00 AM (report-only, no auto-merge).
- **Sidebar RTL Phase 1 (this session's work, uncommitted):** the sidebar can now dock left or right, either manually or auto-following the interface language, via Settings > Workspace > "Sidebar position". Also fixed, across two rounds of user testing: collapse/expand icon direction, resize-handle drag math, footer (Trash/Templates) order, popover open-direction throughout the sidebar (and extended into ~10 in-document popovers, keyed off the document's own RTL setting), the notification bell panel position, the content-pane top toolbar (breadcrumb vs. more-options/favorite/share/active-users) mirroring, and a macOS traffic-light/breadcrumb overlap bug. Full file list and rationale in `specs/rtl-support.md`'s Session Log. **Not yet committed or manually re-verified after the last rebuild** — that's the next step.
- **Project location moved**: the repo now lives at `~/Projects/AppFlowy`, not inside Google Drive. It was originally cloned into the Google Drive-synced folder, which caused severe build slowdowns (Drive fighting the build for CPU/disk while re-syncing hundreds of thousands of small build files). Moved out with git history and remotes intact; the old Drive copy was deleted.
- Local macOS build is confirmed working end-to-end: `flutter run -d macos` builds and launches AppFlowy (Rust core + Flutter UI), reaching the welcome/login screen.
- Toolchain installed on this Mac:
  - Rust via rustup, with the pinned `1.85` toolchain (`frontend/rust-toolchain.toml`) plus a `stable` default toolchain (needed to build `cargo-make`/`duckscript_cli`, which require newer rustc than 1.85).
  - `cargo-make` and `duckscript_cli` (binary name `duck`) via `cargo install`.
  - Flutter **3.27.4** installed via `git clone` at `~/flutter` (not Homebrew — Homebrew's cask installs the latest Flutter, e.g. 3.44, whose `leak_tracker` version conflicts with AppFlowy's pinned dependency).
  - CocoaPods, sqlite3, protobuf via Homebrew.
  - `~/.config` ownership was fixed (was root-owned, blocking Flutter) — required a manual `sudo chown` from the user.
- Rust build must be run with the correct cargo-make profile: `cargo make --profile development-mac-arm64 appflowy-core-dev-macos` (from `frontend/`). Without `--profile`, `TARGET_OS` isn't set and the post-build copy step fails even though compilation succeeds.
- Code generation (locale keys + freezed models) must be run before `flutter run` works: `cargo make code_generation` (from `frontend/`). Skipping it causes real compile errors (`LocaleKeys` undefined, switch-exhaustiveness errors).

## Next step
User to re-test the latest rebuild (sidebar reorder, traffic-light fix, toolbar mirroring, extended popover directions) and report anything still off. Once Phase 1 is signed off as done, commit the work, then decide whether to start Phase 2 (document-content RTL) or switch to meeting transcription.

## Open questions
- Phase 2 (document content RTL) still has two open questions from the original spec: should per-block direction be fully automatic or overridable, and how should mixed RTL/LTR lines visually behave?
- Whether to build out a "who has access" sharing-scope badge and a workspace icon/name in the content-pane toolbar — user explicitly deferred this (not existing UI, out of scope for now) but may revisit.

## Local build quick-reference
Run from `~/Projects/AppFlowy/frontend`, with `~/flutter/bin`, `~/.cargo/bin`, and `~/.pub-cache/bin` on PATH:
```
cargo make --profile development-mac-arm64 appflowy-core-dev-macos   # Rust core
cargo make code_generation                                            # locale keys + freezed (only needed after clean/pubspec changes)
cd appflowy_flutter && flutter run -d macos                           # launch the app
```
