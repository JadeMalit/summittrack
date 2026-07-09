import '../../core/routing/app_routes.dart';
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
      isNavigationEnabled: true,
      validationNote:
          'Pilot navigation uses GraphHopper route data and the public Mt. Apo summit coordinate. Trailhead and checkpoint coordinates should still be validated with local guides before field use.',
    ),
  };

  static HikeNavigationMetadata? forTrailId(String trailId) {
    return _pilotTrails[trailId];
  }
}
