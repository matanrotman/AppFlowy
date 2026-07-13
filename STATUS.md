# Project Status

*The current snapshot only — replace sections when they change, don't append to them. Detailed history lives in each feature's spec, under its own "Session Log."*

**Last updated:** 2026-07-13

## Active feature
RTL/LTR support (`specs/rtl-support.md`) — Phase 1 (app chrome direction) is **implemented, live-tested, and committed** (`5d856b3f7`, plus the foundational `cea574bef`). Meeting transcription (`specs/meeting-transcription.md`) is still queued, untouched.

## Where things stand
- Repo is forked (`origin` = matanrotman/AppFlowy) and cloned, with `upstream` = AppFlowy-IO/AppFlowy.
- **Upstream sync (checked 2026-07-12):** local `main` is fully in sync with `upstream/main` — 0 commits behind, and already contains the latest release tag 0.12.5. Nothing to merge. A weekly automated check runs every Sunday 8:00 AM (report-only, no auto-merge).
- **Sidebar RTL Phase 1 — committed and signed off.** The sidebar docks left or right, manually or auto-following the interface language, via Settings > Workspace > **"Interface layout"** (renamed this session from "Sidebar position" now that it also governs the top bar; kept distinct from the existing, unrelated "Layout direction" setting which controls document editor popovers). A live-testing pass surfaced and fixed: sidebar search icon size/alignment, nested-page indent direction, the top bar's breadcrumb/action-button group edge-anchoring and internal mirroring, the breadcrumb divider chevron direction, the collaborator-avatar anchor position, and user-avatar-to-Share spacing. Full rationale and file list in `specs/rtl-support.md`'s Session Log.
- **Uncommitted, left alone on purpose:** `frontend/appflowy_flutter/macos/Podfile.lock` has a one-line local diff (CocoaPods version stamp, `1.16.2` → `1.17.0`) from running the macOS build on this machine. Harmless, unrelated to the feature, user asked to leave it uncommitted.
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
Decide whether to start Phase 2 (document-content RTL) or switch to meeting transcription.

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
