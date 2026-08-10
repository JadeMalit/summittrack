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

  static HikeNavigationMetadata? forTrailId(String trailId) {
    final normalizedTrailId = _normalizeTrailKey(trailId);
    return _pilotTrails[trailId] ?? _pilotTrails[normalizedTrailId];
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
}
