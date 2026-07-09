import 'package:geolocator/geolocator.dart';

import 'hike_navigation_metadata.dart';

class HikeNavigationStartRequest {
  const HikeNavigationStartRequest({
    required this.metadata,
    required this.initialPosition,
  });

  final HikeNavigationMetadata metadata;
  final Position initialPosition;
}
