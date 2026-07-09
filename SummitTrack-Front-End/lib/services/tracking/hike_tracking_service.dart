import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/hike_navigation_metadata.dart';
import '../../models/hiking_route.dart';
import '../../models/route_coordinate.dart';
import '../location/location_service.dart';
import '../routing/graphhopper_service.dart';

enum HikeTrackingStatus {
  idle,
  loadingRoute,
  active,
  monitoringOffRoute,
  offRoute,
  rerouting,
  routeUnavailable,
  completed,
  error,
}

enum RouteDeviationLevel { unknown, onRoute, monitoring, candidate, confirmed }

class HikeTrackingStartResult {
  const HikeTrackingStartResult({required this.started, this.message});

  final bool started;
  final String? message;
}

class HikeTrackingService extends ChangeNotifier {
  HikeTrackingService({
    LocationService locationService = const LocationService(),
    GraphHopperService graphHopperService = const GraphHopperService(),
  }) : _locationService = locationService,
       _graphHopperService = graphHopperService;

  static final HikeTrackingService instance = HikeTrackingService();

  static const onRouteThresholdMeters = 30.0;
  static const candidateThresholdMeters = 50.0;
  static const destinationRadiusMeters = 25.0;
  static const requiredPersistentSamples = 3;
  static const warningCooldown = Duration(seconds: 90);

  final LocationService _locationService;
  final GraphHopperService _graphHopperService;

  StreamSubscription<Position>? _positionSubscription;
  HikeNavigationMetadata? _metadata;
  HikingRoute? _route;
  Position? _currentPosition;
  RouteCoordinate? _displayCoordinate;
  HikeTrackingStatus _status = HikeTrackingStatus.idle;
  RouteDeviationLevel _deviationLevel = RouteDeviationLevel.unknown;
  String? _statusMessage;
  double? _distanceFromRouteMeters;
  bool _completionCandidate = false;
  int _offRouteSampleCount = 0;
  int _destinationSampleCount = 0;
  int _offRouteWarningVersion = 0;
  int _completionPromptVersion = 0;
  bool _completionPromptIssued = false;
  bool _rerouteInProgress = false;
  DateTime? _lastWarningAt;

  HikeNavigationMetadata? get metadata => _metadata;

  HikingRoute? get route => _route;

  Position? get currentPosition => _currentPosition;

  RouteCoordinate? get displayCoordinate => _displayCoordinate;

  HikeTrackingStatus get status => _status;

  RouteDeviationLevel get deviationLevel => _deviationLevel;

  String? get statusMessage => _statusMessage;

  double? get distanceFromRouteMeters => _distanceFromRouteMeters;

  bool get hasActiveSession {
    return _metadata != null &&
        _status != HikeTrackingStatus.idle &&
        _status != HikeTrackingStatus.completed;
  }

  bool get completionCandidate => _completionCandidate;

  int get offRouteWarningVersion => _offRouteWarningVersion;

  int get completionPromptVersion => _completionPromptVersion;

  Future<HikeTrackingStartResult> start({
    required HikeNavigationMetadata metadata,
    required Position initialPosition,
  }) async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;

    _metadata = metadata;
    _route = null;
    _currentPosition = initialPosition;
    _displayCoordinate = _locationService.coordinateFromPosition(
      initialPosition,
    );
    _status = HikeTrackingStatus.loadingRoute;
    _deviationLevel = RouteDeviationLevel.unknown;
    _statusMessage = 'Loading route...';
    _distanceFromRouteMeters = null;
    _completionCandidate = false;
    _offRouteSampleCount = 0;
    _destinationSampleCount = 0;
    _completionPromptIssued = false;
    notifyListeners();

    try {
      final route = await _graphHopperService.fetchRoute(
        origin: _locationService.coordinateFromPosition(initialPosition),
        destination: metadata.destination,
      );

      _route = route;
      _status = HikeTrackingStatus.active;
      _statusMessage = 'Navigation active';
      _listenToForegroundPositions();
      _handlePosition(initialPosition);
      return const HikeTrackingStartResult(started: true);
    } on GraphHopperRouteException catch (error) {
      _status = HikeTrackingStatus.routeUnavailable;
      _statusMessage = error.message;
      notifyListeners();
      return HikeTrackingStartResult(started: false, message: error.message);
    } catch (_) {
      const message = 'Unable to start navigation.';
      _status = HikeTrackingStatus.error;
      _statusMessage = message;
      notifyListeners();
      return const HikeTrackingStartResult(started: false, message: message);
    }
  }

  Future<void> recalculateRoute() async {
    final metadata = _metadata;
    final currentPosition = _currentPosition;
    if (metadata == null || currentPosition == null || _rerouteInProgress) {
      return;
    }

    await _replaceRouteFrom(
      origin: _locationService.coordinateFromPosition(currentPosition),
      loadingMessage: 'Recalculating route...',
    );
  }

  Future<void> stop() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _metadata = null;
    _route = null;
    _currentPosition = null;
    _displayCoordinate = null;
    _status = HikeTrackingStatus.idle;
    _deviationLevel = RouteDeviationLevel.unknown;
    _statusMessage = null;
    _distanceFromRouteMeters = null;
    _completionCandidate = false;
    notifyListeners();
  }

  Future<void> markCompleted() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _status = HikeTrackingStatus.completed;
    _statusMessage = 'Hike complete';
    _completionCandidate = false;
    notifyListeners();
  }

  void _listenToForegroundPositions() {
    _positionSubscription = _locationService
        .foregroundPositionStream(distanceFilterMeters: 5)
        .listen(
          _handlePosition,
          onError: (_) {
            _statusMessage = 'GPS update paused. Waiting for location signal.';
            notifyListeners();
          },
        );
  }

  void _handlePosition(Position position) {
    _currentPosition = position;
    final rawCoordinate = _locationService.coordinateFromPosition(position);
    _displayCoordinate = _smoothedDisplayCoordinate(rawCoordinate, position);

    final route = _route;
    if (route == null) {
      notifyListeners();
      return;
    }

    final reliableForDecision = _locationService.isReliableForRouteDecision(
      position,
    );

    if (reliableForDecision) {
      _updateRouteDeviation(rawCoordinate, route);
      _updateDestinationCompletion(rawCoordinate);
    } else {
      _statusMessage =
          'GPS accuracy is about ${position.accuracy.toStringAsFixed(0)}m. Holding route decisions.';
    }

    notifyListeners();
  }

  RouteCoordinate _smoothedDisplayCoordinate(
    RouteCoordinate next,
    Position position,
  ) {
    final previous = _displayCoordinate;
    if (previous == null || position.accuracy > 35) {
      return next;
    }

    final distance = previous.distanceTo(next);
    if (distance > 35) {
      return next;
    }

    final weight = distance < 3 ? 0.25 : 0.45;
    return RouteCoordinate(
      latitude:
          previous.latitude + ((next.latitude - previous.latitude) * weight),
      longitude:
          previous.longitude + ((next.longitude - previous.longitude) * weight),
    );
  }

  void _updateRouteDeviation(RouteCoordinate coordinate, HikingRoute route) {
    final distance = _distanceToRouteMeters(coordinate, route.coordinates);
    _distanceFromRouteMeters = distance;

    if (distance <= onRouteThresholdMeters) {
      _offRouteSampleCount = 0;
      _deviationLevel = RouteDeviationLevel.onRoute;
      _status = HikeTrackingStatus.active;
      _statusMessage = 'On route';
      return;
    }

    if (distance < candidateThresholdMeters) {
      _offRouteSampleCount = 0;
      _deviationLevel = RouteDeviationLevel.monitoring;
      _status = HikeTrackingStatus.monitoringOffRoute;
      _statusMessage = 'Monitoring route position';
      return;
    }

    _offRouteSampleCount += 1;
    _deviationLevel = _offRouteSampleCount >= requiredPersistentSamples
        ? RouteDeviationLevel.confirmed
        : RouteDeviationLevel.candidate;

    if (_deviationLevel == RouteDeviationLevel.confirmed) {
      _status = HikeTrackingStatus.offRoute;
      _statusMessage = 'Possible off-route condition confirmed';
      _issueOffRouteWarningIfNeeded();

      if (!_rerouteInProgress) {
        unawaited(
          _replaceRouteFrom(
            origin: coordinate,
            loadingMessage:
                'Trying to recalculate from your current position...',
          ),
        );
      }
    } else {
      _status = HikeTrackingStatus.monitoringOffRoute;
      _statusMessage = 'Possible deviation detected';
    }
  }

  void _updateDestinationCompletion(RouteCoordinate coordinate) {
    final metadata = _metadata;
    if (metadata == null || _completionPromptIssued) {
      return;
    }

    final distanceToDestination = coordinate.distanceTo(metadata.destination);
    if (distanceToDestination <= destinationRadiusMeters) {
      _destinationSampleCount += 1;
    } else {
      _destinationSampleCount = 0;
      _completionCandidate = false;
      return;
    }

    if (_destinationSampleCount >= requiredPersistentSamples) {
      _completionCandidate = true;
      _completionPromptIssued = true;
      _completionPromptVersion += 1;
    }
  }

  void _issueOffRouteWarningIfNeeded() {
    final now = DateTime.now();
    final lastWarningAt = _lastWarningAt;
    if (lastWarningAt != null &&
        now.difference(lastWarningAt) < warningCooldown) {
      return;
    }

    _lastWarningAt = now;
    _offRouteWarningVersion += 1;
  }

  Future<void> _replaceRouteFrom({
    required RouteCoordinate origin,
    required String loadingMessage,
  }) async {
    final metadata = _metadata;
    if (metadata == null || _rerouteInProgress) {
      return;
    }

    _rerouteInProgress = true;
    _status = HikeTrackingStatus.rerouting;
    _statusMessage = loadingMessage;
    notifyListeners();

    try {
      final newRoute = await _graphHopperService.fetchRoute(
        origin: origin,
        destination: metadata.destination,
      );
      _route = newRoute;
      _status = HikeTrackingStatus.active;
      _deviationLevel = RouteDeviationLevel.onRoute;
      _statusMessage = 'Route updated';
      _distanceFromRouteMeters = null;
      _offRouteSampleCount = 0;
    } on GraphHopperRouteException catch (error) {
      _status = HikeTrackingStatus.offRoute;
      _deviationLevel = RouteDeviationLevel.confirmed;
      _statusMessage =
          '${error.message} Original route is still shown for reference.';
    } catch (_) {
      _status = HikeTrackingStatus.offRoute;
      _deviationLevel = RouteDeviationLevel.confirmed;
      _statusMessage = 'Unable to recalculate. Original route is still shown.';
    } finally {
      _rerouteInProgress = false;
      notifyListeners();
    }
  }

  double _distanceToRouteMeters(
    RouteCoordinate point,
    List<RouteCoordinate> route,
  ) {
    if (route.length < 2) {
      return double.infinity;
    }

    var closest = double.infinity;
    for (var index = 0; index < route.length - 1; index += 1) {
      final distance = _distanceToSegmentMeters(
        point,
        route[index],
        route[index + 1],
      );
      if (distance < closest) {
        closest = distance;
      }
    }

    return closest;
  }

  double _distanceToSegmentMeters(
    RouteCoordinate point,
    RouteCoordinate start,
    RouteCoordinate end,
  ) {
    final originLatitudeRadians = point.latitude * math.pi / 180;

    double x(RouteCoordinate coordinate) {
      return (coordinate.longitude - point.longitude) *
          111320 *
          math.cos(originLatitudeRadians);
    }

    double y(RouteCoordinate coordinate) {
      return (coordinate.latitude - point.latitude) * 110540;
    }

    final startX = x(start);
    final startY = y(start);
    final endX = x(end);
    final endY = y(end);
    final segmentX = endX - startX;
    final segmentY = endY - startY;
    final segmentLengthSquared = (segmentX * segmentX) + (segmentY * segmentY);

    if (segmentLengthSquared == 0) {
      return math.sqrt((startX * startX) + (startY * startY));
    }

    final projection =
        (-(startX * segmentX) - (startY * segmentY)) / segmentLengthSquared;
    final clampedProjection = projection.clamp(0.0, 1.0);
    final closestX = startX + (segmentX * clampedProjection);
    final closestY = startY + (segmentY * clampedProjection);

    return math.sqrt((closestX * closestX) + (closestY * closestY));
  }
}
