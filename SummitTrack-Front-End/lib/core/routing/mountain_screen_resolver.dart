import 'package:flutter/material.dart';

import '../../data/trail_data/mountain.dart';
import '../../features/mountains/screens/mountain_detail_screen.dart';
import '../../features/mountains/screens/mt_apo.dart';
import '../../features/mountains/screens/mt_pulag.dart'; 
import '../../features/mountains/screens/mt_mayon.dart'; 
import '../../features/mountains/screens/mt_batulao.dart'; 
import '../../features/mountains/screens/mt_ulap.dart'; 
import '../../features/mountains/screens/mt_daraitan.dart'; // <--- IDINAGDAG ANG IMPORT NI DARAITAN
import 'app_routes.dart';

String? mountainRouteFor(Mountain mountain) {
  switch (mountain.name) {
    case 'Mt. Apo':
      return AppRoutes.mountain(AppRoutes.mtApoMountainId);
    case 'Mt. Pulag':
      return AppRoutes.mountain(AppRoutes.mtPulagMountainId);
    case 'Mt. Mayon':
      return '/mountain/mayon';
    case 'Mt. Batulao':
      return '/mountain/batulao';
    case 'Mt. Ulap':
      return '/mountain/ulap';
    case 'Mt. Daraitan': // <--- IDINAGDAG: Para sa click action mula sa Home card
      return '/mountain/daraitan';
    default:
      return null;
  }
}

Widget buildMountainScreen(Mountain mountain) {
  if (mountain.name == 'Mt. Apo') {
    return const MtApoScreen();
  }
  if (mountain.name == 'Mt. Pulag') {
    return const MtPulagScreen(); 
  }
  if (mountain.name == 'Mt. Mayon') {
    return const MtMayonScreen(); 
  }
  if (mountain.name == 'Mt. Batulao') {
    return const MtBatulaoScreen(); 
  }
  if (mountain.name == 'Mt. Ulap') {
    return const MtUlapScreen(); 
  }
  if (mountain.name == 'Mt. Daraitan') {
    return const MtDaraitanScreen(); // <--- IDINAGDAG: Diretso na sa 3 action buttons natin!
  }

  return MountainDetailScreen(mountain: mountain);
}

Future<T?> openMountainScreen<T>(BuildContext context, Mountain mountain) {
  final routeName = mountainRouteFor(mountain);
  if (routeName != null) {
    return Navigator.of(context).pushNamed<T>(routeName);
  }

  return Navigator.of(
    context,
  ).push<T>(MaterialPageRoute(builder: (_) => buildMountainScreen(mountain)));
}