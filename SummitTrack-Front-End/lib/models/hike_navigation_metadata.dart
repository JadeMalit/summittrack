import 'hiking_checkpoint.dart';
import 'route_coordinate.dart';

class HikeNavigationMetadata {
  const HikeNavigationMetadata({
    required this.mountainId,
    required this.trailId,
    required this.trailName,
    required this.destinationName,
    required this.destination,
    required this.isNavigationEnabled,
    this.trailhead,
    this.trailheadName,
    this.trailheadProximityRadiusMeters = 1500,
    this.checkpoints = const [],
    this.validationNote,
  });

  final String mountainId;
  final String trailId;
  final String trailName;
  final String destinationName;
  final RouteCoordinate destination;
  final bool isNavigationEnabled;
  final RouteCoordinate? trailhead;
  final String? trailheadName;
  final double trailheadProximityRadiusMeters;
  final List<HikingCheckpoint> checkpoints;
  final String? validationNote;
}
