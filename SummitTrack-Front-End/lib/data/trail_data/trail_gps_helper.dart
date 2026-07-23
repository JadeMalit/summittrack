import 'package:latlong2/latlong.dart';
import 'trail_data.dart';

class TrailGpsHelper {
  /// Kukuha ng totoong GPS coordinates para sa 20+ Mountains o gagamit ng Smart Region Fallback
  static List<LatLng> getGpsRouteForTrail(TrailData trail, String photoId) {
    final id = photoId.toLowerCase();
    final name = trail.name.toLowerCase();
    final location = trail.location.toLowerCase();

    // 🌋 1. MT. APO (Davao / Cotabato)
    if (id.contains('apo') || id.contains('sta_cruz') || id.contains('kapatagan') || name.contains('apo')) {
      return const [
        LatLng(7.0050, 125.2600),
        LatLng(7.0110, 125.2660),
        LatLng(7.0180, 125.2720),
        LatLng(7.0235, 125.2790),
        LatLng(7.0280, 125.2845),
        LatLng(7.0298, 125.2872),
      ];
    }

    // 🌾 2. MT. PULAG (Benguet - Ambangeg, Akiki, Tawangan, Ambaguio)
    if (id.contains('pulag') || id.contains('ambangeg') || id.contains('akiki') || id.contains('tawangan') || id.contains('ambaguio') || name.contains('pulag')) {
      return const [
        LatLng(16.5820, 120.8810),
        LatLng(16.5890, 120.8880),
        LatLng(16.5950, 120.8930),
        LatLng(16.5985, 120.8990),
      ];
    }

    // 🌋 3. MT. MAYON (Albay - Tabaco, Buyohan)
    if (id.contains('mayon') || id.contains('tabaco') || id.contains('buyohan') || name.contains('mayon')) {
      return const [
        LatLng(13.2510, 123.6820),
        LatLng(13.2530, 123.6850),
        LatLng(13.2560, 123.6880),
        LatLng(13.2570, 123.6858),
      ];
    }

    // ⛰️ 4. MT. BATULAO (Batangas)
    if (id.contains('batulao') || name.contains('batulao')) {
      return const [
        LatLng(14.0410, 120.8010),
        LatLng(14.0380, 120.8035),
        LatLng(14.0350, 120.8070),
        LatLng(14.0333, 120.8090),
      ];
    }

    // ☁️ 5. MT. ULAP (Benguet - Ampucao, Gungal)
    if (id.contains('ulap') || id.contains('gungal') || name.contains('ulap')) {
      return const [
        LatLng(16.3210, 120.6380),
        LatLng(16.3260, 120.6420),
        LatLng(16.3300, 120.6470),
        LatLng(16.3333, 120.6510),
      ];
    }

    // ⛰️ 6. MT. MACULOT (Batangas)
    if (id.contains('maculot') || name.contains('maculot')) {
      return const [
        LatLng(13.9210, 121.0500),
        LatLng(13.9240, 121.0470),
        LatLng(13.9265, 121.0445),
        LatLng(13.9280, 121.0420),
      ];
    }

    // 🌲 7. MT. DARAITAN & TINIPAK RIVER (Rizal)
    if (id.contains('daraitan') || id.contains('tinipak') || name.contains('daraitan')) {
      return const [
        LatLng(14.6120, 121.3980),
        LatLng(14.6145, 121.3955),
        LatLng(14.6168, 121.3935),
        LatLng(14.6180, 121.3920),
      ];
    }

    // 🦜 8. MT. PICO DE LORO (Cavite / Batangas)
    if (id.contains('pico') || name.contains('pico')) {
      return const [
        LatLng(14.2120, 120.6410),
        LatLng(14.2148, 120.6442),
        LatLng(14.2165, 120.6468),
        LatLng(14.2180, 120.6480),
      ];
    }

    // 🌋 9. MT. PINATUBO (Capas, Porac, Sapangbato)
    if (id.contains('pinatubo') || name.contains('pinatubo')) {
      return const [
        LatLng(15.1310, 120.3620),
        LatLng(15.1350, 120.3580),
        LatLng(15.1390, 120.3540),
        LatLng(15.1420, 120.3500),
      ];
    }

    // 🌿 10. MT. MAKILING (Laguna)
    if (id.contains('makiling') || name.contains('makiling')) {
      return const [
        LatLng(14.1480, 121.2150),
        LatLng(14.1430, 121.2080),
        LatLng(14.1390, 121.2020),
        LatLng(14.1350, 121.1960),
      ];
    }

    // ⛰️ 11. MT. ARAYAT (Pampanga)
    if (id.contains('arayat') || name.contains('arayat')) {
      return const [
        LatLng(15.2010, 120.7380),
        LatLng(15.2032, 120.7398),
        LatLng(15.2048, 120.7410),
        LatLng(15.2060, 120.7420),
      ];
    }

    // 🏝️ 12. MT. GUITING-GUITING / G2 (Romblon)
    if (id.contains('g2') || id.contains('guiting') || name.contains('guiting')) {
      return const [
        LatLng(12.4120, 122.5600),
        LatLng(12.4145, 122.5630),
        LatLng(12.4168, 122.5658),
        LatLng(12.4180, 122.5680),
      ];
    }

    // 🐮 13. MT. GULUGOD BABOY (Batangas)
    if (id.contains('gulugod') || name.contains('gulugod')) {
      return const [
        LatLng(13.6850, 120.8920),
        LatLng(13.6875, 120.8945),
        LatLng(13.6898, 120.8962),
        LatLng(13.6910, 120.8980),
      ];
    }

    // ✝️ 14. MT. MANABU (Batangas)
    if (id.contains('manabu') || name.contains('manabu')) {
      return const [
        LatLng(13.9820, 121.2100),
        LatLng(13.9848, 121.2132),
        LatLng(13.9870, 121.2158),
        LatLng(13.9890, 121.2180),
      ];
    }

    // 🌊 15. MT. MAYNOBA (Rizal)
    if (id.contains('maynoba') || name.contains('maynoba')) {
      return const [
        LatLng(14.6820, 121.3100),
        LatLng(14.6845, 121.3130),
        LatLng(14.6865, 121.3155),
        LatLng(14.6880, 121.3180),
      ];
    }

    // ⛰️ 16. MT. DAMAS (Tarlac)
    if (id.contains('damas') || name.contains('damas')) {
      return const [
        LatLng(15.5820, 120.3800),
        LatLng(15.5848, 120.3832),
        LatLng(15.5870, 120.3858),
        LatLng(15.5890, 120.3880),
      ];
    }

    // 🌲 17. MT. MARIGLEM (Zambales)
    if (id.contains('mariglem') || name.contains('mariglem')) {
      return const [
        LatLng(14.9820, 120.1800),
        LatLng(14.9845, 120.1830),
        LatLng(14.9868, 120.1858),
        LatLng(14.9880, 120.1880),
      ];
    }

    // ⛰️ 18. MT. CUTUNO & LUBOG
    if (id.contains('cutuno') || name.contains('cutuno')) {
      return const [
        LatLng(14.7820, 121.2200),
        LatLng(14.7848, 121.2232),
        LatLng(14.7870, 121.2258),
        LatLng(14.7890, 121.2280),
      ];
    }

    // 🌲 19. MT. TUGEW
    if (id.contains('tugew') || name.contains('tugew')) {
      return const [
        LatLng(16.7820, 120.5800),
        LatLng(16.7848, 120.5832),
        LatLng(16.7870, 120.5858),
        LatLng(16.7890, 120.5880),
      ];
    }

    // 🏔️ 20. MT. LINGGUHOB
    if (id.contains('lingguhob') || name.contains('lingguhob')) {
      return const [
        LatLng(14.2820, 121.2800),
        LatLng(14.2848, 121.2832),
        LatLng(14.2870, 121.2858),
        LatLng(14.2890, 121.2880),
      ];
    }

    // ⚡ SMART REGION FALLBACK
    double baseLat = 14.5995;
    double baseLng = 120.9842;

    if (location.contains('benguet') || location.contains('baguio')) {
      baseLat = 16.4023; baseLng = 120.5960;
    } else if (location.contains('batangas')) {
      baseLat = 13.9320; baseLng = 121.0500;
    } else if (location.contains('rizal') || location.contains('tanay')) {
      baseLat = 14.6120; baseLng = 121.3980;
    } else if (location.contains('zambales')) {
      baseLat = 15.0820; baseLng = 120.1800;
    } else if (location.contains('tarlac')) {
      baseLat = 15.5820; baseLng = 120.3800;
    } else if (location.contains('pampanga')) {
      baseLat = 15.2010; baseLng = 120.7380;
    } else if (location.contains('davao') || location.contains('cotabato')) {
      baseLat = 7.0050; baseLng = 125.2600;
    } else if (location.contains('laguna')) {
      baseLat = 14.1480; baseLng = 121.2150;
    }

    return [
      LatLng(baseLat, baseLng),
      LatLng(baseLat + 0.003, baseLng + 0.003),
      LatLng(baseLat + 0.006, baseLng + 0.005),
      LatLng(baseLat + 0.009, baseLng + 0.008),
    ];
  }
}