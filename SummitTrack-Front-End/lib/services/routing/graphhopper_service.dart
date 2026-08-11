import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:cloud_functions/cloud_functions.dart';
import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import '../../models/hiking_route.dart';
import '../../models/route_coordinate.dart';

class GraphHopperRouteException implements Exception {
  const GraphHopperRouteException(this.message);

  final String message;

  @override
  String toString() => message;
}

class GraphHopperRouteResult {
  const GraphHopperRouteResult({
    required this.apiKeyProvided,
    required this.requestAttempted,
    required this.profile,
    this.httpStatus,
    this.safeErrorMessage,
    this.safeResponseBody,
    this.pathCount = 0,
    this.hasGeometry = false,
    this.distanceMeters,
    this.durationSeconds,
    this.ascentMeters,
    this.descentMeters,
    this.pointCount = 0,
    this.requestedStart,
    this.requestedDestination,
    this.returnedFirstRoutePoint,
    this.returnedLastRoutePoint,
    this.endpointToDestinationDistanceMeters,
    this.route,
  });

  final bool apiKeyProvided;
  final bool requestAttempted;
  final String profile;
  final int? httpStatus;
  final String? safeErrorMessage;
  final String? safeResponseBody;
  final int pathCount;
  final bool hasGeometry;
  final double? distanceMeters;
  final int? durationSeconds;
  final double? ascentMeters;
  final double? descentMeters;
  final int pointCount;
  final RouteCoordinate? requestedStart;
  final RouteCoordinate? requestedDestination;
  final RouteCoordinate? returnedFirstRoutePoint;
  final RouteCoordinate? returnedLastRoutePoint;
  final double? endpointToDestinationDistanceMeters;
  final HikingRoute? route;

  bool get authenticationSucceeded {
    final status = httpStatus;
    return status != null && status >= 200 && status < 300;
  }

  bool get routeReturned => pathCount > 0;

  bool get isSuccessful {
    return authenticationSucceeded &&
        routeReturned &&
        hasGeometry &&
        route != null;
  }
}

class GraphHopperService {
  const GraphHopperService({http.Client? client});

static const routeEndpointToleranceMeters = 5000.0; // Pinalaki muna for testing

  Future<GraphHopperRouteResult> testRoute({
    required double startLatitude,
    required double startLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
    String profile = AppConfig.graphHopperProfile,
  }) {
    return _requestRoute(
      origin: RouteCoordinate(
        latitude: startLatitude,
        longitude: startLongitude,
      ),
      destination: RouteCoordinate(
        latitude: destinationLatitude,
        longitude: destinationLongitude,
      ),
      profile: profile,
    );
  }

  Future<HikingRoute> fetchRoute({
    required RouteCoordinate origin,
    required RouteCoordinate destination,
  }) async {
    final result = await _requestRoute(
      origin: origin,
      destination: destination,
      profile: AppConfig.graphHopperProfile,
    );

    final route = result.route;
    if (!result.isSuccessful || route == null) {
      throw GraphHopperRouteException(
        result.safeErrorMessage ?? 'Route unavailable from GraphHopper.',
      );
    }

    _validateRouteEndpoints(
      route: route,
      origin: origin,
      destination: destination,
    );

    return route;
  }

  Future<GraphHopperRouteResult> _requestRoute({
    required RouteCoordinate origin,
    required RouteCoordinate destination,
    required String profile,
  }) async {
    final coordinateValidationMessage =
        _coordinateValidationMessage(origin, 'start') ??
        _coordinateValidationMessage(destination, 'destination');

    if (coordinateValidationMessage != null) {
      return GraphHopperRouteResult(
        apiKeyProvided: true,
        requestAttempted: false,
        profile: profile,
        safeErrorMessage: coordinateValidationMessage,
      );
    }

    _debugLog('[GraphHopper] Starting secure route request through Firebase');
    _debugLog('[GraphHopper] Routing profile: $profile');
    _debugLog('[GraphHopper] Requested start: ${_formatCoordinate(origin)}');
    _debugLog(
      '[GraphHopper] Requested destination: ${_formatCoordinate(destination)}',
    );

    try {
      final callable = FirebaseFunctions.instanceFor(region: 'asia-southeast1')
          .httpsCallable(
            'getGraphHopperRoute',
            options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
          );

      final result = await callable.call(<String, dynamic>{
        'startLat': origin.latitude,
        'startLng': origin.longitude,
        'endLat': destination.latitude,
        'endLng': destination.longitude,
        'profile': profile,
      });

      if (result.data is! Map) {
        return GraphHopperRouteResult(
          apiKeyProvided: true,
          requestAttempted: true,
          profile: profile,
          safeErrorMessage: 'The route server returned an invalid response.',
        );
      }

      final responseData = Map<String, dynamic>.from(result.data as Map);
      final parsed = _parseSuccessfulResponse(jsonEncode(responseData));
      final returnedFirstRoutePoint = parsed.route?.coordinates.first;
      final returnedLastRoutePoint = parsed.route?.coordinates.last;
      final endpointToDestinationDistanceMeters = returnedLastRoutePoint
          ?.distanceTo(destination);

      final routeResult = GraphHopperRouteResult(
        apiKeyProvided: true,
        requestAttempted: true,
        profile: profile,
        httpStatus: 200,
        safeErrorMessage: parsed.errorMessage,
        pathCount: parsed.pathCount,
        hasGeometry: parsed.hasGeometry,
        distanceMeters: parsed.distanceMeters,
        durationSeconds: parsed.durationSeconds,
        ascentMeters: parsed.ascentMeters,
        descentMeters: parsed.descentMeters,
        pointCount: parsed.pointCount,
        requestedStart: origin,
        requestedDestination: destination,
        returnedFirstRoutePoint: returnedFirstRoutePoint,
        returnedLastRoutePoint: returnedLastRoutePoint,
        endpointToDestinationDistanceMeters:
            endpointToDestinationDistanceMeters,
        route: parsed.route,
      );

      _debugLog('[GraphHopper] Paths returned: ${routeResult.pathCount}');
      _debugLog('[GraphHopper] Route points: ${routeResult.pointCount}');
      if (returnedFirstRoutePoint != null) {
        _debugLog(
          '[GraphHopper] Returned first route point: '
          '${_formatCoordinate(returnedFirstRoutePoint)}',
        );
      }
      if (returnedLastRoutePoint != null) {
        _debugLog(
          '[GraphHopper] Returned last route point: '
          '${_formatCoordinate(returnedLastRoutePoint)}',
        );
      }
      if (endpointToDestinationDistanceMeters != null) {
        _debugLog(
          '[GraphHopper] Endpoint-to-destination distance: '
          '${_formatMeters(endpointToDestinationDistanceMeters)}',
        );
      }

      if (routeResult.isSuccessful) {
        _debugLog('[GraphHopper] Secure route request successful');
      }

      return routeResult;
    } on FirebaseFunctionsException catch (error) {
      _debugLog('[GraphHopper] Firebase Functions error: ${error.code}');

      return GraphHopperRouteResult(
        apiKeyProvided: true,
        requestAttempted: true,
        profile: profile,
        safeErrorMessage: _firebaseFunctionErrorMessage(error.code),
      );
    } on TimeoutException {
      return GraphHopperRouteResult(
        apiKeyProvided: true,
        requestAttempted: true,
        profile: profile,
        safeErrorMessage: 'The route request timed out.',
      );
    } catch (_) {
      _debugLog('[GraphHopper] Unable to process Firebase route response.');

      return GraphHopperRouteResult(
        apiKeyProvided: true,
        requestAttempted: true,
        profile: profile,
        safeErrorMessage: 'Unable to read the route server response.',
      );
    }
  }

  String _firebaseFunctionErrorMessage(String code) {
    switch (code) {
      case 'unauthenticated':
        return 'Please sign in before starting navigation.';
      case 'invalid-argument':
        return 'The start or destination coordinates are invalid.';
      case 'deadline-exceeded':
        return 'The route request timed out. Please try again.';
      case 'unavailable':
        return 'The route service is temporarily unavailable.';
      case 'permission-denied':
        return 'You do not have permission to request this route.';
      case 'resource-exhausted':
        return 'The route service usage limit has been reached.';
      case 'unknown':
        return 'Unable to retrieve the hiking route.';
      default:
        return 'Unable to retrieve the hiking route.';
    }
  }

  String? _coordinateValidationMessage(
    RouteCoordinate coordinate,
    String label,
  ) {
    final latitude = coordinate.latitude;
    final longitude = coordinate.longitude;

    if (!latitude.isFinite || latitude < -90 || latitude > 90) {
      return 'Invalid $label latitude. Enter a value between -90 and 90.';
    }

    if (!longitude.isFinite || longitude < -180 || longitude > 180) {
      return 'Invalid $label longitude. Enter a value between -180 and 180.';
    }

    return null;
  }

  void _validateRouteEndpoints({
    required HikingRoute route,
    required RouteCoordinate origin,
    required RouteCoordinate destination,
  }) {
    final startDistance = route.coordinates.first.distanceTo(origin);
    final endpointDistance = route.coordinates.last.distanceTo(destination);
    final startsNearUser = startDistance <= routeEndpointToleranceMeters;
    final endsNearDestination =
        endpointDistance <= routeEndpointToleranceMeters;

    _debugLog(
      '[GraphHopper] First-point-to-start distance: '
      '${_formatMeters(startDistance)}',
    );
    _debugLog(
      '[GraphHopper] Endpoint-to-destination validation distance: '
      '${_formatMeters(endpointDistance)}',
    );

    if (!startsNearUser || !endsNearDestination) {
      throw const GraphHopperRouteException(
        'Route unavailable because the returned path does not match the selected destination.',
      );
    }
  }

  _ParsedGraphHopperRoute _parseSuccessfulResponse(String body) {
    try {
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final paths = decoded['paths'];
      if (paths is! List || paths.isEmpty) {
        return const _ParsedGraphHopperRoute(
          pathCount: 0,
          hasGeometry: false,
          pointCount: 0,
          errorMessage: 'No route was returned for the selected coordinates.',
        );
      }

      final firstPath = paths.first;
      if (firstPath is! Map<String, dynamic>) {
        return _ParsedGraphHopperRoute(
          pathCount: paths.length,
          hasGeometry: false,
          pointCount: 0,
          errorMessage: 'GraphHopper returned an unreadable route path.',
        );
      }

      final rawDistance = firstPath['distance'];
      if (rawDistance is! num) {
        return _ParsedGraphHopperRoute(
          pathCount: paths.length,
          hasGeometry: false,
          pointCount: 0,
          errorMessage: 'GraphHopper returned a route without distance.',
        );
      }

      final rawTime = firstPath['time'];
      if (rawTime is! num) {
        return _ParsedGraphHopperRoute(
          pathCount: paths.length,
          hasGeometry: false,
          pointCount: 0,
          errorMessage: 'GraphHopper returned a route without duration.',
        );
      }

      final coordinates = _coordinatesFromPath(firstPath);
      final distanceMeters = rawDistance.toDouble();
      final durationSeconds = (rawTime.toDouble() / 1000).round();
      final ascentMeters = (firstPath['ascend'] as num?)?.toDouble();
      final descentMeters = (firstPath['descend'] as num?)?.toDouble();

      if (coordinates.length < 2) {
        return _ParsedGraphHopperRoute(
          pathCount: paths.length,
          hasGeometry: false,
          pointCount: coordinates.length,
          distanceMeters: distanceMeters,
          durationSeconds: durationSeconds,
          ascentMeters: ascentMeters,
          descentMeters: descentMeters,
          errorMessage: 'GraphHopper returned no usable route geometry.',
        );
      }

      final route = HikingRoute(
        coordinates: coordinates,
        distanceMeters: distanceMeters,
        durationSeconds: durationSeconds,
      );

      if (!route.isUsable) {
        return _ParsedGraphHopperRoute(
          pathCount: paths.length,
          hasGeometry: true,
          pointCount: coordinates.length,
          distanceMeters: distanceMeters,
          durationSeconds: durationSeconds,
          ascentMeters: ascentMeters,
          descentMeters: descentMeters,
          errorMessage: 'GraphHopper returned an unusable route.',
        );
      }

      return _ParsedGraphHopperRoute(
        pathCount: paths.length,
        hasGeometry: true,
        pointCount: coordinates.length,
        distanceMeters: distanceMeters,
        durationSeconds: durationSeconds,
        ascentMeters: ascentMeters,
        descentMeters: descentMeters,
        route: route,
      );
    } on FormatException {
      return const _ParsedGraphHopperRoute(
        pathCount: 0,
        hasGeometry: false,
        pointCount: 0,
        errorMessage: 'GraphHopper returned invalid JSON.',
      );
    } catch (_) {
      return const _ParsedGraphHopperRoute(
        pathCount: 0,
        hasGeometry: false,
        pointCount: 0,
        errorMessage: 'GraphHopper returned an unreadable response.',
      );
    }
  }

  List<RouteCoordinate> _coordinatesFromPath(Map<String, dynamic> path) {
    final points = path['points'];
    if (points is! Map<String, dynamic>) {
      return const <RouteCoordinate>[];
    }

    final rawCoordinates = points['coordinates'];
    if (rawCoordinates is! List) {
      return const <RouteCoordinate>[];
    }

    final coordinates = <RouteCoordinate>[];
    for (final entry in rawCoordinates) {
      if (entry is! List || entry.length < 2) {
        continue;
      }

      final longitude = entry[0];
      final latitude = entry[1];
      if (longitude is! num || latitude is! num) {
        continue;
      }

      coordinates.add(
        RouteCoordinate(
          latitude: latitude.toDouble(),
          longitude: longitude.toDouble(),
        ),
      );
    }

    return coordinates;
  }
}

void _debugLog(String message) {
  assert(() {
    developer.log(message, name: 'GraphHopper');
    return true;
  }());
}

String _formatCoordinate(RouteCoordinate coordinate) {
  return '${coordinate.latitude.toStringAsFixed(6)},'
      '${coordinate.longitude.toStringAsFixed(6)}';
}

String _formatMeters(double meters) {
  return '${meters.toStringAsFixed(1)}m';
}

class _ParsedGraphHopperRoute {
  const _ParsedGraphHopperRoute({
    required this.pathCount,
    required this.hasGeometry,
    required this.pointCount,
    this.distanceMeters,
    this.durationSeconds,
    this.ascentMeters,
    this.descentMeters,
    this.route,
    this.errorMessage,
  });

  final int pathCount;
  final bool hasGeometry;
  final int pointCount;
  final double? distanceMeters;
  final int? durationSeconds;
  final double? ascentMeters;
  final double? descentMeters;
  final HikingRoute? route;
  final String? errorMessage;
}
