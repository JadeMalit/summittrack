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
import '../../features/mountains/screens/mt_guiting_guiting.dart'; 
import '../../features/mountains/screens/mt_manabu.dart'; 
import '../../features/mountains/screens/mt_gulugod_baboy.dart'; 
import '../../features/mountains/screens/mt_maynoba.dart'; 
import '../../features/mountains/screens/mt_lingguhob.dart'; // <--- IDINAGDAG ANG IMPORT NI LINGGUHOB SCREEN
import '../../features/mountains/screens/mt_arayat.dart'; // <--- IDINAGDAG: IMPORT NI ARAYAT SCREEN
import '../../features/mountains/screens/mt_makiling.dart'; // <--- IDINAGDAG: IMPORT NI MAKILING SCREEN
import '../../features/mountains/screens/mt_damas.dart'; // <--- IDINAGDAG: IMPORT NI DAMAS SCREEN
import '../../features/mountains/screens/mt_tugew.dart'; // <--- IDINAGDAG: IMPORT NI TUGEW SCREEN
import '../../features/mountains/screens/mt_mariglem.dart'; // <--- IDINAGDAG: IMPORT NI MARIGLEM SCREEN
import '../../features/mountains/screens/mt_cutuno.dart'; // <--- BINAGO: PURE CUTUNO SCREEN IMPORT
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
    case 'Mt. Guiting-Guiting': 
      return '/mountain/g2';
    case 'Mt. Manabu': 
      return '/mountain/manabu';
    case 'Mt. Gulugod Baboy': 
      return '/mountain/gulugodbaboy';
    case 'Mt. Maynoba': 
      return '/mountain/maynoba';
    case 'Mt. Lingguhob': // <--- IDINAGDAG: Para sa click action ni Lingguhob
      return '/mountain/lingguhob';
    case 'Mt. Arayat': // <--- IDINAGDAG: Para sa click action ni Arayat
      return '/mountain/arayat';
    case 'Mt. Makiling': // <--- IDINAGDAG: Para sa click action ni Makiling
      return '/mountain/makiling';
    case 'Mt. Damas': // <--- IDINAGDAG: Para sa click action ni Damas
      return '/mountain/damas';
    case 'Mt. Tugew': // <--- IDINAGDAG: Para sa click action ni Tugew
      return '/mountain/tugew';
    case 'Mt. Mariglem': // <--- IDINAGDAG: Para sa click action ni Mariglem
      return '/mountain/mariglem';
    case 'Mt. Cutuno': // <--- BINAGO: Pure Cutuno click target layout route
      return '/mountain/cutuno';
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
    return const MtGuitingGuitingScreen(); 
  }
  if (mountain.name == 'Mt. Manabu') {
    return const MtManabuScreen(); 
  }
  if (mountain.name == 'Mt. Gulugod Baboy') {
    return const MtGulugodBaboyScreen(); 
  }
  if (mountain.name == 'Mt. Maynoba') {
    return const MtMaynobaScreen(); 
  }
  if (mountain.name == 'Mt. Lingguhob') {
    return const MtLingguhobScreen(); // <--- IDINAGDAG: Buksan ang custom design layout natin!
  }
  if (mountain.name == 'Mt. Arayat') {
    return const MtArayatScreen(); // <--- IDINAGDAG: Buksan ang custom design layout ni Arayat!
  }
  if (mountain.name == 'Mt. Makiling') {
    return const MtMakilingScreen(); // <--- IDINAGDAG: Buksan ang custom design layout ni Makiling!
  }
  if (mountain.name == 'Mt. Damas') {
    return const MtDamasScreen(); // <--- IDINAGDAG: Buksan ang custom design layout ni Damas!
  }
  if (mountain.name == 'Mt. Tugew') {
    return const MtTugewScreen(); // <--- IDINAGDAG: Buksan ang custom design layout ni Tugew!
  }
  if (mountain.name == 'Mt. Mariglem') {
    return const MtMariglemScreen(); // <--- IDINAGDAG: Buksan ang custom design layout ni Mariglem!
  }
  if (mountain.name == 'Mt. Cutuno') { // <--- BINAGO: Pure Cutuno action screen binding block
    return const MtCutunoScreen(); 
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