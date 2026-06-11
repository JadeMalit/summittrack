import 'package:flutter/material.dart';

import '../app_routes.dart';
import 'profile_button_function.dart';
import 'settings_button_function.dart';

const int profileNavbarIndex = 0;
const int homeNavbarIndex = 1;
const int weatherNavbarIndex = 2;
const int settingsNavbarIndex = 3;

void handleNavbarButtonTap(
  BuildContext context,
  int index, {
  VoidCallback? onHomeSelected,
  VoidCallback? onWeatherSelected,
}) {
  switch (index) {
    case profileNavbarIndex:
      openProfileScreen(context);
      return;
    case homeNavbarIndex:
      _openHomeScreen(context, onHomeSelected: onHomeSelected);
      return;
    case weatherNavbarIndex:
      onWeatherSelected?.call();
      return;
    case settingsNavbarIndex:
      openSettingsScreen(context);
      return;
  }
}

void _openHomeScreen(
  BuildContext context, {
  VoidCallback? onHomeSelected,
}) {
  final currentRouteName = ModalRoute.of(context)?.settings.name;

  if (currentRouteName == AppRoutes.home || currentRouteName == null) {
    onHomeSelected?.call();
    return;
  }

  Navigator.of(context).pushNamedAndRemoveUntil(
    AppRoutes.home,
    (route) => false,
  );
}
