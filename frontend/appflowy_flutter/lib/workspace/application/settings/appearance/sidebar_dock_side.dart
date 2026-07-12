import 'package:appflowy/core/config/kv.dart';
import 'package:appflowy/core/config/kv_keys.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flutter/widgets.dart';

/// Which edge of the app window the sidebar (and its collapse icon,
/// resize handle, and adjacent panels) docks to.
///
/// This is a separate, app-chrome-level setting from `LayoutDirection`
/// (which controls RTL layout inside document content, see
/// `appearance_cubit.dart`) — kept independent since one affects the
/// app's own UI and the other affects user-authored content, and they
/// can reasonably be set differently.
enum SidebarDockSide {
  /// Follow the current interface language's text direction: RTL
  /// languages (e.g. Hebrew, Arabic) dock the sidebar on the right,
  /// LTR languages dock it on the left.
  auto,
  left,
  right;

  static SidebarDockSide fromKey(String? key) => switch (key) {
        'left' => SidebarDockSide.left,
        'right' => SidebarDockSide.right,
        _ => SidebarDockSide.auto,
      };

  String toKey() => name;
}

/// Resolves [SidebarDockSide.auto] against the current [Directionality],
/// which Flutter already derives from the active interface language.
bool resolveSidebarOnRight(BuildContext context, SidebarDockSide side) {
  switch (side) {
    case SidebarDockSide.left:
      return false;
    case SidebarDockSide.right:
      return true;
    case SidebarDockSide.auto:
      return Directionality.of(context) == TextDirection.rtl;
  }
}

/// Most of the sidebar's popovers (space switcher, "..." manage menus,
/// "add a page" menus) open with their left edge aligned to the
/// trigger, growing down-right. When the sidebar docks right, that
/// reads backwards — the popover should grow down-left instead, so
/// it opens toward the sidebar's own content rather than off toward
/// the middle of the window.
PopoverDirection sidebarPopoverDirection(
  BuildContext context,
  SidebarDockSide side,
) {
  return resolveSidebarOnRight(context, side)
      ? PopoverDirection.bottomWithRightAligned
      : PopoverDirection.bottomWithLeftAligned;
}

/// Local-only setting (like text scale factor) — not synced across
/// devices via the backend, read/written straight to key-value storage.
Future<SidebarDockSide> readSidebarDockSide() async {
  final key = await getIt<KeyValueStorage>().get(KVKeys.sidebarDockSide);
  return SidebarDockSide.fromKey(key);
}

Future<void> saveSidebarDockSide(SidebarDockSide side) {
  return getIt<KeyValueStorage>().set(KVKeys.sidebarDockSide, side.toKey());
}
