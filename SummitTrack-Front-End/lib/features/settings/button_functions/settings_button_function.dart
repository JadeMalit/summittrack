import 'package:flutter/material.dart';

import '../../../core/routing/app_routes.dart';

Future<void> openSettingsScreen(BuildContext context) async {
  await Navigator.of(context).pushNamed(AppRoutes.settings);
}
