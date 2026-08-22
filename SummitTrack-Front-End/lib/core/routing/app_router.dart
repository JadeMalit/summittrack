import '../../features/mountains/screens/live_hike_viewer_screen.dart';
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
import '../../models/hike_navigation_start_request.dart';
import '../../screens/navigation/graphhopper_connection_test_screen.dart';
import '../../screens/navigation/hike_navigation_screen.dart';
import '../../features/mountains/screens/kapatagan_trail_details.dart';
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
import '../../data/trail_data/ambanao_paoay_data.dart';
import '../../data/trail_data/gungal_rock_data.dart';
import '../../data/trail_data/sta_fe_trail_data.dart';
import '../../data/trail_data/daraitan_summit_data.dart';
import '../../data/trail_data/tinipak_river_data.dart';
import '../../data/trail_data/daraitan_traverse_data.dart';
import '../../data/trail_data/maculot_rockies_data.dart';
import '../../data/trail_data/maculot_summit_data.dart';
import '../../data/trail_data/maculot_traverse_data.dart';
import '../../data/trail_data/maculot_airforce_data.dart';
import '../../data/trail_data/pico_main_data.dart';
import '../../data/trail_data/pico_monolith_data.dart';
import '../../data/trail_data/pico_traverse_data.dart';
import '../../data/trail_data/pinatubo_capas_data.dart';
import '../../data/trail_data/pinatubo_sapangbato_data.dart';
import '../../data/trail_data/pinatubo_porac_data.dart';
import '../../data/trail_data/g2_tampayan_data.dart';
import '../../data/trail_data/g2_olango_data.dart';
import '../../data/trail_data/g2_traverse_data.dart';
import '../../data/trail_data/manabu_main_data.dart';
import '../../data/trail_data/manabu_grotto_data.dart';
import '../../data/trail_data/manabu_traverse_data.dart';
import '../../data/trail_data/gulugod_anilao_data.dart';
import '../../data/trail_data/gulugod_laurel_data.dart';
import '../../data/trail_data/gulugod_san_teodoro_data.dart';
import '../../data/trail_data/gulugod_campsite_data.dart';
import '../../data/trail_data/maynoba_circuit_data.dart';
import '../../data/trail_data/maynoba_waterfalls_data.dart';
import '../../data/trail_data/maynoba_campsite_data.dart';
import '../../data/trail_data/maynoba_traverse_data.dart';
import '../../data/trail_data/lingguhob_trails.dart';
import '../../features/mountains/screens/mt_lingguhob.dart';
import '../../data/trail_data/arayat_trails.dart';
import '../../features/mountains/screens/mt_arayat.dart';
import '../../data/trail_data/makiling_trails.dart';
import '../../features/mountains/screens/mt_makiling.dart';
import '../../data/trail_data/damas_trails.dart';
import '../../features/mountains/screens/mt_damas.dart';
import '../../data/trail_data/tugew_trails.dart';
import '../../features/mountains/screens/mt_tugew.dart';
import '../../data/trail_data/mariglem_trails.dart';
import '../../features/mountains/screens/mt_mariglem.dart';
import '../../data/trail_data/cutuno_trails.dart';
import '../../features/mountains/screens/mt_cutuno.dart';

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

    if (uri.path == AppRoutes.hikeNavigation) {
      final startRequest = settings.arguments is HikeNavigationStartRequest
          ? settings.arguments as HikeNavigationStartRequest
          : null;

      return _route(
        settings,
        HikeNavigationScreen(startRequest: startRequest),
      );
    }

    if (kDebugMode && uri.path == AppRoutes.graphHopperConnectionTest) {
      return _route(settings, const GraphHopperConnectionTestScreen());
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

      if (mountainId.toLowerCase().contains('gulugod') ||
          mountainId.toLowerCase().contains('baboy')) {
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

      if (mountainId.toLowerCase().contains('lingguhob')) {
        return _route(
          settings,
          _AuthGuard(
            currentLocation: location,
            requireAuth: true,
            child: const MtLingguhobScreen(),
          ),
        );
      }

      if (mountainId.toLowerCase().contains('arayat')) {
        return _route(
          settings,
          _AuthGuard(
            currentLocation: location,
            requireAuth: true,
            child: const MtArayatScreen(),
          ),
        );
      }

      if (mountainId.toLowerCase().contains('makiling')) {
        return _route(
          settings,
          _AuthGuard(
            currentLocation: location,
            requireAuth: true,
            child: const MtMakilingScreen(),
          ),
        );
      }

      if (mountainId.toLowerCase().contains('damas')) {
        return _route(
          settings,
          _AuthGuard(
            currentLocation: location,
            requireAuth: true,
            child: const MtDamasScreen(),
          ),
        );
      }

      if (mountainId.toLowerCase().contains('tugew')) {
        return _route(
          settings,
          _AuthGuard(
            currentLocation: location,
            requireAuth: true,
            child: const MtTugewScreen(),
          ),
        );
      }

      if (mountainId.toLowerCase().contains('mariglem')) {
        return _route(
          settings,
          _AuthGuard(
            currentLocation: location,
            requireAuth: true,
            child: const MtMariglemScreen(),
          ),
        );
      }

      if (mountainId.toLowerCase().contains('cutuno')) {
        return _route(
          settings,
          _AuthGuard(
            currentLocation: location,
            requireAuth: true,
            child: const MtCutunoScreen(),
          ),
        );
      }
    }

    if (segments.length == 4 &&
        segments.first == 'mountain' &&
        segments[2] == 'trail') {
      final mountainId = segments[1];
      final trailId = segments[3];

      if (mountainId.toLowerCase().contains('lingguhob')) {
        if (trailId == 'bonbon')
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: lingguhobBonbonTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'lingguhob_bonbon',
                navigationTrailId: trailId,
              ),
            ),
          );
        if (trailId == 'itisan')
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: lingguhobItisanTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'lingguhob_itisan',
                navigationTrailId: trailId,
              ),
            ),
          );
        if (trailId == 'tuasan')
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: lingguhobTuasanTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'lingguhob_tuasan',
                navigationTrailId: trailId,
              ),
            ),
          );
      }

      if (mountainId.toLowerCase().contains('arayat')) {
        if (trailId == 'sanjuan')
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: arayatSanJuanTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'arayat_sanjuan',
                navigationTrailId: trailId,
              ),
            ),
          );
        if (trailId == 'magalang')
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: arayatMagalangTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'arayat_magalang',
                navigationTrailId: trailId,
              ),
            ),
          );
        if (trailId == 'traverse')
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: arayatTraverseTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'arayat_traverse',
                navigationTrailId: trailId,
              ),
            ),
          );
        if (trailId == 'pinnacle')
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: arayatPinnacleTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'arayat_pinnacle',
                navigationTrailId: trailId,
              ),
            ),
          );
      }

      if (mountainId.toLowerCase().contains('makiling')) {
        if (trailId == 'uplb')
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: makilingUplbTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'makiling_uplb',
                navigationTrailId: trailId,
              ),
            ),
          );
        if (trailId == 'traverse')
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: makilingTraverseTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'makiling_traverse',
                navigationTrailId: trailId,
              ),
            ),
          );
        if (trailId == 'mudsprings')
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: makilingMudspringsTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'makiling_mudsprings',
                navigationTrailId: trailId,
              ),
            ),
          );
        if (trailId == 'flatrocks')
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: makilingFlatrocksTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'makiling_flatrocks',
                navigationTrailId: trailId,
              ),
            ),
          );
      }

      if (mountainId.toLowerCase().contains('damas')) {
        if (trailId == 'papaac')
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: damasPapaacTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'damas_papaac',
                navigationTrailId: trailId,
              ),
            ),
          );
        if (trailId == 'ubod')
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: damasUbodTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'damas_ubod',
                navigationTrailId: trailId,
              ),
            ),
          );
        if (trailId == 'dueg')
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: damasDuegTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'damas_dueg',
                navigationTrailId: trailId,
              ),
            ),
          );
        if (trailId == 'canding')
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: damasCandingTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'damas_canding',
                navigationTrailId: trailId,
              ),
            ),
          );
        if (trailId == 'siwsiw')
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: damasSiwsiwTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'damas_siwsiw',
                navigationTrailId: trailId,
              ),
            ),
          );
      }

      if (mountainId.toLowerCase().contains('tugew')) {
        if (trailId == 'poblacion')
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: tugewPoblacionTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'tugew_poblacion',
                navigationTrailId: trailId,
              ),
            ),
          );
        if (trailId == 'amburayan')
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: tugewAmburayanTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'tugew_amburayan',
                navigationTrailId: trailId,
              ),
            ),
          );
        if (trailId == 'longog')
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: tugewLongogTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'tugew_longog',
                navigationTrailId: trailId,
              ),
            ),
          );
        if (trailId == 'gaddani')
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: tugewGaddaniTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'tugew_gaddani',
                navigationTrailId: trailId,
              ),
            ),
          );
        if (trailId == 'badi')
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: tugewBadiTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'tugew_badi',
                navigationTrailId: trailId,
              ),
            ),
          );
      }

      if (mountainId.toLowerCase().contains('mariglem')) {
        if (trailId == 'classic')
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: mariglemClassicTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'mariglem_classic',
                navigationTrailId: trailId,
              ),
            ),
          );
        if (trailId == 'mapanuepe')
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: mariglemMapanuepeTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'mariglem_mapanuepe',
                navigationTrailId: trailId,
              ),
            ),
          );
        if (trailId == 'marella')
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: mariglemMarellaTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'mariglem_marella',
                navigationTrailId: trailId,
              ),
            ),
          );
        if (trailId == 'aglao')
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: mariglemAglaoTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'mariglem_aglao',
                navigationTrailId: trailId,
              ),
            ),
          );
        if (trailId == 'consuelo')
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: mariglemConsueloTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'mariglem_consuelo',
                navigationTrailId: trailId,
              ),
            ),
          );
      }

      if (mountainId.toLowerCase().contains('cutuno')) {
        if (trailId == 'summit')
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: cutunoSummitTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'cutuno_summit',
                navigationTrailId: trailId,
              ),
            ),
          );
        if (trailId == 'lubog')
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: cutunoLubogTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'cutuno_lubog',
                navigationTrailId: trailId,
              ),
            ),
          );
        if (trailId == 'explorer')
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: cutunoExplorerTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'cutuno_explorer',
                navigationTrailId: trailId,
              ),
            ),
          );
        if (trailId == 'river')
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: cutunoRiverTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'cutuno_river',
                navigationTrailId: trailId,
              ),
            ),
          );
        if (trailId == 'cave')
          return _route(
            settings,
            _AuthGuard(
              currentLocation: location,
              requireAuth: true,
              child: TrailDetailScreen(
                trail: cutunoCaveTrail,
                parentRoute: AppRoutes.mountain(mountainId),
                trailPhotoId: 'cutuno_cave',
                navigationTrailId: trailId,
              ),
            ),
          );
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
              navigationTrailId: AppRoutes.staCruzTrailId,
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
              navigationTrailId: trailId,
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
              navigationTrailId: trailId,
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
              navigationTrailId: trailId,
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
              navigationTrailId: trailId,
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
                navigationTrailId: trailId,
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
                navigationTrailId: trailId,
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
                navigationTrailId: trailId,
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
                navigationTrailId: trailId,
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
                navigationTrailId: trailId,
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
                navigationTrailId: trailId,
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
                navigationTrailId: trailId,
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
                navigationTrailId: trailId,
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
                navigationTrailId: trailId,
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
                navigationTrailId: trailId,
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
                navigationTrailId: trailId,
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
                navigationTrailId: trailId,
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
                navigationTrailId: trailId,
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
                navigationTrailId: trailId,
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
                navigationTrailId: trailId,
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
                navigationTrailId: trailId,
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
                navigationTrailId: trailId,
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
                navigationTrailId: trailId,
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
                navigationTrailId: trailId,
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
                navigationTrailId: trailId,
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
                navigationTrailId: trailId,
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
                navigationTrailId: trailId,
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
                navigationTrailId: trailId,
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
                navigationTrailId: trailId,
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
                navigationTrailId: trailId,
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
                navigationTrailId: trailId,
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
                navigationTrailId: trailId,
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
                navigationTrailId: trailId,
              ),
            ),
          );
        }
      }

      if (mountainId.toLowerCase().contains('gulugod') ||
          mountainId.toLowerCase().contains('baboy')) {
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
                navigationTrailId: trailId,
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
                navigationTrailId: trailId,
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
                navigationTrailId: trailId,
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
                navigationTrailId: trailId,
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
                navigationTrailId: trailId,
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
                navigationTrailId: trailId,
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
                navigationTrailId: trailId,
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
                navigationTrailId: trailId,
              ),
            ),
          );
        }
      }
    }

    // ============================================================
    // 🛰️ PUBLIC LIVE HIKE TRACKING
    // ============================================================
    if (uri.path == AppRoutes.liveTrack) {
      final String hikeId = uri.queryParameters['hikeId']?.trim() ?? '';

      debugPrint(
        '[TRACK DEBUG] /track matched | '
        'location="$location" | '
        'hikeId="$hikeId"',
      );

      if (hikeId.isNotEmpty) {
        return _route(settings, LiveHikeViewerScreen(hikeId: hikeId));
      }

      debugPrint('[TRACK DEBUG] /track rejected: missing hikeId');
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