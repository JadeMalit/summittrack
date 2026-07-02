import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/state/app_mode_provider.dart';
import '../../profile/button_functions/profile_button_function.dart';
import '../../settings/button_functions/settings_button_function.dart';

const int profileNavbarIndex = 0;
const int homeNavbarIndex = 1;
const int weatherNavbarIndex = 2;
const int settingsNavbarIndex = 3;

Future<void> handleNavbarButtonTap(
  BuildContext context,
  int index, {
  VoidCallback? onHomeSelected,
  FutureOr<void> Function()? onWeatherSelected,
}) async {
  if (AppModeProvider.instance.isOfflineMode && index != homeNavbarIndex) {
    onHomeSelected?.call();
    await showOfflineFeatureUnavailableDialog(context);
    return;
  }

  switch (index) {
    case profileNavbarIndex:
      await openProfileScreen(context);
      return;
    case homeNavbarIndex:
      _openHomeScreen(context, onHomeSelected: onHomeSelected);
      return;
    case weatherNavbarIndex:
      final onWeather = onWeatherSelected;
      if (onWeather != null) {
        await onWeather();
      }
      return;
    case settingsNavbarIndex:
      await openSettingsScreen(context);
      return;
  }
}

Future<void> showOfflineFeatureUnavailableDialog(BuildContext context) async {
  if (!context.mounted) {
    return;
  }

  await showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Offline Mode'),
        content: const Text('This feature is only available online.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}

int navbarIndexForRouteName(String? routeName) {
  final location = AppRoutes.normalizeLocation(routeName);
  final path = Uri.parse(location).path;

  switch (path) {
    case AppRoutes.profile:
      return profileNavbarIndex;
    case AppRoutes.weather:
      return weatherNavbarIndex;
    case AppRoutes.settings:
      return settingsNavbarIndex;
    case AppRoutes.home:
    default:
      return homeNavbarIndex;
  }
}

void _openHomeScreen(BuildContext context, {VoidCallback? onHomeSelected}) {
  final currentRouteName = ModalRoute.of(context)?.settings.name;

  if (currentRouteName == AppRoutes.home || currentRouteName == null) {
    onHomeSelected?.call();
    return;
  }

  Navigator.of(
    context,
  ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
}
