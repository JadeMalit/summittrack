import 'package:flutter/material.dart';

import '../../features/mountains/widgets/elevation_gradient_map_3d.dart';
import 'trail_data.dart';

class TrailWaypointHelper {
  /// Awtomatikong nag-ge-generate o nagre-return ng TOTOONG Waypoints para sa 20+ Bundok
  static List<TrailWaypoint> getWaypointsForTrail(TrailData trail, String photoId) {
    // 🔠 Normalize search string para hindi magkamali sa matching
    final String searchKey = '${photoId}_${trail.name}_${trail.location}'.toLowerCase();

    // 🌋 1. MT. PULAG (Benguet) - ~2,928m ASL
    if (searchKey.contains('pulag') || searchKey.contains('ambangeg') || searchKey.contains('akiki')) {
      final bool isAkiki = searchKey.contains('akiki');
      if (isAkiki) {
        return const [
          TrailWaypoint(name: 'Eddet River Jump-off', elevation: 1250, distance: 0.0, slope: 8, color: Color(0xFF4CAF50)),
          TrailWaypoint(name: 'Marlboro Campsite', elevation: 2100, distance: 5.5, slope: 22, color: Color(0xFFFFB300)),
          TrailWaypoint(name: 'Saddle Campsite', elevation: 2680, distance: 8.8, slope: 35, color: Color(0xFFFF7043)),
          TrailWaypoint(name: 'Mt. Pulag Summit', elevation: 2928, distance: 10.5, slope: 28, color: Color(0xFFE53935)),
        ];
      }
      return const [
        TrailWaypoint(name: 'Babadak Ranger Station', elevation: 2400, distance: 0.0, slope: 6, color: Color(0xFF4CAF50)),
        TrailWaypoint(name: 'Camp 1', elevation: 2580, distance: 3.2, slope: 12, color: Color(0xFFFFB300)),
        TrailWaypoint(name: 'Camp 2 (Grassland)', elevation: 2720, distance: 6.8, slope: 18, color: Color(0xFFFF7043)),
        TrailWaypoint(name: 'Mt. Pulag Summit', elevation: 2928, distance: 8.5, slope: 25, color: Color(0xFFE53935)),
      ];
    }

    // 🌋 2. MT. APO (Davao / Cotabato) - ~2,954m ASL
    if (searchKey.contains('apo') || searchKey.contains('sta_cruz') || searchKey.contains('sibulan') || searchKey.contains('kidapawan')) {
      return const [
        TrailWaypoint(name: 'Sibulan Jump-off', elevation: 840, distance: 0.0, slope: 8, color: Color(0xFF4CAF50)),
        TrailWaypoint(name: 'Forest Trail / Camp', elevation: 1650, distance: 5.2, slope: 18, color: Color(0xFFFFB300)),
        TrailWaypoint(name: 'Boulder Face', elevation: 2400, distance: 10.8, slope: 38, color: Color(0xFFFF7043)),
        TrailWaypoint(name: 'Mt. Apo Summit', elevation: 2954, distance: 14.5, slope: 42, color: Color(0xFFE53935)),
      ];
    }

    // ⛰️ 3. MT. ULAP (Benguet) - ~1,846m ASL
    if (searchKey.contains('ulap') || searchKey.contains('itogon')) {
      return const [
        TrailWaypoint(name: 'Ampucao Jump-off', elevation: 1300, distance: 0.0, slope: 10, color: Color(0xFF4CAF50)),
        TrailWaypoint(name: 'Ambabanay Ridge', elevation: 1550, distance: 3.2, slope: 16, color: Color(0xFFFFB300)),
        TrailWaypoint(name: 'Gungal Rock', elevation: 1810, distance: 6.0, slope: 22, color: Color(0xFFFF7043)),
        TrailWaypoint(name: 'Mt. Ulap Summit', elevation: 1846, distance: 9.2, slope: 20, color: Color(0xFFE53935)),
      ];
    }

    // 👑 4. MT. GUITING-GUITING / G2 (Romblon) - ~2,058m ASL
    if (searchKey.contains('guiting') || searchKey.contains('g2') || searchKey.contains('romblon')) {
      return const [
        TrailWaypoint(name: 'Magdiwang Jump-off', elevation: 50, distance: 0.0, slope: 12, color: Color(0xFF4CAF50)),
        TrailWaypoint(name: 'Mayo\'s Peak', elevation: 1540, distance: 4.8, slope: 30, color: Color(0xFFFFB300)),
        TrailWaypoint(name: 'Knife Edge Ridge', elevation: 1850, distance: 6.5, slope: 45, color: Color(0xFFFF7043)),
        TrailWaypoint(name: 'G2 Summit', elevation: 2058, distance: 8.5, slope: 50, color: Color(0xFFE53935)),
      ];
    }

    // 🌋 5. MT. MAYON (Albay) - ~2,463m ASL
    if (searchKey.contains('mayon') || searchKey.contains('albay')) {
      return const [
        TrailWaypoint(name: 'Buyohan Jump-off', elevation: 320, distance: 0.0, slope: 12, color: Color(0xFF4CAF50)),
        TrailWaypoint(name: 'Camp 1', elevation: 850, distance: 3.0, slope: 24, color: Color(0xFFFFB300)),
        TrailWaypoint(name: 'Camp 2 (Scree Area)', elevation: 1400, distance: 5.2, slope: 36, color: Color(0xFFFF7043)),
        TrailWaypoint(name: 'Summit Ridge', elevation: 2463, distance: 6.5, slope: 48, color: Color(0xFFE53935)),
      ];
    }

    // 🪨 6. MT. BATULAO (Batangas) - ~811m ASL
    if (searchKey.contains('batulao') || searchKey.contains('nasugbu')) {
      return const [
        TrailWaypoint(name: 'Evercrest Jump-off', elevation: 210, distance: 0.0, slope: 6, color: Color(0xFF4CAF50)),
        TrailWaypoint(name: 'Camp 1 / Split', elevation: 450, distance: 2.8, slope: 14, color: Color(0xFFFFB300)),
        TrailWaypoint(name: 'New / Old Trail Peak', elevation: 720, distance: 4.5, slope: 28, color: Color(0xFFFF7043)),
        TrailWaypoint(name: 'Batulao Summit', elevation: 811, distance: 5.5, slope: 32, color: Color(0xFFE53935)),
      ];
    }

    // ⛰️ 7. MT. MACULOT (Batangas) - ~930m ASL
    if (searchKey.contains('maculot') || searchKey.contains('cuenca')) {
      return const [
        TrailWaypoint(name: 'Cuenca Jump-off', elevation: 120, distance: 0.0, slope: 15, color: Color(0xFF4CAF50)),
        TrailWaypoint(name: 'Store Checkpoint', elevation: 520, distance: 2.2, slope: 25, color: Color(0xFFFFB300)),
        TrailWaypoint(name: 'Rockies Viewpoint', elevation: 700, distance: 3.8, slope: 35, color: Color(0xFFFF7043)),
        TrailWaypoint(name: 'Maculot Summit', elevation: 930, distance: 5.2, slope: 30, color: Color(0xFFE53935)),
      ];
    }

    // 🌊 8. MT. DARAITAN (Rizal) - ~739m ASL
    if (searchKey.contains('daraitan') || searchKey.contains('tanay')) {
      return const [
        TrailWaypoint(name: 'Barangay Hall Jump-off', elevation: 100, distance: 0.0, slope: 14, color: Color(0xFF4CAF50)),
        TrailWaypoint(name: 'Station 2 / Caves', elevation: 380, distance: 2.0, slope: 28, color: Color(0xFFFFB300)),
        TrailWaypoint(name: 'Summit Viewdeck', elevation: 739, distance: 4.5, slope: 38, color: Color(0xFFE53935)),
      ];
    }

    // 🏕️ 9. MT. TAPULAO (Zambales) - ~2,037m ASL
    if (searchKey.contains('tapulao') || searchKey.contains('palauig')) {
      return const [
        TrailWaypoint(name: 'Palauig Jump-off', elevation: 150, distance: 0.0, slope: 8, color: Color(0xFF4CAF50)),
        TrailWaypoint(name: 'Km 10 Water Source', elevation: 1100, distance: 10.0, slope: 18, color: Color(0xFFFFB300)),
        TrailWaypoint(name: 'Bunker Campsite', elevation: 1850, distance: 16.0, slope: 24, color: Color(0xFFFF7043)),
        TrailWaypoint(name: 'Mt. Tapulao Peak', elevation: 2037, distance: 18.0, slope: 22, color: Color(0xFFE53935)),
      ];
    }

    // 🌲 10. MT. AMUYAO (Mountain Province) - ~2,702m ASL
    if (searchKey.contains('amuyao') || searchKey.contains('barlig')) {
      return const [
        TrailWaypoint(name: 'Barlig Jump-off', elevation: 1550, distance: 0.0, slope: 12, color: Color(0xFF4CAF50)),
        TrailWaypoint(name: 'Wait Station', elevation: 2100, distance: 6.0, slope: 26, color: Color(0xFFFFB300)),
        TrailWaypoint(name: 'Mt. Amuyao Peak', elevation: 2702, distance: 12.5, slope: 34, color: Color(0xFFE53935)),
      ];
    }

    // 🌋 11. MT. KANLAON (Negros) - ~2,465m ASL
    if (searchKey.contains('kanlaon') || searchKey.contains('canlaon')) {
      return const [
        TrailWaypoint(name: 'Wasay Jump-off', elevation: 800, distance: 0.0, slope: 10, color: Color(0xFF4CAF50)),
        TrailWaypoint(name: 'Hardin sang Balo', elevation: 1750, distance: 6.5, slope: 22, color: Color(0xFFFFB300)),
        TrailWaypoint(name: 'Pagatpat Campsite', elevation: 2100, distance: 9.5, slope: 32, color: Color(0xFFFF7043)),
        TrailWaypoint(name: 'Kanlaon Crater Summit', elevation: 2465, distance: 11.5, slope: 40, color: Color(0xFFE53935)),
      ];
    }

    // 🌊 12. MT. TARAK RIDGE / MARIVELES (Bataan) - ~1,005m ASL
    if (searchKey.contains('tarak') || searchKey.contains('mariveles') || searchKey.contains('bataan')) {
      return const [
        TrailWaypoint(name: 'Alas-asin Jump-off', elevation: 60, distance: 0.0, slope: 8, color: Color(0xFF4CAF50)),
        TrailWaypoint(name: 'Papaya River', elevation: 320, distance: 4.5, slope: 15, color: Color(0xFFFFB300)),
        TrailWaypoint(name: 'Tarak Ridge', elevation: 1005, distance: 7.5, slope: 38, color: Color(0xFFFF7043)),
        TrailWaypoint(name: 'El Saco Peak', elevation: 1130, distance: 8.8, slope: 35, color: Color(0xFFE53935)),
      ];
    }

    // 🥾 13. MT. DAMAS (Tarlac) - ~685m ASL
    if (searchKey.contains('damas') || searchKey.contains('tarlac')) {
      return const [
        TrailWaypoint(name: 'Papaac Jump-off', elevation: 70, distance: 0.0, slope: 10, color: Color(0xFF4CAF50)),
        TrailWaypoint(name: 'River Crossing', elevation: 220, distance: 3.5, slope: 20, color: Color(0xFFFFB300)),
        TrailWaypoint(name: 'Cardiac Assault', elevation: 510, distance: 6.2, slope: 38, color: Color(0xFFFF7043)),
        TrailWaypoint(name: 'Mt. Damas Summit', elevation: 685, distance: 8.0, slope: 35, color: Color(0xFFE53935)),
      ];
    }

    // 🌲 14. MT. MAKILING (Laguna) - ~1,090m ASL
    if (searchKey.contains('makiling') || searchKey.contains('los_banos')) {
      return const [
        TrailWaypoint(name: 'UPLB Forestry Jump-off', elevation: 100, distance: 0.0, slope: 8, color: Color(0xFF4CAF50)),
        TrailWaypoint(name: 'Agila Base', elevation: 550, distance: 4.2, slope: 14, color: Color(0xFFFFB300)),
        TrailWaypoint(name: 'Wildness Trail', elevation: 880, distance: 6.5, slope: 28, color: Color(0xFFFF7043)),
        TrailWaypoint(name: 'Peak 2 (Summit)', elevation: 1090, distance: 7.8, slope: 32, color: Color(0xFFE53935)),
      ];
    }

    // 🦜 15. MT. PICO DE LORO (Cavite) - ~664m ASL
    if (searchKey.contains('pico') || searchKey.contains('palay') || searchKey.contains('denr')) {
      return const [
        TrailWaypoint(name: 'DENR Jump-off', elevation: 120, distance: 0.0, slope: 10, color: Color(0xFF4CAF50)),
        TrailWaypoint(name: 'Basecamp 1', elevation: 340, distance: 2.5, slope: 18, color: Color(0xFFFFB300)),
        TrailWaypoint(name: 'Pico de Loro Summit', elevation: 664, distance: 5.0, slope: 30, color: Color(0xFFE53935)),
      ];
    }

    // ⛰️ 16. MT. DULANG-DULANG / D2 (Bukidnon) - ~2,938m ASL
    if (searchKey.contains('dulang') || searchKey.contains('d2')) {
      return const [
        TrailWaypoint(name: 'Lantapan Jump-off', elevation: 1300, distance: 0.0, slope: 10, color: Color(0xFF4CAF50)),
        TrailWaypoint(name: 'Manny\'s Garden', elevation: 2250, distance: 7.5, slope: 28, color: Color(0xFFFFB300)),
        TrailWaypoint(name: 'Sacred Mossy Forest', elevation: 2700, distance: 12.0, slope: 36, color: Color(0xFFFF7043)),
        TrailWaypoint(name: 'D2 Summit', elevation: 2938, distance: 15.0, slope: 32, color: Color(0xFFE53935)),
      ];
    }

    // ⛰️ 17. MT. KITANGLAD (Bukidnon) - ~2,899m ASL
    if (searchKey.contains('kitanglad')) {
      return const [
        TrailWaypoint(name: 'Intavas Jump-off', elevation: 1200, distance: 0.0, slope: 12, color: Color(0xFF4CAF50)),
        TrailWaypoint(name: 'Pine Tree Line', elevation: 1950, distance: 6.0, slope: 22, color: Color(0xFFFFB300)),
        TrailWaypoint(name: 'Summit Towers', elevation: 2899, distance: 13.0, slope: 38, color: Color(0xFFE53935)),
      ];
    }

    // 🌋 18. MT. KALATUNGAN (Bukidnon) - ~2,880m ASL
    if (searchKey.contains('kalatungan')) {
      return const [
        TrailWaypoint(name: 'Pangantucan Jump-off', elevation: 1100, distance: 0.0, slope: 12, color: Color(0xFF4CAF50)),
        TrailWaypoint(name: 'Sasa View Deck', elevation: 2100, distance: 7.0, slope: 28, color: Color(0xFFFFB300)),
        TrailWaypoint(name: 'Mt. Kalatungan Peak', elevation: 2880, distance: 14.0, slope: 38, color: Color(0xFFE53935)),
      ];
    }

    // ☁️ 19. MT. UGO (Benguet / Nueva Vizcaya) - ~2,150m ASL
    if (searchKey.contains('ugo') || searchKey.contains('kayapa')) {
      return const [
        TrailWaypoint(name: 'Kayapa Jump-off', elevation: 850, distance: 0.0, slope: 10, color: Color(0xFF4CAF50)),
        TrailWaypoint(name: 'Indupit Village', elevation: 1400, distance: 8.5, slope: 16, color: Color(0xFFFFB300)),
        TrailWaypoint(name: 'Last Water Source', elevation: 1850, distance: 18.0, slope: 22, color: Color(0xFFFF7043)),
        TrailWaypoint(name: 'Mt. Ugo Summit', elevation: 2150, distance: 24.0, slope: 25, color: Color(0xFFE53935)),
      ];
    }

    // 🌋 20. MT. PINATUBO (Zambales / Tarlac) - ~960m ASL
    if (searchKey.contains('pinatubo')) {
      return const [
        TrailWaypoint(name: 'Capas 4x4 Station', elevation: 150, distance: 0.0, slope: 4, color: Color(0xFF4CAF50)),
        TrailWaypoint(name: 'Trek Jump-off', elevation: 600, distance: 5.0, slope: 12, color: Color(0xFFFFB300)),
        TrailWaypoint(name: 'Crater Lake Rim', elevation: 960, distance: 7.0, slope: 24, color: Color(0xFFE53935)),
      ];
    }

    // ⚡ 21. SMART DYNAMIC AUTO-GENERATION PARA SA custom/unknown trails
    final bool isMajor = trail.slopeDifficulty.toLowerCase().contains('major') ||
        trail.slopeDifficulty.toLowerCase().contains('hard') ||
        trail.slopeDifficulty.contains('7/') ||
        trail.slopeDifficulty.contains('8/') ||
        trail.slopeDifficulty.contains('9/');

    final double baseElev = isMajor ? 600 : 200;
    final double midElev = isMajor ? 1400 : 500;
    final double steepElev = isMajor ? 2100 : 850;
    final double peakElev = isMajor ? 2600 : 1100;
    final double maxDist = isMajor ? 12.0 : 5.5;

    final String cleanName = trail.name.replaceAll('Trail', '').trim();

    return [
      TrailWaypoint(
        name: 'Jump-off Point',
        elevation: baseElev,
        distance: 0.0,
        slope: 7.0,
        color: const Color(0xFF4CAF50),
      ),
      TrailWaypoint(
        name: 'Mid Trail Checkpoint',
        elevation: midElev,
        distance: double.parse((maxDist * 0.4).toStringAsFixed(1)),
        slope: isMajor ? 18.0 : 12.0,
        color: const Color(0xFFFFB300),
      ),
      TrailWaypoint(
        name: 'Steep Assault',
        elevation: steepElev,
        distance: double.parse((maxDist * 0.75).toStringAsFixed(1)),
        slope: isMajor ? 32.0 : 22.0,
        color: const Color(0xFFFF7043),
      ),
      TrailWaypoint(
        name: '$cleanName Summit',
        elevation: peakElev,
        distance: maxDist,
        slope: isMajor ? 40.0 : 28.0,
        color: const Color(0xFFE53935),
      ),
    ];
  }
}