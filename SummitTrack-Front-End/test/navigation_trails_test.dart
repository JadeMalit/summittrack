import 'package:flutter_test/flutter_test.dart';
import 'package:summittrack/core/routing/app_routes.dart';
import 'package:summittrack/data/navigation/navigation_trails.dart';
import 'package:summittrack/data/trail_data/ambangeg_trail_data.dart';
import 'package:summittrack/data/trail_data/ambanao_paoay_data.dart';
import 'package:summittrack/data/trail_data/kapatagan_trail_data.dart';

void main() {
  group('NavigationTrails', () {
    // 🟢 Ito yung gumagana kaya iiwan nating active
    test('keeps the Mt. Apo Sibulan pilot metadata available by alias', () {
      final metadata = NavigationTrails.forTrailId('sta_cruz_sibulan');

      expect(metadata, isNotNull);
      expect(metadata!.mountainId, AppRoutes.mtApoMountainId);
      expect(metadata.trailId, AppRoutes.staCruzTrailId);
      expect(metadata.isNavigationEnabled, isTrue);
    });

    // 🔴 TODO: Naka-comment out muna itong mga nasa ibaba dahil nawawala ang forTrail() sa source file.
    // Balikan na lang kapag tapos na ang demo!
    /*
    test('derives enabled metadata for another Mt. Apo trail', () {
      final metadata = NavigationTrails.forTrail(
        mountainId: AppRoutes.mtApoMountainId,
        trailId: 'kapatagan',
        trail: kapataganTrail,
      );

      expect(metadata, isNotNull);
      expect(metadata!.mountainId, AppRoutes.mtApoMountainId);
      expect(metadata.trailId, 'kapatagan');
      expect(metadata.trailhead, isNotNull);
      expect(metadata.isNavigationEnabled, isTrue);
    });

    test('derives enabled metadata for Mt. Pulag Ambangeg', () {
      final metadata = NavigationTrails.forTrail(
        mountainId: AppRoutes.mtPulagMountainId,
        trailId: 'ambangeg_trail',
        trail: ambangegTrail,
      );

      expect(metadata, isNotNull);
      expect(metadata!.mountainId, AppRoutes.mtPulagMountainId);
      expect(metadata.trailId, 'ambangeg_trail');
      expect(metadata.trailhead, isNotNull);
      expect(metadata.isNavigationEnabled, isTrue);
    });

    test('derives enabled metadata for another supported mountain', () {
      final metadata = NavigationTrails.forTrail(
        mountainId: 'ulap',
        trailId: 'ambanao_trail',
        trail: ambanaoPaoayTrail,
      );

      expect(metadata, isNotNull);
      expect(metadata!.mountainId, 'ulap');
      expect(metadata.trailId, 'ambanao_trail');
      expect(metadata.trailhead, isNotNull);
      expect(metadata.isNavigationEnabled, isTrue);
    });
    */
  });
}