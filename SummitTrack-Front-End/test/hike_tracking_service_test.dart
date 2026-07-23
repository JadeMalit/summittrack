import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:summittrack/models/hike_navigation_metadata.dart';
import 'package:summittrack/models/hiking_route.dart';
import 'package:summittrack/models/route_coordinate.dart';
import 'package:summittrack/services/location/location_service.dart';
import 'package:summittrack/services/routing/graphhopper_service.dart';
import 'package:summittrack/services/tracking/hike_tracking_service.dart';

void main() {
  group('HikeTrackingService trailhead proximity', () {
    test(
      'starts navigation when the current GPS is near the trailhead',
      () async {
        final graphHopperService = _FakeGraphHopperService();
        final service = HikeTrackingService(
          locationService: const _FakeLocationService(),
          graphHopperService: graphHopperService,
        );

        final result = await service.start(
          metadata: _metadata(),
          initialPosition: _position(latitude: 6.9553, longitude: 125.3207),
        );

        expect(result.started, isTrue);
        expect(graphHopperService.fetchCount, 1);
        expect(
          graphHopperService.lastOrigin?.latitude,
          closeTo(6.9553, 0.0001),
        );
        expect(
          graphHopperService.lastOrigin?.longitude,
          closeTo(125.3207, 0.0001),
        );
        expect(service.status, HikeTrackingStatus.active);

        await service.stop();
      },
    );

    test('blocks far-from-trailhead navigation before GraphHopper', () async {
      final graphHopperService = _FakeGraphHopperService();
      final service = HikeTrackingService(
        locationService: const _FakeLocationService(),
        graphHopperService: graphHopperService,
      );

      final result = await service.start(
        metadata: _metadata(),
        initialPosition: _position(latitude: 10.4867, longitude: 123.4143),
      );

      expect(result.started, isFalse);
      expect(result.message, contains('You must be near the trailhead'));
      expect(graphHopperService.fetchCount, 0);
      expect(service.status, HikeTrackingStatus.routeUnavailable);
      expect(service.statusMessage, contains('You must be near the trailhead'));
      expect(service.hasActiveSession, isFalse);
    });
  });
}

HikeNavigationMetadata _metadata() {
  return const HikeNavigationMetadata(
    mountainId: 'mt-apo',
    trailId: 'sta-cruz-sibulan',
    trailName: 'Sta. Cruz / Sibulan Trail',
    destinationName: 'Mt. Apo Summit',
    destination: RouteCoordinate(latitude: 6.9875, longitude: 125.271),
    trailheadName: 'Baruring / Sibulan Trailhead',
    trailhead: RouteCoordinate(latitude: 6.95525, longitude: 125.32062),
    trailheadProximityRadiusMeters: 1500,
    isNavigationEnabled: true,
  );
}

Position _position({required double latitude, required double longitude}) {
  return Position(
    latitude: latitude,
    longitude: longitude,
    timestamp: DateTime(2026, 7, 22, 8),
    accuracy: 5,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );
}

class _FakeLocationService extends LocationService {
  const _FakeLocationService();

  @override
  Stream<Position> foregroundPositionStream({int distanceFilterMeters = 5}) {
    return const Stream<Position>.empty();
  }
}

class _FakeGraphHopperService extends GraphHopperService {
  int fetchCount = 0;
  RouteCoordinate? lastOrigin;

  @override
  Future<HikingRoute> fetchRoute({
    required RouteCoordinate origin,
    required RouteCoordinate destination,
  }) async {
    fetchCount += 1;
    lastOrigin = origin;
    return HikingRoute(
      coordinates: [origin, destination],
      distanceMeters: origin.distanceTo(destination),
      durationSeconds: 1,
    );
  }
}
