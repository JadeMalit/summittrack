// Regression tests for the Debug Start availability mismatch fix.
//
// Root cause fixed: _debugTrailheadStartAvailable in
// HikeNavigationConfirmationDialog previously hardcoded `return true`,
// disconnecting the UI eligibility check from
// DebugTrailheadStartSimulator.isAvailable(). This let the Start button
// appear enabled via the debug path even in release builds where
// simulatedPositionFor() returns null, causing a silent abort in
// _startNavigation().
//
// These tests cover the DebugTrailheadStartSimulator contract that now
// serves as the single source of truth for both UI eligibility and execution.
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:summittrack/models/hike_navigation_metadata.dart';
import 'package:summittrack/models/route_coordinate.dart';
import 'package:summittrack/services/location/location_service.dart';
import 'package:summittrack/services/routing/trailhead_proximity_guard.dart';

void main() {
  group('DebugTrailheadStartSimulator — availability contract', () {
    // -----------------------------------------------------------------------
    // Test 1: Simulator unavailable in release mode.
    //
    // Before the fix: _debugTrailheadStartAvailable returned true regardless,
    // so canUseDebugStart could be true even when simulatedPositionFor()
    // returned null — producing a silent no-op on Start tap.
    //
    // After the fix: _debugTrailheadStartAvailable delegates to
    // DebugTrailheadStartSimulator.isAvailable(), which returns false when
    // debugMode is false. The Switch is therefore hidden and the debug path
    // never contributes to canStart in release builds.
    // -----------------------------------------------------------------------
    test(
      'isAvailable returns false when debugMode is false (release build)',
      () {
        expect(
          DebugTrailheadStartSimulator.isAvailable(debugMode: false),
          isFalse,
        );
      },
    );

    test('simulatedPositionFor returns null when debugMode is false '
        '(release build) — was the cause of the silent abort', () {
      final position = DebugTrailheadStartSimulator.simulatedPositionFor(
        metadata: _metadata(),
        debugMode: false,
      );

      // In a release build the simulator must produce null so that the
      // debug eligibility path cannot inadvertently enable Start.
      expect(position, isNull);
    });

    // -----------------------------------------------------------------------
    // Test 2: Simulator available in debug mode.
    //
    // When running under `flutter run` / dart test (kDebugMode == true),
    // the debug Start path must still function correctly: isAvailable()
    // returns true and simulatedPositionFor() returns a non-null Position
    // at the trailhead coordinate.
    // -----------------------------------------------------------------------
    test('isAvailable returns true when debugMode is true (debug build)', () {
      expect(DebugTrailheadStartSimulator.isAvailable(debugMode: true), isTrue);
    });

    test('simulatedPositionFor returns a valid mocked position at trailhead '
        'when debugMode is true', () {
      final position = DebugTrailheadStartSimulator.simulatedPositionFor(
        metadata: _metadata(),
        debugMode: true,
        timestamp: DateTime(2026, 8, 21, 12),
      );

      expect(position, isNotNull);
      // Simulated position must be at the trailhead coordinate so subsequent
      // TrailheadProximityGuard evaluation in HikeTrackingService.start()
      // will pass.
      expect(position!.latitude, closeTo(6.95525, 0.000001));
      expect(position.longitude, closeTo(125.32062, 0.000001));
      expect(position.accuracy, 5.0);
      expect(position.isMocked, isTrue);
    });

    test('simulatedPositionFor returns null when metadata has no trailhead '
        '(regardless of debugMode)', () {
      const metadataWithoutTrailhead = HikeNavigationMetadata(
        mountainId: 'test-mountain',
        trailId: 'test-trail',
        trailName: 'Test Trail',
        destinationName: 'Test Summit',
        destination: RouteCoordinate(latitude: 14.0, longitude: 121.0),
        isNavigationEnabled: true,
        // trailhead intentionally omitted — simulated position cannot exist
      );

      final position = DebugTrailheadStartSimulator.simulatedPositionFor(
        metadata: metadataWithoutTrailhead,
        debugMode: true,
      );

      // Without a trailhead coordinate the simulator cannot produce a
      // meaningful start position; the caller must treat this as unavailable.
      expect(position, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // Test 3: canUseDebugStart eligibility formula mirrors the fix.
  //
  // The fix ensures the UI formula uses the same availability gate as the
  // executor. We verify the raw boolean logic the dialog computes, using the
  // debugMode flag to simulate release vs. debug builds.
  // -------------------------------------------------------------------------
  group('canUseDebugStart eligibility — single source of truth', () {
    bool canUseDebugStart({
      required bool debugMode,
      required bool useDebugTrailheadStart,
    }) {
      final available = DebugTrailheadStartSimulator.isAvailable(
        debugMode: debugMode,
      );
      return available && useDebugTrailheadStart;
    }

    test('canUseDebugStart is false in release build even when toggle is ON '
        '(would have caused the silent abort before fix)', () {
      // Before fix: _debugTrailheadStartAvailable was hardcoded true,
      // so this returned true — incorrectly enabling Start in release builds.
      expect(
        canUseDebugStart(debugMode: false, useDebugTrailheadStart: true),
        isFalse,
      );
    });

    test('canUseDebugStart is true in debug build when toggle is ON', () {
      expect(
        canUseDebugStart(debugMode: true, useDebugTrailheadStart: true),
        isTrue,
      );
    });

    test('canUseDebugStart is false in debug build when toggle is OFF', () {
      expect(
        canUseDebugStart(debugMode: true, useDebugTrailheadStart: false),
        isFalse,
      );
    });
  });

  // -------------------------------------------------------------------------
  // Test 4: Normal GPS Start eligibility (LocationReadiness) is unaffected.
  //
  // The patch must not change the GPS start path. Verify LocationReadiness
  // semantics and the 20m accuracy threshold are preserved exactly.
  // -------------------------------------------------------------------------
  group('GPS Start eligibility — preserved, unaffected by fix', () {
    test('LocationReadiness.isReady is true only for ready status', () {
      const ready = LocationReadiness(
        status: LocationReadinessStatus.ready,
        message: 'GPS ready. Accuracy is about 6m.',
      );
      expect(ready.isReady, isTrue);
    });

    test('LocationReadiness.isReady is false for poorAccuracy — '
        'GPS Start is correctly blocked when accuracy exceeds threshold', () {
      const poor = LocationReadiness(
        status: LocationReadinessStatus.poorAccuracy,
        message: 'Accuracy is about 45m.',
      );
      expect(poor.isReady, isFalse);
    });

    test('LocationReadiness.isReady is false for permissionDenied', () {
      const denied = LocationReadiness(
        status: LocationReadinessStatus.permissionDenied,
        message: 'Allow location access.',
      );
      expect(denied.isReady, isFalse);
    });

    test('isReliableForStart passes for 6m accuracy — '
        'the exact case reported in the iOS reproduction', () {
      const service = LocationService();
      expect(service.isReliableForStart(_mockPosition(accuracy: 6.0)), isTrue);
    });

    test('isReliableForStart passes at exact 20m boundary', () {
      const service = LocationService();
      expect(service.isReliableForStart(_mockPosition(accuracy: 20.0)), isTrue);
    });

    test('isReliableForStart fails above 20m boundary', () {
      const service = LocationService();
      expect(
        service.isReliableForStart(_mockPosition(accuracy: 20.1)),
        isFalse,
      );
    });
  });
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

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

Position _mockPosition({required double accuracy}) {
  return Position(
    latitude: 16.5786,
    longitude: 120.9038,
    timestamp: DateTime(2026, 8, 21, 12),
    accuracy: accuracy,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );
}
