import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../data/trail_data/Sta.Cruz details.dart';
import '../state/app_mode_provider.dart';
import 'app_routes.dart';
import '../../features/auth/screens/SignIN_SignUP/pre_hike_loading_screen.dart';
import '../../features/auth/screens/SignIN_SignUP/signin.dart';
import '../../features/auth/screens/SignIN_SignUP/forgot_password_screen.dart';
import '../../features/auth/screens/SignIN_SignUP/register_screen.dart';
import '../../features/auth/widgets/video_background.dart';
import '../../features/navigation/button_functions/navbar_button_function.dart';
import '../../features/navigation/widgets/main_navigation_shell.dart';
import '../../features/mountains/screens/kapatagan_trail_details.dart';
import '../../features/mountains/screens/mt_apo.dart';
import '../../features/mountains/screens/mt_pulag.dart';
import '../../features/mountains/screens/mt_mayon.dart';
import '../../features/mountains/screens/mt_batulao.dart';
import '../../features/mountains/screens/mt_ulap.dart'; // <--- IMPORTS PARA KAY ULAP
import '../../features/mountains/screens/mt_daraitan.dart'; // <--- IDINAGDAG ANG IMPORT NI DARAITAN SCREEN
import '../../features/mountains/screens/mt_maculot.dart'; // <--- IDINAGDAG ANG IMPORT NI MACULOT SCREEN
import '../../features/mountains/screens/mt_pico_de_loro.dart'; // <--- IDINAGDAG ANG IMPORT NI PICO DE LORO SCREEN
import '../../features/mountains/screens/mt_pinatubo.dart'; // <--- IDINAGDAG ANG IMPORT NI PINATUBO SCREEN
import '../../features/mountains/screens/mt_guiting_guiting.dart'; // <--- IDINAGDAG ANG IMPORT NI GUITING-GUITING SCREEN
import '../../features/mountains/screens/mt_manabu.dart'; // <--- IDINAGDAG ANG IMPORT NI MANABU SCREEN
import '../../features/mountains/screens/mt_gulugod_baboy.dart'; // <--- IDINAGDAG ANG IMPORT NI GULUGOD BABOY SCREEN
import '../../features/mountains/screens/mt_maynoba.dart'; // <--- IDINAGDAG ANG IMPORT NI MAYNOBA SCREEN
import '../../features/mountains/screens/trail_detail_screen.dart';
import '../../data/trail_data/ambangeg_trail_data.dart';
import '../../data/trail_data/akiki_trail_data.dart';
import '../../data/trail_data/tawangan_trail_data.dart';
import '../../data/trail_data/ambaguio_trail_data.dart';
import '../../data/trail_data/buyohan_trail_data.dart';
import '../../data/trail_data/anoling_trail_data.dart';
import '../../data/trail_data/miisi_trail_data.dart';
import '../../data/trail_data/old_trail_data.dart';
import '../../data/trail_data/new_trail_data.dart';
import '../../data/trail_data/ambanao_paoay_data.dart'; // <--- BAGONG UTILS NI ULAP
import '../../data/trail_data/gungal_rock_data.dart';
import '../../data/trail_data/sta_fe_trail_data.dart';
import '../../data/trail_data/daraitan_summit_data.dart'; // <--- IDINAGDAG ANG UTILS NI DARAITAN
import '../../data/trail_data/tinipak_river_data.dart';
import '../../data/trail_data/daraitan_traverse_data.dart';
import '../../data/trail_data/maculot_rockies_data.dart'; // <--- IDINAGDAG ANG UTILS NI MACULOT
import '../../data/trail_data/maculot_summit_data.dart';
import '../../data/trail_data/maculot_traverse_data.dart';
import '../../data/trail_data/maculot_airforce_data.dart';
import '../../data/trail_data/pico_main_data.dart'; // <--- IDINAGDAG ANG UTILS NI PICO DE LORO
import '../../data/trail_data/pico_monolith_data.dart';
import '../../data/trail_data/pico_traverse_data.dart';
import '../../data/trail_data/pinatubo_capas_data.dart'; // <--- IDINAGDAG ANG UTILS NI MT. PINATUBO
import '../../data/trail_data/pinatubo_sapangbato_data.dart';
import '../../data/trail_data/pinatubo_porac_data.dart';
import '../../data/trail_data/g2_tampayan_data.dart'; // <--- IDINAGDAG ANG UTILS NI MT. GUITING-GUITING
import '../../data/trail_data/g2_olango_data.dart';
import '../../data/trail_data/g2_traverse_data.dart';
import '../../data/trail_data/manabu_main_data.dart'; // <--- IDINAGDAG ANG UTILS NI MT. MANABU
import '../../data/trail_data/manabu_grotto_data.dart';
import '../../data/trail_data/manabu_traverse_data.dart';
import '../../data/trail_data/gulugod_anilao_data.dart'; // <--- IDINAGDAG ANG UTILS NI MT. GULUGOD BABOY
import '../../data/trail_data/gulugod_laurel_data.dart';
import '../../data/trail_data/gulugod_san_teodoro_data.dart';
import '../../data/trail_data/gulugod_campsite_data.dart';
import '../../data/trail_data/maynoba_circuit_data.dart'; // <--- IDINAGDAG ANG UTILS NI MT. MAYNOBA
import '../../data/trail_data/maynoba_waterfalls_data.dart';
import '../../data/trail_data/maynoba_campsite_data.dart';
import '../../data/trail_data/maynoba_traverse_data.dart';
import '../../data/trail_data/catuno_summit_data.dart';
import '../../data/trail_data/catuno_lubog_data.dart';
import '../../data/trail_data/catuno_explorer_data.dart';
import '../../data/trail_data/catuno_river_data.dart';
import '../../features/mountains/screens/mt_catuno.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final location = AppRoutes.normalizeLocation(settings.name);
    final uri = Uri.parse(location);
    final segments = uri.pathSegments;

    if (uri.path == AppRoutes.home ||
        uri.path == '/home' ||
        uri.path == 'home') {
      return _route(
        settings,
        _AuthGuard(
          currentLocation: location,
          requireAuth: true,
          child: const MainNavigationShell(initialIndex: homeNavbarIndex),
        ),
      );
    }

    if (uri.path == AppRoutes.login) {
      return _authRoute(
        settings,
        _AuthGuard(
          currentLocation: location,
          requireAuth: false,
          child: SignInScreen(
            redirectTo: AppRoutes.redirectFromUri(uri) ?? AppRoutes.home,
          ),
        ),
      );
    }

    if (uri.path == AppRoutes.signup) {
      return _authRoute(
        settings,
        _AuthGuard(
          currentLocation: location,
          requireAuth: false,
          child: SignUpScreen(
            redirectTo: AppRoutes.redirectFromUri(uri) ?? AppRoutes.home,
          ),
        ),
      );
    }

    if (uri.path == '/forgot-password' || uri.path == 'forgot-password') {
      return _authRoute(
        settings,
        _AuthGuard(
          currentLocation: location,
          requireAuth: false,
          child: const ForgotPasswordScreen(),
        ),
      );
    }

    if (uri.path == AppRoutes.profile) {
      return _route(
        settings,
        _AuthGuard(
          currentLocation: location,
          requireAuth: true,
          child: const MainNavigationShell(initialIndex: profileNavbarIndex),
        ),
      );
    }

    if (uri.path == AppRoutes.weather) {
      return _route(
        settings,
        _AuthGuard(
          currentLocation: location,
          requireAuth: true,
          child: const MainNavigationShell(initialIndex: weatherNavbarIndex),
        ),
      );
    }

    if (uri.path == AppRoutes.settings) {
      return _route(
        settings,
        _AuthGuard(
          currentLocation: location,
          requireAuth: true,
          child: const MainNavigationShell(initialIndex: settingsNavbarIndex),
        ),
      );
    }

    if (segments.length == 2 && segments.first == 'mountain') {
      final mountainId = segments[1];

      if (mountainId == AppRoutes.mtApoMountainId) {
        return _route(
          settings,
          _AuthGuard(
            currentLocation: location,
            requireAuth: true,
            child: const MtApoScreen(),
          ),
        );
      }

      if (mountainId == AppRoutes.mtPulagMountainId) {
        return _route(
          settings,
          _AuthGuard(
            currentLocation: location,
            requireAuth: true,
            child: const MtPulagScreen(),
          ),
        );
      }

      if (mountainId.toLowerCase().contains('mayon')) {
        return _route(
          settings,
          _AuthGuard(
            currentLocation: location,
            requireAuth: true,
            child: const MtMayonScreen(),
          ),
        );
      }

      if (mountainId.toLowerCase().contains('batulao')) {
        return _route(
          settings,
          _AuthGuard(
            currentLocation: location,
            requireAuth: true,
            child: const MtBatulaoScreen(),
          ),
        );
      }

      if (mountainId.toLowerCase().contains('ulap')) {
        return _route(
          settings,
          _AuthGuard(
            currentLocation: location,
            requireAuth: true,
            child: const MtUlapScreen(),
          ),
        );
      }

      if (mountainId.toLowerCase().contains('daraitan')) {
        return _route(
          settings,
          _AuthGuard(
            currentLocation: location,
            requireAuth: true,
            child: const MtDaraitanScreen(),
          ),
        );
      }

      if (mountainId.toLowerCase().contains('maculot')) {
        return _route(
          settings,
          _AuthGuard(
            currentLocation: location,
            requireAuth: true,
            child: const MtMaculotScreen(),
          ),
        );
      }

      if (mountainId.toLowerCase().contains('picodeloro')) {
        return _route(
          settings,
          _AuthGuard(
            currentLocation: location,
            requireAuth: true,
            child: const MtPicoDeLoroScreen(),
          ),
        );
      }

      if (mountainId.toLowerCase().contains('pinatubo')) {
        return _route(
          settings,
          _AuthGuard(
            currentLocation: location,
            requireAuth: true,
            child: const MtPinatuboScreen(),
          ),
        );
      }

      if (mountainId.toLowerCase() == 'g2' ||
          mountainId.toLowerCase().contains('guiting')) {
        return _route(
          settings,
          _AuthGuard(
            currentLocation: location,
            requireAuth: true,
            child: const MtGuitingGuitingScreen(),
          ),
        );
      }

      if (mountainId.toLowerCase().contains('manabu')) {
        return _route(
          settings,
          _AuthGuard(
            currentLocation: location,
            requireAuth: true,
            child: const MtManabuScreen(),
          ),
        );
      }

      if (mountainId.toLowerCase().contains('gulugod') || mountainId.toLowerCase().contains('baboy')) {
        return _route(
          settings,
          _AuthGuard(
            currentLocation: location,
            requireAuth: true,
            child: const MtGulugodBaboyScreen(),
          ),
        );
      }

      if (mountainId.toLowerCase().contains('maynoba')) {
        return _route(
          settings,
          _AuthGuard(
            currentLocation: location,
            requireAuth: true,
            child: const MtMaynobaScreen(),
          ),
        );
      }

      if (mountainId.toLowerCase().contains('catuno') || mountainId.toLowerCase().contains('katingno') || mountainId.toLowerCase().contains('cutuno')) {
        return _route(
          settings,
          _AuthGuard(
            currentLocation: location,
            requireAuth: true,
            child: const MtCatunoScreen(),
          ),
        );
      }
    }

    if (segments.length == 4 &&
        segments.first == 'mountain' &&
        segments[2] == 'trail') {
      final mountainId = segments[1];
      final trailId = segments[3];

      if (mountainId.toLowerCase().contains('catuno') || mountainId.toLowerCase().contains('katingno') || mountainId.toLowerCase().contains('cutuno')) {
        if (trailId == 'summit') return _route(settings, _AuthGuard(currentLocation: location, requireAuth: true, child: TrailDetailScreen(trail: catunoSummitTrail, parentRoute: AppRoutes.mountain(mountainId), trailPhotoId: 'catuno_summit')));
        if (trailId == 'lubog') return _route(settings, _AuthGuard(currentLocation: location, requireAuth: true, child: TrailDetailScreen(trail: catunoLubogTrail, parentRoute: AppRoutes.mountain(mountainId), trailPhotoId: 'catuno_lubog')));
        if (trailId == 'explorer') return _route(settings, _AuthGuard(currentLocation: location, requireAuth: true, child: TrailDetailScreen(trail: catunoExplorerTrail, parentRoute: AppRoutes.mountain(mountainId), trailPhotoId: 'catuno_explorer')));
        if (trailId == 'river') return _route(settings, _AuthGuard(currentLocation: location, requireAuth: true, child: TrailDetailScreen(trail: catunoRiverTrail, parentRoute: AppRoutes.mountain(mountainId), trailPhotoId: 'catuno_river')));
      }

      if (mountainId == AppRoutes.mtApoMountainId &&
          trailId == AppRoutes.staCruzTrailId) {
        return _route(
          settings,
          _AuthGuard(
            currentLocation: location,
            requireAuth: true,
            child: TrailDetailScreen(
              trail: staCruzSibulanTrail,
              parentRoute: AppRoutes.mountain(mountainId),
            ),
          ),
        );
      }

      if (mountainId == AppRoutes.mtApoMountainId &&
          trailId == AppRoutes.kapataganTrailId) {
        return _route(
          settings,
          _AuthGuard(
            currentLocation: location,
            requireAuth: true,
            child: const KapataganTrailDetailsScreen(),
          ),
        );
      }

      if (mountainId == AppRoutes.mtPulagMountainId && trailId == 'ambangeg') {
        return _route(
          settings,
          _AuthGuard(
            currentLocation: location,
            requireAuth: true,
            child: TrailDetailScreen(
              trail: ambangegTrail,
              parentRoute: AppRoutes.mountain(mountainId),
              trailPhotoId: 'ambangeg_trail',
            ),
          ),
        );
      }

      if (mountainId == AppRoutes.mtPulagMountainId && trailId == 'akiki') {
        return _route(
          settings,
          _AuthGuard(
            currentLocation: location,
            requireAuth: true,
            child: TrailDetailScreen(
              trail: akikiTrail,
              parentRoute: AppRoutes.mountain(mountainId),
              trailPhotoId: 'akiki_trail',
            ),
          ),
        );
      }

      if (mountainId == AppRoutes.mtPulagMountainId && trailId == 'tawangan') {
        return _route(
          settings,
          _AuthGuard(
            currentLocation: location,
            requireAuth: true,
            child: TrailDetailScreen(
              trail: tawanganTrail,
              parentRoute: AppRoutes.mountain(mountainId),
              trailPhotoId: 'tawangan_trail',
            ),
          ),
        );
      }

      if (mountainId == AppRoutes.mtPulagMountainId && trailId == 'ambaguio') {
        return _route(
          settings,
          _AuthGuard(
            currentLocation: location,
            requireAuth: true,
            child: TrailDetailScreen(
              trail: ambaguioTrail,
              parentRoute: AppRoutes.mountain(mountainId),
              trailPhotoId: 'ambaguio_trail',
            ),
          ),
        );
      }

      if (mountainId.toLowerCase().contains('mayon')) {
        if (trailId == 'buyohan') {
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: buyohanTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'buyohan_trail',
              ),
            ),
          );
        }

        if (trailId == 'anoling') {
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: anolingTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'anoling_trail',
              ),
            ),
          );
        }

        if (trailId == 'miisi') {
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: miisiTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'miisi_trail',
              ),
            ),
          );
        }

        if (trailId == 'tabaco') {
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: buyohanTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'buyohan_trail',
              ),
            ),
          );
        }
      }

      if (mountainId.toLowerCase().contains('batulao')) {
        if (trailId == 'old') {
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: oldTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'old_trail',
              ),
            ),
          );
        }

        if (trailId == 'new') {
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: newTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'new_trail',
              ),
            ),
          );
        }
      }

      if (mountainId.toLowerCase().contains('ulap')) {
        if (trailId == 'ambanao') {
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: ambanaoPaoayTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'ambanao_trail',
              ),
            ),
          );
        }

        if (trailId == 'gungal') {
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: gungalRockTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'gungal_trail',
              ),
            ),
          );
        }

        if (trailId == 'stafe') {
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: staFeTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'stafe_trail',
              ),
            ),
          );
        }
      }

      if (mountainId.toLowerCase().contains('daraitan')) {
        if (trailId == 'summit') {
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: daraitanSummitTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'daraitan_summit',
              ),
            ),
          );
        }

        if (trailId == 'tinipak') {
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: tinipakRiverTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'tinipak_river',
              ),
            ),
          );
        }

        if (trailId == 'traverse') {
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: daraitanTraverseTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'daraitan_traverse',
              ),
            ),
          );
        }
      }

      if (mountainId.toLowerCase().contains('maculot')) {
        if (trailId == 'rockies') {
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: maculotRockiesTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'maculot_rockies',
              ),
            ),
          );
        }

        if (trailId == 'summit') {
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: maculotSummitTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'maculot_summit',
              ),
            ),
          );
        }

        if (trailId == 'traverse') {
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: maculotTraverseTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'maculot_traverse',
              ),
            ),
          );
        }

        if (trailId == 'airforce') {
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: maculotAirForceTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'maculot_airforce',
              ),
            ),
          );
        }
      }

      if (mountainId.toLowerCase().contains('picodeloro')) {
        if (trailId == 'main') {
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: picoMainTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'pico_main',
              ),
            ),
          );
        }

        if (trailId == 'monolith') {
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: picoMonolithTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'pico_monolith',
              ),
            ),
          );
        }

        if (trailId == 'traverse') {
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: picoTraverseTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'pico_traverse',
              ),
            ),
          );
        }
      }

      if (mountainId.toLowerCase().contains('pinatubo')) {
        if (trailId == 'capas') {
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: pinatuboCapasTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'pinatubo_capas',
              ),
            ),
          );
        }

        if (trailId == 'sapangbato') {
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: pinatuboSapangbatoTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'pinatubo_sapangbato',
              ),
            ),
          );
        }

        if (trailId == 'porac') {
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: pinatuboPoracTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'pinatubo_porac',
              ),
            ),
          );
        }
      }

      if (mountainId.toLowerCase() == 'g2' ||
          mountainId.toLowerCase().contains('guiting')) {
        if (trailId == 'tampayan') {
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: g2TampayanTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'g2_tampayan',
              ),
            ),
          );
        }

        if (trailId == 'olango') {
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: g2OlangoTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'g2_olango',
              ),
            ),
          );
        }

        if (trailId == 'traverse') {
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: g2TraverseTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'g2_traverse',
              ),
            ),
          );
        }
      }

      if (mountainId.toLowerCase().contains('manabu')) {
        if (trailId == 'main') {
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: manabuMainTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'manabu_main',
              ),
            ),
          );
        }

        if (trailId == 'grotto') {
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: manabuGrottoTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'manabu_grotto',
              ),
            ),
          );
        }

        if (trailId == 'traverse') {
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: manabuTraverseTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'manabu_traverse',
              ),
            ),
          );
        }
      }

      if (mountainId.toLowerCase().contains('gulugod') || mountainId.toLowerCase().contains('baboy')) {
        if (trailId == 'anilao') {
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: gulugodAnilaoTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'gulugod_anilao',
              ),
            ),
          );
        }

        if (trailId == 'laurel') {
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: gulugodLaurelTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'gulugod_laurel',
              ),
            ),
          );
        }

        if (trailId == 'santeodoro') {
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: gulugodSanTeodoroTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'gulugod_santeodoro',
              ),
            ),
          );
        }

        if (trailId == 'campsite') {
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: gulugodCampsiteTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'gulugod_campsite',
              ),
            ),
          );
        }
      }

      if (mountainId.toLowerCase().contains('maynoba')) {
        if (trailId == 'circuit') {
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: maynobaCircuitTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'maynoba_circuit',
              ),
            ),
          );
        }

        if (trailId == 'waterfalls') {
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: maynobaWaterfallsTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'maynoba_waterfalls',
              ),
            ),
          );
        }

        if (trailId == 'campsite') {
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: maynobaCampsiteTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'maynoba_campsite',
              ),
            ),
          );
        }

        if (trailId == 'traverse') {
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: maynobaTraverseTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'maynoba_traverse',
              ),
            ),
          );
        }
      }
    }

    return onUnknownRoute(settings);
  }

  static List<Route<dynamic>> onGenerateInitialRoutes(String initialRoute) {
    return [onGenerateRoute(RouteSettings(name: initialRoute))];
  }

  static Route<dynamic> onUnknownRoute(RouteSettings settings) {
    return _route(
      settings,
      _UnknownRouteScreen(
        attemptedLocation: AppRoutes.normalizeLocation(settings.name),
      ),
    );
  }

  static PageRouteBuilder<dynamic> _authRoute(
    RouteSettings settings,
    Widget child,
  ) {
    return PageRouteBuilder<dynamic>(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 160),
      reverseTransitionDuration: const Duration(milliseconds: 120),
      pageBuilder: (_, __, ___) => ColoredBox(
        color: VideoBackground.fallbackBackgroundColor,
        child: child,
      ),
      transitionsBuilder: (_, animation, __, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        final slideAnimation = Tween<Offset>(
          begin: const Offset(0.02, 0),
          end: Offset.zero,
        ).animate(curvedAnimation);

        return FadeTransition(
          opacity: curvedAnimation,
          child: SlideTransition(position: slideAnimation, child: child),
        );
      },
    );
  }

  static MaterialPageRoute<dynamic> _route(
    RouteSettings settings,
    Widget child,
  ) {
    return MaterialPageRoute<dynamic>(
      settings: settings,
      builder: (_) => child,
    );
  }
}

Future<void>? _authBootstrapFuture;
bool _authBootstrapComplete = false;

Future<void> _ensureAuthBootstrap() {
  if (_authBootstrapComplete) {
    return SynchronousFuture<void>(null);
  }

  return _authBootstrapFuture ??= _bootstrapAuth().then<void>((_) {
    _authBootstrapComplete = true;
  });
}

Future<void> _bootstrapAuth() async {
  final auth = FirebaseAuth.instance;

  if (kIsWeb) {
    await auth.setPersistence(Persistence.LOCAL);
  }

  if (auth.currentUser != null) {
    return;
  }

  await auth.authStateChanges().first;
}

class _AuthGuard extends StatefulWidget {
  const _AuthGuard({
    required this.currentLocation,
    required this.requireAuth,
    required this.child,
  });

  final String currentLocation;
  final bool requireAuth;
  final Widget child;

  @override
  State<_AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<_AuthGuard> {
  Future<void>? _bootstrapFuture;
  late final bool _bootstrapAlreadyComplete;

  @override
  void initState() {
    super.initState();
    final isOfflineMode = AppModeProvider.instance.isOfflineMode;
    _bootstrapAlreadyComplete = _authBootstrapComplete || isOfflineMode;
    if (!_bootstrapAlreadyComplete && !isOfflineMode) {
      _bootstrapFuture = _ensureAuthBootstrap();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (AppModeProvider.instance.isOfflineMode) {
      return _buildWithOfflineMode();
    }

    if (_bootstrapAlreadyComplete) {
      return _buildWithAuthState();
    }

    return FutureBuilder<void>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _AuthLoadingScreen();
        }

        return _buildWithAuthState();
      },
    );
  }

  Widget _buildWithOfflineMode() {
    if (AppModeProvider.instance.isRouteAllowedInOfflineMode(
      widget.currentLocation,
    )) {
      return widget.child;
    }

    return const _OfflineRestrictedRouteScreen();
  }

  Widget _buildWithAuthState() {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      initialData: FirebaseAuth.instance.currentUser,
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;

        if (widget.requireAuth) {
          if (user != null) {
            return widget.child;
          }

          return _RouteRedirect(
            targetLocation: AppRoutes.loginWithRedirect(widget.currentLocation),
          );
        }

        if (user != null) {
          final path = Uri.parse(
            AppRoutes.normalizeLocation(widget.currentLocation),
          ).path;
          final shouldShowSignInAfterOfflineMode =
              path == AppRoutes.login &&
              AppModeProvider.instance.shouldShowSignInAfterOfflineMode;

          if (PreHikeLoginTransition.isActive ||
              RegistrationAuthFlow.isActive ||
              shouldShowSignInAfterOfflineMode) {
            return widget.child;
          }

          return _RouteRedirect(targetLocation: AppRoutes.home);
        }

        return widget.child;
      },
    );
  }
}

class _OfflineRestrictedRouteScreen extends StatefulWidget {
  const _OfflineRestrictedRouteScreen();

  @override
  State<_OfflineRestrictedRouteScreen> createState() =>
      _OfflineRestrictedRouteScreenState();
}

class _OfflineRestrictedRouteScreenState
    extends State<_OfflineRestrictedRouteScreen> {
  bool _handled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_handled) {
      return;
    }

    _handled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
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

      if (!mounted) {
        return;
      }

      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const _AuthLoadingScreen();
  }
}

class _RouteRedirect extends StatefulWidget {
  const _RouteRedirect({required this.targetLocation});

  final String targetLocation;

  @override
  State<_RouteRedirect> createState() => _RouteRedirectState();
}

class _RouteRedirectState extends State<_RouteRedirect> {
  bool _redirected = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_redirected) {
      return;
    }

    _redirected = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      Navigator.of(context).pushReplacementNamed(widget.targetLocation);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const _AuthLoadingScreen();
  }
}

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: VideoBackground.fallbackBackgroundColor,
      body: Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }
}

class _UnknownRouteScreen extends StatelessWidget {
  const _UnknownRouteScreen({required this.attemptedLocation});

  final String attemptedLocation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page not found')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.map_outlined, size: 54),
              const SizedBox(height: 16),
              Text(
                'No screen is registered for "$attemptedLocation".',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed(AppRoutes.home);
                },
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}