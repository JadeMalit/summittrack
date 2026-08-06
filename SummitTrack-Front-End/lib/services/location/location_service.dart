import 'package:geolocator/geolocator.dart';

import '../../models/route_coordinate.dart';

enum LocationReadinessStatus {
  ready,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  poorAccuracy,
  unavailable,
}

class LocationReadiness {
  const LocationReadiness({
    required this.status,
    required this.message,
    this.position,
  });

  final LocationReadinessStatus status;
  final String message;
  final Position? position;

  bool get isReady => status == LocationReadinessStatus.ready;
}

class LocationService {
  const LocationService();

  static const reliableStartAccuracyMeters = 20.0;
  static const reliableDecisionAccuracyMeters = 30.0;

  Future<LocationReadiness> requestNavigationReadiness() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationReadiness(
          status: LocationReadinessStatus.serviceDisabled,
          message: 'Turn on Location Services before starting navigation.',
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        return const LocationReadiness(
          status: LocationReadinessStatus.permissionDenied,
          message: 'Allow location access to use hiking navigation.',
        );
      }

      if (permission == LocationPermission.deniedForever) {
        return const LocationReadiness(
          status: LocationReadinessStatus.permissionDeniedForever,
          message:
              'Location access is permanently denied. Enable it in device settings.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 15),
      );

      if (!isReliableForStart(position)) {
        return LocationReadiness(
          status: LocationReadinessStatus.poorAccuracy,
          message:
              'Waiting for a stronger GPS fix. Current accuracy is about ${position.accuracy.toStringAsFixed(0)}m.',
          position: position,
        );
      }

      return LocationReadiness(
        status: LocationReadinessStatus.ready,
        message:
            'GPS ready. Accuracy is about ${position.accuracy.toStringAsFixed(0)}m.',
        position: position,
      );
    } catch (_) {
      return const LocationReadiness(
        status: LocationReadinessStatus.unavailable,
        message: 'Unable to read GPS location. Please try again outdoors.',
      );
    }
  }

  Stream<Position> foregroundPositionStream({int distanceFilterMeters = 5}) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: distanceFilterMeters,
      ),
    );
  }

  bool isReliableForStart(Position position) {
    return position.accuracy > 0 &&
        position.accuracy <= reliableStartAccuracyMeters;
  }

  bool isReliableForRouteDecision(Position position) {
    return position.accuracy > 0 &&
        position.accuracy <= reliableDecisionAccuracyMeters;
  }

  RouteCoordinate coordinateFromPosition(Position position) {
    return RouteCoordinate(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  /// Helper method para sa mabilisang Permission Check ng Live Tracking
  Future<bool> requestPermission() async {
    final readiness = await requestNavigationReadiness();
    // Papayagan mag-track basta may permission (kahit poor accuracy muna habang nasa loob ng bahay)
    return readiness.isReady ||
        readiness.status == LocationReadinessStatus.poorAccuracy;
  }
}