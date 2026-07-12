import 'dart:io' show Platform;
import 'dart:math';

import 'package:appflowy/workspace/application/home/home_setting_bloc.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy/workspace/application/settings/appearance/sidebar_dock_side.dart';
import 'package:flowy_infra/size.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:sized_context/sized_context.dart';

import 'home_sizes.dart';

class HomeLayout {
  HomeLayout(BuildContext context) {
    final homeSetting = context.read<HomeSettingBloc>().state;
    showEditPanel = homeSetting.panelContext != null;

    menuWidth = max(
      HomeSizes.minimumSidebarWidth + homeSetting.resizeOffset,
      HomeSizes.minimumSidebarWidth,
    );

    final screenWidthPx = context.widthPx;
    context
        .read<HomeSettingBloc>()
        .add(HomeSettingEvent.checkScreenSize(screenWidthPx));

    showMenu = homeSetting.menuStatus == MenuStatus.expanded;
    if (showMenu) {
      menuIsDrawer = context.widthPx <= PageBreaks.tabletPortrait;
    }

    showNotificationPanel = !homeSetting.isNotificationPanelCollapsed;

    sidebarOnRight = resolveSidebarOnRight(
      context,
      context.read<AppearanceSettingsCubit>().state.sidebarDockSide,
    );

    // On macOS, the traffic-light window buttons are always painted
    // top-left of the window, regardless of sidebar side. This 80px
    // reserve keeps the content pane's own top bar from rendering
    // under them — needed whenever the content pane's left edge sits
    // at the window's physical left edge, which happens both when
    // the sidebar is hidden AND when it's docked right (since then
    // the content pane occupies the window's left side either way).
    menuSpacing =
        (!showMenu || sidebarOnRight) && Platform.isMacOS ? 80.0 : 0.0;
    animDuration = homeSetting.resizeType.duration();
    editPanelWidth = HomeSizes.editPanelWidth;
    notificationPanelWidth = MediaQuery.of(context).size.width -
        (showEditPanel ? editPanelWidth : 0);

    // The sidebar and the edit panel are always docked to opposite
    // edges so they never contest the same corner of the window.
    final menuOccupiedWidth = (showMenu && !menuIsDrawer) ? menuWidth : 0.0;
    final editPanelOccupiedWidth = showEditPanel ? editPanelWidth : 0.0;
    if (sidebarOnRight) {
      homePageLOffset = editPanelOccupiedWidth;
      homePageROffset = menuOccupiedWidth;
    } else {
      homePageLOffset = menuOccupiedWidth;
      homePageROffset = editPanelOccupiedWidth;
    }
  }

  late bool showEditPanel;
  late double menuWidth;
  late bool showMenu;
  late bool menuIsDrawer;
  late bool showNotificationPanel;
  late bool sidebarOnRight;
  late double homePageLOffset;
  late double menuSpacing;
  late Duration animDuration;
  late double editPanelWidth;
  late double notificationPanelWidth;
  late double homePageROffset;
}
