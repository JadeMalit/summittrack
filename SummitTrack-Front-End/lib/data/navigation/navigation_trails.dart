import '../../core/routing/app_routes.dart';
import '../../features/hike/utils/mountain_schedule_identity.dart';
import '../../data/trail_data/trail_data.dart';
import '../../data/trail_data/trail_gps_helper.dart';
import '../../models/hike_navigation_metadata.dart';
import '../../models/route_coordinate.dart';

class NavigationTrails {
  const NavigationTrails._();

  static const _pilotTrails = <String, HikeNavigationMetadata>{
    AppRoutes.staCruzTrailId: HikeNavigationMetadata(
      mountainId: AppRoutes.mtApoMountainId,
      trailId: AppRoutes.staCruzTrailId,
      trailName: 'Sta. Cruz / Sibulan Trail',
      destinationName: 'Mt. Apo Summit',
      destination: RouteCoordinate(latitude: 6.9875, longitude: 125.271),
      trailheadName: 'Baruring / Sibulan Trailhead',
      trailhead: RouteCoordinate(latitude: 6.95525, longitude: 125.32062),
      trailheadProximityRadiusMeters: 1500,
      isNavigationEnabled: true,
      validationNote:
          'Pilot navigation uses GraphHopper route data and the public Mt. Apo summit coordinate. Trailhead and checkpoint coordinates should still be validated with local guides before field use.',
    ),
  };

  static HikeNavigationMetadata? forTrailId(String photoId) {
    // Check pilot map first (preserve Mt. Apo pilot-specific behavior from stash)
    final normalizedKey = _normalizeTrailKey(photoId);
    final pilot = _pilotTrails[photoId] ?? _pilotTrails[normalizedKey];
    if (pilot != null) {
      return pilot;
    }

    switch (photoId) {
      // 🏔️ MT. BATULAO (THE SURE-FIRE DEMO CODE)

      // Start (Kubo 2 Area) -> End (Old Trail / Campsites)
      // 🏔️ MT. BATULAO (THE WORKING DEMO CODE - DO NOT TOUCH)
      case 'old_trail':
        return _build(
          'batulao',
          'old',
          'Batulao Old Trail',
          14.0410,
          120.8010,
          14.0326,
          120.8055,
        );
      // Start (Kubo 2 Area) -> End (New Trail / Peaks)
      case 'new_trail':
        return _build(
          'batulao',
          'new',
          'Batulao New Trail',
          14.0410,
          120.8010,
          14.0366,
          120.8070,
        );
      // 🏔️ MT. APO
      case 'sta_cruz_sibulan':
        return _build(
          AppRoutes.mtApoMountainId,
          'sta_cruz',
          'Sta. Cruz / Sibulan',
          6.9552,
          125.3206,
          6.9875,
          125.2710,
        );

      // 🏔️ MT. PULAG
      case 'ambangeg_trail':
        return _build(
          AppRoutes.mtPulagMountainId,
          'ambangeg',
          'Ambangeg Trail',
          16.5786,
          120.9038,
          16.5960,
          120.8985,
        );
      case 'akiki_trail':
        return _build(
          AppRoutes.mtPulagMountainId,
          'akiki',
          'Akiki Trail',
          16.6025,
          120.8407,
          16.5960,
          120.8985,
        );
      case 'tawangan_trail':
        return _build(
          AppRoutes.mtPulagMountainId,
          'tawangan',
          'Tawangan Trail',
          16.6120,
          120.9100,
          16.5960,
          120.8985,
        );
      case 'ambaguio_trail':
        return _build(
          AppRoutes.mtPulagMountainId,
          'ambaguio',
          'Ambaguio Trail',
          16.5210,
          120.9500,
          16.5960,
          120.8985,
        );

      // 🌋 MT. MAYON
      case 'buyohan_trail':
        return _build(
          'mayon',
          'buyohan',
          'Buyohan Trail',
          13.2200,
          123.6820,
          13.2500,
          123.6853,
        );
      case 'anoling_trail':
        return _build(
          'mayon',
          'anoling',
          'Anoling Trail',
          13.2384,
          123.6558,
          13.2500,
          123.6853,
        );
      case 'miisi_trail':
        return _build(
          'mayon',
          'miisi',
          'Miisi Trail',
          13.2300,
          123.6700,
          13.2500,
          123.6853,
        );
      case 'tobaco_trail':
        return _build(
          'mayon',
          'tobaco',
          'Tabaco Trail',
          13.3050,
          123.6620,
          13.2500,
          123.6853,
        ); // <-- NANDITO NA SIYA!
      // ☁️ MT. ULAP
      // MT. ULAP (Start: Ampucao Trailhead, End: Ambanao Paoay)
      case 'ambanao_trail':
        return _build(
          'ulap',
          'ambanao',
          'Ambanao Paoay',
          16.2908,
          120.6315,
          16.3020,
          120.6275,
        );
      case 'gungal_trail':
        return _build(
          'ulap',
          'gungal',
          'Gungal Rock',
          16.3100,
          120.6300,
          16.3248,
          120.6402,
        );
      case 'stafe_trail':
        return _build(
          'ulap',
          'stafe',
          'Sta. Fe Exit',
          16.3248,
          120.6402,
          16.3350,
          120.6510,
        );

      // 🌲 MT. DARAITAN
      case 'tinipak_river':
        return _build(
          'daraitan',
          'tinipak',
          'Tinipak River',
          14.6133,
          121.4116,
          14.6175,
          121.4140,
        );
      // case 'tinipak_river': return _build('daraitan', 'tinipak', 'Tinipak River', 14.6150, 121.3950, 14.6180, 121.4150); // Duplicate commented out to prevent compiler issues
      case 'daraitan_traverse':
        return _build(
          'daraitan',
          'traverse',
          'Daraitan Traverse',
          14.6133,
          121.3984,
          14.6180,
          121.4150,
        );

      // ⛰️ MT. MACULOT
      case 'maculot_rockies':
        return _build(
          'maculot',
          'rockies',
          'Maculot Rockies',
          13.9189,
          121.0505,
          13.9248,
          121.0423,
        );

      // Start (Jump-off) -> End (Yung nahanap mong Summit Coordinate!)
      case 'maculot_summit':
        return _build(
          'maculot',
          'summit',
          'Maculot Summit',
          13.9189,
          121.0505,
          13.919999,
          121.043522,
        );
      case 'maculot_traverse':
        return _build(
          'maculot',
          'traverse',
          'Maculot Traverse',
          13.9189,
          121.0505,
          13.9150,
          121.0430,
        );
      case 'maculot_airforce':
        return _build(
          'maculot',
          'airforce',
          'Airforce Trail',
          13.9100,
          121.0600,
          13.9213,
          121.0483,
        );

      // 🦜 MT. PICO DE LORO
      case 'pico_main':
        return _build(
          'picodeloro',
          'main',
          'Pico Main',
          14.2150,
          120.6450,
          14.2120,
          120.6350,
        );
      case 'pico_monolith':
        return _build(
          'picodeloro',
          'monolith',
          'Pico Monolith',
          14.2150,
          120.6450,
          14.2100,
          120.6330,
        );
      case 'pico_traverse':
        return _build(
          'picodeloro',
          'traverse',
          'Pico Traverse',
          14.2150,
          120.6450,
          14.2050,
          120.6300,
        );

      // 🌋 MT. PINATUBO
      case 'pinatubo_capas':
        return _build(
          'pinatubo',
          'capas',
          'Capas Trail',
          15.1500,
          120.4000,
          15.1420,
          120.3500,
        );
      case 'pinatubo_sapangbato':
        return _build(
          'pinatubo',
          'sapangbato',
          'Sapangbato Trail',
          15.1300,
          120.4100,
          15.1420,
          120.3500,
        );
      case 'pinatubo_porac':
        return _build(
          'pinatubo',
          'porac',
          'Porac Trail',
          15.1200,
          120.4200,
          15.1420,
          120.3500,
        );

      // 🏝️ MT. GUITING-GUITING
      case 'g2_tampayan':
        return _build(
          'guiting',
          'tampayan',
          'G2 Tampayan',
          12.4200,
          122.5400,
          12.4136,
          122.5694,
        );
      case 'g2_olango':
        return _build(
          'guiting',
          'olango',
          'G2 Olango',
          12.4000,
          122.5500,
          12.4136,
          122.5694,
        );
      case 'g2_traverse':
        return _build(
          'guiting',
          'traverse',
          'G2 Traverse',
          12.4200,
          122.5400,
          12.4000,
          122.5500,
        );

      // ✝️ MT. MANABU
      case 'manabu_main':
        return _build(
          'manabu',
          'main',
          'Manabu Main',
          13.9850,
          121.2150,
          13.9900,
          121.2100,
        );
      case 'manabu_grotto':
        return _build(
          'manabu',
          'grotto',
          'Manabu Grotto',
          13.9820,
          121.2180,
          13.9900,
          121.2100,
        );
      case 'manabu_traverse':
        return _build(
          'manabu',
          'traverse',
          'Manabu Traverse',
          13.9850,
          121.2150,
          13.9800,
          121.2050,
        );

      // 🐮 MT. GULUGOD BABOY
      case 'gulugod_anilao':
        return _build(
          'gulugodbaboy',
          'anilao',
          'Gulugod Anilao',
          13.6820,
          120.8950,
          13.6900,
          120.8900,
        );
      case 'gulugod_laurel':
        return _build(
          'gulugodbaboy',
          'laurel',
          'Gulugod Laurel',
          13.6800,
          120.8800,
          13.6900,
          120.8900,
        );
      case 'gulugod_santeodoro':
        return _build(
          'gulugodbaboy',
          'santeodoro',
          'San Teodoro',
          13.6880,
          120.8850,
          13.6900,
          120.8900,
        );
      case 'gulugod_campsite':
        return _build(
          'gulugodbaboy',
          'campsite',
          'Gulugod Campsite',
          13.6820,
          120.8950,
          13.6890,
          120.8920,
        );

      // 🌊 MT. MAYNOBA
      case 'maynoba_circuit':
        return _build(
          'maynoba',
          'circuit',
          'Maynoba Circuit',
          14.6850,
          121.3150,
          14.6900,
          121.3100,
        );
      case 'maynoba_waterfalls':
        return _build(
          'maynoba',
          'waterfalls',
          'Maynoba Waterfalls',
          14.6850,
          121.3150,
          14.6880,
          121.3120,
        );
      case 'maynoba_campsite':
        return _build(
          'maynoba',
          'campsite',
          'Maynoba Campsite',
          14.6850,
          121.3150,
          14.6890,
          121.3110,
        );
      case 'maynoba_traverse':
        return _build(
          'maynoba',
          'traverse',
          'Maynoba Traverse',
          14.6850,
          121.3150,
          14.6950,
          121.3050,
        );

      // 🏔️ MT. LINGGUHOB
      case 'lingguhob_bonbon':
        return _build(
          'lingguhob',
          'bonbon',
          'Lingguhob Bonbon',
          14.2850,
          121.2850,
          14.2900,
          121.2800,
        );
      case 'lingguhob_itisan':
        return _build(
          'lingguhob',
          'itisan',
          'Lingguhob Itisan',
          14.2800,
          121.2900,
          14.2900,
          121.2800,
        );
      case 'lingguhob_tuasan':
        return _build(
          'lingguhob',
          'tuasan',
          'Lingguhob Tuasan',
          14.2880,
          121.2880,
          14.2900,
          121.2800,
        );

      // ⛰️ MT. ARAYAT
      case 'arayat_sanjuan':
        return _build(
          'arayat',
          'sanjuan',
          'Arayat San Juan',
          15.1950,
          120.7500,
          15.2045,
          120.7410,
        );
      case 'arayat_magalang':
        return _build(
          'arayat',
          'magalang',
          'Arayat Magalang',
          15.2150,
          120.7300,
          15.2045,
          120.7410,
        );
      case 'arayat_traverse':
        return _build(
          'arayat',
          'traverse',
          'Arayat Traverse',
          15.1950,
          120.7500,
          15.2150,
          120.7300,
        );
      case 'arayat_pinnacle':
        return _build(
          'arayat',
          'pinnacle',
          'Arayat Pinnacle',
          15.1950,
          120.7500,
          15.2020,
          120.7450,
        );

      // 🌿 MT. MAKILING
      case 'makiling_uplb':
        return _build(
          'makiling',
          'uplb',
          'Makiling UPLB',
          14.1500,
          121.2200,
          14.1350,
          121.1960,
        );
      case 'makiling_traverse':
        return _build(
          'makiling',
          'traverse',
          'Makiling Traverse',
          14.1500,
          121.2200,
          14.1200,
          121.1800,
        );
      case 'makiling_mudsprings':
        return _build(
          'makiling',
          'mudsprings',
          'Makiling Mudsprings',
          14.1500,
          121.2200,
          14.1400,
          121.2100,
        );
      case 'makiling_flatrocks':
        return _build(
          'makiling',
          'flatrocks',
          'Makiling Flatrocks',
          14.1500,
          121.2200,
          14.1450,
          121.2150,
        );

      // ⛰️ MT. DAMAS
      case 'damas_papaac':
        return _build(
          'damas',
          'papaac',
          'Damas Papaac',
          15.5850,
          120.3850,
          15.5900,
          120.3800,
        );
      case 'damas_ubod':
        return _build(
          'damas',
          'ubod',
          'Damas Ubod',
          15.5800,
          120.3900,
          15.5900,
          120.3800,
        );
      case 'damas_dueg':
        return _build(
          'damas',
          'dueg',
          'Damas Dueg',
          15.5880,
          120.3880,
          15.5900,
          120.3800,
        );
      case 'damas_canding':
        return _build(
          'damas',
          'canding',
          'Damas Canding',
          15.5820,
          120.3820,
          15.5900,
          120.3800,
        );
      case 'damas_siwsiw':
        return _build(
          'damas',
          'siwsiw',
          'Damas Siwsiw',
          15.5870,
          120.3870,
          15.5900,
          120.3800,
        );

      // 🌲 MT. TUGEW
      case 'tugew_poblacion':
        return _build(
          'tugew',
          'poblacion',
          'Tugew Poblacion',
          16.7850,
          120.5850,
          16.7900,
          120.5800,
        );
      case 'tugew_amburayan':
        return _build(
          'tugew',
          'amburayan',
          'Tugew Amburayan',
          16.7800,
          120.5900,
          16.7900,
          120.5800,
        );
      case 'tugew_longog':
        return _build(
          'tugew',
          'longog',
          'Tugew Longog',
          16.7820,
          120.5880,
          16.7900,
          120.5800,
        );
      case 'tugew_gaddani':
        return _build(
          'tugew',
          'gaddani',
          'Tugew Gaddani',
          16.7880,
          120.5820,
          16.7900,
          120.5800,
        );
      case 'tugew_badi':
        return _build(
          'tugew',
          'badi',
          'Tugew Badi',
          16.7840,
          120.5840,
          16.7900,
          120.5800,
        );

      // 🌲 MT. MARIGLEM
      case 'mariglem_classic':
        return _build(
          'mariglem',
          'classic',
          'Mariglem Classic',
          14.9850,
          120.1850,
          14.9900,
          120.1800,
        );
      case 'mariglem_mapanuepe':
        return _build(
          'mariglem',
          'mapanuepe',
          'Mapanuepe Trail',
          14.9800,
          120.1900,
          14.9900,
          120.1800,
        );
      case 'mariglem_marella':
        return _build(
          'mariglem',
          'marella',
          'Marella Trail',
          14.9820,
          120.1880,
          14.9900,
          120.1800,
        );
      case 'mariglem_aglao':
        return _build(
          'mariglem',
          'aglao',
          'Aglao Trail',
          14.9880,
          120.1820,
          14.9900,
          120.1800,
        );
      case 'mariglem_consuelo':
        return _build(
          'mariglem',
          'consuelo',
          'Consuelo Trail',
          14.9840,
          120.1840,
          14.9900,
          120.1800,
        );

      // ⛰️ MT. CUTUNO
      case 'cutuno_summit':
        return _build(
          'cutuno',
          'summit',
          'Cutuno Summit',
          14.7850,
          121.2250,
          14.7900,
          121.2200,
        );
      case 'cutuno_lubog':
        return _build(
          'cutuno',
          'lubog',
          'Cutuno Lubog',
          14.7800,
          121.2300,
          14.7900,
          121.2200,
        );
      case 'cutuno_explorer':
        return _build(
          'cutuno',
          'explorer',
          'Explorer Trail',
          14.7820,
          121.2280,
          14.7900,
          121.2200,
        );
      case 'cutuno_river':
        return _build(
          'cutuno',
          'river',
          'River Trail',
          14.7880,
          121.2220,
          14.7900,
          121.2200,
        );
      case 'cutuno_cave':
        return _build(
          'cutuno',
          'cave',
          'Cave Trail',
          14.7840,
          121.2240,
          14.7900,
          121.2200,
        );

      default:
        return null; // Safe fallback
    }
  }

  static HikeNavigationMetadata? forTrail({
    required String mountainId,
    required String trailId,
    required TrailData trail,
  }) {
    final explicitMetadata = forTrailId(trailId);
    if (explicitMetadata != null) {
      return explicitMetadata;
    }

    final routeCoordinates = TrailGpsHelper.getGpsRouteForTrail(trail, trailId);
    if (routeCoordinates.length < 2) {
      return null;
    }

    final trailhead = routeCoordinates.first;
    final destination = routeCoordinates.last;
    final normalizedMountainId = MountainScheduleIdentity.normalizeMountainId(
      mountainId,
    );

    return HikeNavigationMetadata(
      mountainId: normalizedMountainId,
      trailId: trailId,
      trailName: trail.name,
      destinationName: _destinationName(
        normalizedMountainId: normalizedMountainId,
        trail: trail,
      ),
      destination: RouteCoordinate(
        latitude: destination.latitude,
        longitude: destination.longitude,
      ),
      trailheadName: _trailheadName(trail),
      trailhead: RouteCoordinate(
        latitude: trailhead.latitude,
        longitude: trailhead.longitude,
      ),
      isNavigationEnabled: true,
      validationNote:
          'Navigation uses SummitTrack trail route coordinates for this trail.',
    );
  }

  static String _normalizeTrailKey(String trailId) {
    return trailId.trim().toLowerCase().replaceAll('_', '-');
  }

  static String _destinationName({
    required String normalizedMountainId,
    required TrailData trail,
  }) {
    final mountainName = MountainScheduleIdentity.displayNameForMountainId(
      normalizedMountainId,
    );
    final trailName = trail.name.trim();

    if (trailName.toLowerCase().contains('summit')) {
      return trailName;
    }

    return '$mountainName Summit';
  }

  static String _trailheadName(TrailData trail) {
    final trailName = trail.name.trim();
    if (trailName.isEmpty) {
      return 'Selected trailhead';
    }

    return '$trailName Trailhead';
  }

  // ⚙️ HELPER WIDGET
  static HikeNavigationMetadata _build(
    String mountainId,
    String trailId,
    String name,
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return HikeNavigationMetadata(
      mountainId: mountainId,
      trailId: trailId,
      trailName: name,
      destinationName: 'Destination / Summit',
      destination: RouteCoordinate(latitude: endLat, longitude: endLng),
      trailheadName: 'Jump-off Point',
      trailhead: RouteCoordinate(latitude: startLat, longitude: startLng),
      trailheadProximityRadiusMeters: 5000,
      isNavigationEnabled: true,
      validationNote: 'Fully mapped for testing.',
    );
  }
}
