import 'package:flutter_test/flutter_test.dart';
import 'package:summittrack/core/routing/app_routes.dart';
import 'package:summittrack/data/navigation/navigation_trails.dart';
import 'package:summittrack/models/hike_navigation_metadata.dart';
import 'package:summittrack/models/route_coordinate.dart';
import 'package:summittrack/services/routing/trailhead_proximity_guard.dart';

void main() {
  group('TrailheadProximityGuard', () {
    test('allows starts near the selected trailhead', () {
      final result = TrailheadProximityGuard.evaluate(
        metadata: _metadata(),
        currentLocation: const RouteCoordinate(
          latitude: 6.9553,
          longitude: 125.3207,
        ),
      );

      expect(result.canStart, isTrue);
      expect(result.distanceMeters, lessThan(20));
    });

    test('blocks starts far from the selected trailhead', () {
      final result = TrailheadProximityGuard.evaluate(
        metadata: _metadata(),
        currentLocation: const RouteCoordinate(
          latitude: 10.4867,
          longitude: 123.4143,
        ),
      );

      expect(result.canStart, isFalse);
      expect(result.message, contains('You must be near the trailhead'));
      expect(result.distanceMeters, greaterThan(400000));
    });

    test(
      'debug simulated trailhead location is unavailable in release mode',
      () {
        final position = DebugTrailheadStartSimulator.simulatedPositionFor(
          metadata: _metadata(),
          debugMode: false,
        );

        expect(position, isNull);
      },
    );

    test(
      'debug simulated trailhead location uses selected trailhead order',
      () {
        final position = DebugTrailheadStartSimulator.simulatedPositionFor(
          metadata: _metadata(),
          debugMode: true,
          timestamp: DateTime(2026, 7, 22, 8),
        );

        expect(position, isNotNull);
        expect(position!.latitude, 6.95525);
        expect(position.longitude, 125.32062);
        expect(position.isMocked, isTrue);
      },
    );

    test('Sta. Cruz/Sibulan metadata points to Davao trailhead and summit', () {
      final metadata = NavigationTrails.forTrailId(AppRoutes.staCruzTrailId);

      expect(metadata, isNotNull);
      expect(metadata!.destination.latitude, closeTo(6.9875, 0.000001));
      expect(metadata.destination.longitude, closeTo(125.271, 0.000001));
      expect(metadata.trailhead?.latitude, closeTo(6.95525, 0.000001));
      expect(metadata.trailhead?.longitude, closeTo(125.32062, 0.000001));
      expect(
        metadata.trailhead!.distanceTo(metadata.destination),
        inInclusiveRange(5000, 7000),
      );
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
