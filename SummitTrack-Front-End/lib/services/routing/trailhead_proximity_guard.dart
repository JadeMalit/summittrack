import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/hike_navigation_metadata.dart';
import '../../models/route_coordinate.dart';

class TrailheadProximityResult {
  const TrailheadProximityResult({
    required this.canStart,
    required this.message,
    this.distanceMeters,
    this.allowedRadiusMeters,
  });

  final bool canStart;
  final String message;
  final double? distanceMeters;
  final double? allowedRadiusMeters;
}

class TrailheadProximityGuard {
  const TrailheadProximityGuard._();

  static const blockedMessage =
      'You must be near the trailhead to start navigation.';

  static TrailheadProximityResult evaluate({
    required HikeNavigationMetadata metadata,
    required RouteCoordinate currentLocation,
  }) {
    final trailhead = metadata.trailhead;
    if (trailhead == null) {
      return const TrailheadProximityResult(
        canStart: true,
        message: 'Trailhead proximity check unavailable for this route.',
      );
    }

    final radius = metadata.trailheadProximityRadiusMeters;
    final distance = currentLocation.distanceTo(trailhead);
    if (distance <= radius) {
      return TrailheadProximityResult(
        canStart: true,
        distanceMeters: distance,
        allowedRadiusMeters: radius,
        message:
            'Near ${metadata.trailheadName ?? 'the selected trailhead'} '
            '(${formatDistance(distance)} away).',
      );
    }

    return TrailheadProximityResult(
      canStart: false,
      distanceMeters: distance,
      allowedRadiusMeters: radius,
      message:
          '$blockedMessage You are ${formatDistance(distance)} from '
          '${metadata.trailheadName ?? 'the selected trailhead'}.',
    );
  }

  static String formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }

    return '${meters.toStringAsFixed(0)} m';
  }
}

class DebugTrailheadStartSimulator {
  const DebugTrailheadStartSimulator._();

  static bool isAvailable({bool debugMode = kDebugMode}) {
    return debugMode;
  }

  static Position? simulatedPositionFor({
    required HikeNavigationMetadata metadata,
    DateTime? timestamp,
    bool debugMode = kDebugMode,
  }) {
    if (!isAvailable(debugMode: debugMode)) {
      return null;
    }

    final trailhead = metadata.trailhead;
    if (trailhead == null) {
      return null;
    }

    return Position(
      latitude: trailhead.latitude,
      longitude: trailhead.longitude,
      timestamp: timestamp ?? DateTime.now(),
      accuracy: 5,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
      isMocked: true,
    );
  }
}
