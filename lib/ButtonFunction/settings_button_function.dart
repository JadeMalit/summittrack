import 'package:flutter/material.dart';

import '../app_routes.dart';

void openSettingsScreen(BuildContext context) {
  Navigator.of(context).pushNamed(AppRoutes.settings);
}
