# RTL/LTR Support

## Goal
Better right-to-left and left-to-right writing and display support — both inside document content, and in the surrounding app UI (sidebar, toolbar) so the whole app feels natural in RTL languages like Hebrew or Arabic, not just the text you type.

## Current state
- The editor already has partial RTL handling — a per-block text-direction attribute and a few targeted line-break fixes — but full bidirectional support has been a known, long-requested gap since 2021 (AppFlowy issue #39: https://github.com/AppFlowy-IO/AppFlowy/issues/39). Mixed-direction content is the weakest part.
- The app's surrounding chrome (sidebar, toolbar, panels) has **no RTL awareness at all** today. The sidebar is pinned to the left edge using hardcoded pixel positioning (`Positioned(left: ...)` in `desktop_home_screen.dart`), not a direction-flexible layout — so nothing in the app chrome currently follows interface language automatically.

## Desired behavior

### Phase 1 — App chrome direction (sidebar + adjacent UI)
- A layout-direction setting that controls where the sidebar docks (left or right).
- **Auto-follow interface language by default**: switching the app's interface language to Hebrew/Arabic auto-flips the sidebar to the right; switching back to English (or another LTR language) flips it back to the left. A manual override is available in Settings for anyone who wants to pin a side regardless of language.
- Collapse/expand icon flips to match — points toward the sidebar's current edge, not hardcoded left.
- Resize drag-handle logic is corrected so dragging toward the sidebar always widens it, regardless of which side it's docked on.
- Adjacent chrome sweep: toolbar/breadcrumb layout and any icons that visually imply "sidebar is on the left" (arrows, hover-reveal edge trigger) are checked and corrected as part of this phase, not left for later.

### Phase 2 — Document content (original scope)
- Automatic per-paragraph direction detection — typing Hebrew/Arabic flips that block automatically, the way Google Docs or Notion handles it.
- Correct cursor movement, text selection, and toolbar placement inside RTL blocks.
- Clean handling of mixed-direction content, e.g. Hebrew text with embedded English words or numbers.

## Files / interfaces involved
- `frontend/appflowy_flutter/lib/workspace/presentation/home/desktop_home_screen.dart` — main layout `Stack`; sidebar, resizer, and content pane are all positioned here with hardcoded `left`/`right` offsets. This is the core file to change for Phase 1.
- `frontend/appflowy_flutter/lib/workspace/presentation/home/home_layout.dart` (`HomeLayout`) — computes `menuWidth`, `showMenu`, `homePageLOffset`; left-edge math needs a direction-aware equivalent.
- `frontend/appflowy_flutter/lib/workspace/presentation/home/menu/sidebar/header/sidebar_top_menu.dart` — collapse/expand button, currently a hardcoded left-pointing icon (`FlowySvgs.double_back_arrow_m`).
- `frontend/appflowy_flutter/lib/workspace/presentation/widgets/sidebar_resizer.dart` (`SidebarResizer`) — drag-to-resize handle; drag math assumes sidebar-then-handle left-to-right ordering.
- `frontend/appflowy_flutter/lib/workspace/presentation/home/menu/sidebar/slider_menu_hover_trigger.dart` (`SliderMenuHoverTrigger`) — appears to be dead/unused code (built but never placed in the layout `Stack`). Worth confirming and either wiring it up correctly or removing it, rather than leaving unclear dead code in a fork we intend to keep merging with upstream.
- `frontend/appflowy_flutter/lib/startup/tasks/app_widget.dart` — sets the app `locale`, which drives Flutter's built-in RTL text mirroring for standard widgets, but the sidebar's manual positioning ignores this today.
- Existing but narrowly-scoped: `LayoutDirection`/`AppFlowyTextDirection` in `appearance_cubit.dart`, currently only wraps the document editor (`plugins/document/presentation/editor_page.dart`) in `Directionality` — Phase 2 will extend this; Phase 1 needs a separate, new app-chrome-level setting since this one doesn't touch the sidebar.
- Editor package (https://github.com/AppFlowy-IO/appflowy-editor) — likely touched directly for Phase 2.

## Out of scope (for now)
- Mobile layout direction (this plan targets desktop first, matching how the sidebar/menu system is currently desktop-specific).
- Localizing/translating the UI itself into Hebrew/Arabic strings (separate effort from layout direction).

## To confirm with me
*(resolved via interview — kept here for the record)*
- Scope: app chrome (sidebar) **and** document content — both in scope, split into two phases. ✅
- Sidebar side: toggleable setting, auto-following interface language by default with manual override. ✅
- Collapse/resize behavior: mirrored exactly, no interaction redesign. ✅
- Adjacent-chrome sweep: included in Phase 1 (toolbar/breadcrumbs/icons), not just the sidebar itself. ✅

Still open, to confirm before Phase 2 begins:
- Should per-block direction be fully automatic, or overridable per block?
- How should mixed RTL/LTR lines visually behave?

## Verification
**Phase 1:**
- Manually switch interface language to Hebrew (or another RTL language available in Settings) and confirm: sidebar docks right, collapse icon points the correct way, resize handle widens the sidebar when dragged toward it, toolbar/breadcrumbs look correct, no leftover left-docked visual artifacts.
- Switch back to English and confirm everything returns to the left correctly.
- Test manual override: pin sidebar to a side that doesn't match the current language, confirm it stays put until changed.

**Phase 2:** *(fill in once we scope that phase in detail)*

## Session Log
- **2026-07-11**: Interviewed on sidebar-right request; determined it's really Phase 1 of the existing RTL spec (app chrome direction), not a standalone feature. Explored codebase to confirm current left-hardcoded positioning (sidebar layout, collapse icon, resize handle) and confirmed no existing app-chrome direction plumbing. Wrote phased plan (chrome first, document content second) for sign-off; no code changes made yet.
- **2026-07-11/12**: Built Phase 1 and iterated through two rounds of live testing against a running `flutter run -d macos` build.
  - **Foundation**: new `SidebarDockSide` setting (auto/left/right) in `sidebar_dock_side.dart`, local-only (like text scale factor, not synced), with `resolveSidebarOnRight()` resolving "auto" against the ambient `Directionality` (itself driven by interface locale). Wired into `AppearanceSettingsCubit` and a new Settings > Workspace radio group. Reused Flutter's own `Directionality` mechanism by wrapping the whole sidebar subtree (`HomeSideBar`) in it — this made most icon/row ordering mirror for free, rather than hand-patching every widget.
  - **Round 1 fixes**: sidebar/resizer/edit-panel/notification-panel positioning in `desktop_home_screen.dart` and `home_layout.dart` (edit panel now docks opposite the sidebar so they never collide); collapse icon direction; resizer drag-math sign flip for right dock; removed confirmed-dead `SliderMenuHoverTrigger`; Search row margin fixed to match sibling rows; caret icon flip on tree items; footer Trash/Templates order swap; popover open-direction (`sidebarPopoverDirection` helper, `bottomWithLeftAligned` → `bottomWithRightAligned`) applied to ~8 sidebar popovers (space switcher, space/workspace "..." menus, add-page menu, per-page "..." menu); notification bell panel's real bug found — a hardcoded `Alignment.centerLeft` inside `notification_panel.dart` that ignored dock side entirely.
  - **Round 2 fixes** (user found more after live testing): reverted the collapse button's position back to the sidebar's own top row (an initial attempt to relocate it next to "More options" was wrong — moved and reverted in the same session); fixed a macOS traffic-light/breadcrumb collision (`menuSpacing` in `home_layout.dart` now also reserves space when docked right and open, not just when hidden); reordered the content-pane's top toolbar (`home_stack.dart`'s `HomeTopBar`) so the breadcrumb and the more-options/favorite/share/active-users group swap sides; extended direction-aware popovers into ~10 in-document popovers (text align/color/highlight, heading, more-options, code language picker, math equation, AI writer, link edit menu) via a new `documentPopoverDirection()` helper keyed off the **document's own** `LayoutDirection` setting, not the sidebar's — confirmed as the right split via the one existing precedent (`block_action_option_button.dart`) and a direct question to the user.
  - **Explicitly deferred, not built**: a workspace icon/name and a "who has access" sharing-scope badge in the content-pane toolbar (user confirmed these don't exist today and asked to skip building new UI, just reorder what's there); the "My workspace" switcher popover (already centered, direction-neutral, judged not to need the fix); a table column-menu popover whose direction already branches on row-vs-column type (left alone, not confirmed broken); Windows-specific sidebar-toggle icon in `home_stack.dart`'s `_buildToggleMenuButton` (flagged as untested/unverifiable on this Mac).
  - **Status**: all code passes `flutter analyze` clean and builds/runs successfully as of the last rebuild. **Not yet committed.** User was about to re-test the latest build when the session ended — next session should start by checking whether that re-test surfaced anything else before committing.
- **2026-07-13**: Live-tested the rebuild end-to-end (`flutter run -d macos`, computer-use screenshots of the actual window) and fixed everything the user found:
  - **Sidebar**: search row's icon box was 16×16 (Flutter's `FlowyButton` default) while the adjacent "new page" row explicitly sets 24×24 — added the matching explicit size so the two icons line up. Nested-page indent used a hardcoded `EdgeInsets.only(left: ...)`, which doesn't mirror; switched to `EdgeInsetsDirectional.only(start: ...)` so children indent toward the correct edge regardless of dock side (confirmed by creating a real nested page and checking it indented leftward with the sidebar docked right).
  - **Top bar** (the bigger fix): the breadcrumb (space icon/name → page icon/name → access-scope label) was stretching into an `Expanded` region but always hugging its *start* edge, leaving a dead gap next to a right-docked sidebar instead of sitting flush against it — fixed in `NaviItemWidget` (`navigation.dart`) with an `Align` keyed off ambient `Directionality`. Separately, the breadcrumb's internal item order and the action-button group's internal order (user avatar/share/favorite/more-options) were always LTR-authored order regardless of dock side; wrapped both in `Directionality(textDirection: sidebarOnRight ? rtl : ltr)` in `home_stack.dart` so they mirror together with the rest of the chrome. The breadcrumb's `›` divider icon doesn't auto-mirror as part of that (Flutter doesn't flip glyphs based on ambient direction), so added an explicit `Transform.flip` in `view_title_bar.dart`, matching the existing pattern used for the sidebar collapse icon.
  - **Root-cause note for future reference**: resolved via user testing + reading the running app, not guesswork — an earlier code comment in `view_title_bar.dart` claimed breadcrumb items should *keep* LTR order regardless of direction; the user's explicit walkthrough of the desired order superseded that, so the comment's premise is now stale (removed as part of this fix).
  - **Round 2 (two small polish requests after sign-off)**: user avatar sat too far from the Share button — root cause was `CollaboratorAvatarStack` (`collaborator_avatar_stack.dart`) hardcoding `align: StackAlign.right` inside its reserved 120px-wide box regardless of layout direction, so in the mirrored top bar the visible avatar sat at the box's *outer* edge instead of the edge next to Share; made the align direction-aware (`Directionality.of(context)`-driven) instead. Also renamed the "Sidebar position" setting to **"Interface layout"** in Settings > Workspace, since it now visibly governs both the sidebar and the top bar — flagged and resolved a naming collision first, since there's a separate, pre-existing "Layout direction" setting (document editor popovers only, intentionally independent); user chose to keep that one as-is and give this one its own distinct name.
  - **Committed**: `5d856b3f7` — all of the above, plus the `en-US.json` label rename. `macos/Podfile.lock`'s one-line CocoaPods-version diff (unrelated local artifact) was deliberately left out of the commit and left uncommitted at the user's request.
  - **Verification note**: everything above was checked visually in the running app via computer-use screenshots (including creating and deleting a throwaway nested test page) — not just `flutter analyze`. One exception: the Settings > Workspace panel wouldn't accept scroll input in this session's automation, so the "Interface layout" rename is a straightforward, low-risk string-only change that wasn't re-confirmed visually — worth a glance next time that settings page is open.
