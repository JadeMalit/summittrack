import 'route_coordinate.dart';

class HikingCheckpoint {
  const HikingCheckpoint({
    required this.id,
    required this.name,
    required this.coordinate,
    this.description,
  });

  final String id;
  final String name;
  final RouteCoordinate coordinate;
  final String? description;
}
