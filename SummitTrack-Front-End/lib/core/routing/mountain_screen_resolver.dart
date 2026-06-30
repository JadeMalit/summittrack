import 'package:flutter/material.dart';

import '../../data/trail_data/mountain.dart';
import '../../features/mountains/screens/mountain_detail_screen.dart';
import '../../features/mountains/screens/mt_apo.dart';
import '../../features/mountains/screens/mt_pulag.dart'; 
import '../../features/mountains/screens/mt_mayon.dart'; 
import '../../features/mountains/screens/mt_batulao.dart'; 
import '../../features/mountains/screens/mt_ulap.dart'; 
import '../../features/mountains/screens/mt_daraitan.dart'; 
import '../../features/mountains/screens/mt_maculot.dart'; 
import '../../features/mountains/screens/mt_pico_de_loro.dart'; 
import '../../features/mountains/screens/mt_pinatubo.dart'; 
import '../../features/mountains/screens/mt_guiting_guiting.dart'; // <--- IDINAGDAG ANG IMPORT NI GUITING-GUITING SCREEN
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
    case 'Mt. Daraitan': 
      return '/mountain/daraitan';
    case 'Mt. Maculot': 
      return '/mountain/maculot';
    case 'Mt. Pico de Loro': 
      return '/mountain/picodeloro';
    case 'Mt. Pinatubo': 
      return '/mountain/pinatubo';
    case 'Mt. Guiting-Guiting': // <--- IDINAGDAG: Para sa click action mula sa Home card
      return '/mountain/g2';
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
    return const MtDaraitanScreen(); 
  }
  if (mountain.name == 'Mt. Maculot') {
    return const MtMaculotScreen(); 
  }
  if (mountain.name == 'Mt. Pico de Loro') {
    return const MtPicoDeLoroScreen(); 
  }
  if (mountain.name == 'Mt. Pinatubo') {
    return const MtPinatuboScreen(); 
  }
  if (mountain.name == 'Mt. Guiting-Guiting') {
    return const MtGuitingGuitingScreen(); // <--- IDINAGDAG: Diretso na sa 3 action buttons natin!
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