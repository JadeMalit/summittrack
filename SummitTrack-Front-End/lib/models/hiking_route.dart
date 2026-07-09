import 'route_coordinate.dart';

class HikingRoute {
  const HikingRoute({
    required this.coordinates,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  final List<RouteCoordinate> coordinates;
  final double distanceMeters;
  final int durationSeconds;

  bool get isUsable => coordinates.length >= 2 && distanceMeters > 0;
}
