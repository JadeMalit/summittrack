import 'package:flutter/material.dart';

import '../../../core/routing/app_routes.dart';

void openProfileScreen(BuildContext context) {
  Navigator.of(context).pushNamed(AppRoutes.profile);
}
