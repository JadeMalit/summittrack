import 'package:flutter/material.dart';

import '../TrailData/mountain.dart';
import '../app_routes.dart';
import 'mountain_detail_screen.dart';
import 'mt_apo.dart';

String? mountainRouteFor(Mountain mountain) {
  switch (mountain.name) {
    case 'Mt. Apo':
      return AppRoutes.mountain(AppRoutes.mtApoMountainId);
    case 'Mt. Pulag':
      return AppRoutes.mountain(AppRoutes.mtPulagMountainId);
    default:
      return null;
  }
}

Widget buildMountainScreen(Mountain mountain) {
  if (mountain.name == 'Mt. Apo') {
    return const MtApoScreen();
  }

  return MountainDetailScreen(mountain: mountain);
}

Future<T?> openMountainScreen<T>(
  BuildContext context,
  Mountain mountain,
) {
  final routeName = mountainRouteFor(mountain);
  if (routeName != null) {
    return Navigator.of(context).pushNamed<T>(routeName);
  }

  return Navigator.of(context).push<T>(
    MaterialPageRoute(
      builder: (_) => buildMountainScreen(mountain),
    ),
  );
}
