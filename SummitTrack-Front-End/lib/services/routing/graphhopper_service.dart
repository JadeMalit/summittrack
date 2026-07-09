import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

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
  const GraphHopperService({http.Client? client}) : _client = client;

  final http.Client? _client;

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
        apiKeyProvided: AppConfig.hasGraphHopperApiKey,
        requestAttempted: false,
        profile: profile,
        safeErrorMessage: coordinateValidationMessage,
      );
    }

    _debugLog('[GraphHopper] Starting route request');
    _debugLog(
      '[GraphHopper] API key present: ${AppConfig.hasGraphHopperApiKey}',
    );

    if (!AppConfig.hasGraphHopperApiKey) {
      return GraphHopperRouteResult(
        apiKeyProvided: false,
        requestAttempted: false,
        profile: profile,
        safeErrorMessage:
            'GraphHopper API key is missing. Add GRAPHHOPPER_API_KEY with --dart-define.',
      );
    }

    final client = _client ?? http.Client();
    final shouldCloseClient = _client == null;

    try {
      final uri = Uri.https(
        'graphhopper.com',
        '/api/1/route',
        <String, dynamic>{
          'point': [
            '${origin.latitude},${origin.longitude}',
            '${destination.latitude},${destination.longitude}',
          ],
          'profile': profile,
          'points_encoded': 'false',
          'instructions': 'true',
          'locale': 'en',
          'key': AppConfig.graphHopperApiKey,
        },
      );

      final response = await client
          .get(uri)
          .timeout(const Duration(seconds: 20));

      _debugLog('[GraphHopper] HTTP status: ${response.statusCode}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return GraphHopperRouteResult(
          apiKeyProvided: true,
          requestAttempted: true,
          profile: profile,
          httpStatus: response.statusCode,
          safeErrorMessage: _messageFromResponse(
            statusCode: response.statusCode,
            body: response.body,
          ),
          safeResponseBody: _safeResponseBody(response.body),
        );
      }

      final parsed = _parseSuccessfulResponse(response.body);
      final result = GraphHopperRouteResult(
        apiKeyProvided: true,
        requestAttempted: true,
        profile: profile,
        httpStatus: response.statusCode,
        safeErrorMessage: parsed.errorMessage,
        pathCount: parsed.pathCount,
        hasGeometry: parsed.hasGeometry,
        distanceMeters: parsed.distanceMeters,
        durationSeconds: parsed.durationSeconds,
        ascentMeters: parsed.ascentMeters,
        descentMeters: parsed.descentMeters,
        pointCount: parsed.pointCount,
        route: parsed.route,
      );

      _debugLog('[GraphHopper] Paths returned: ${result.pathCount}');
      _debugLog('[GraphHopper] Route points: ${result.pointCount}');

      if (result.isSuccessful) {
        _debugLog('[GraphHopper] Route request successful');
      }

      return result;
    } on TimeoutException {
      return GraphHopperRouteResult(
        apiKeyProvided: true,
        requestAttempted: true,
        profile: profile,
        safeErrorMessage: 'GraphHopper request timed out.',
      );
    } on http.ClientException {
      return GraphHopperRouteResult(
        apiKeyProvided: true,
        requestAttempted: true,
        profile: profile,
        safeErrorMessage: 'Unable to connect to GraphHopper.',
      );
    } catch (_) {
      return GraphHopperRouteResult(
        apiKeyProvided: true,
        requestAttempted: true,
        profile: profile,
        safeErrorMessage: 'Unable to read a GraphHopper route response.',
      );
    } finally {
      if (shouldCloseClient) {
        client.close();
      }
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
    final startsNearUser = route.coordinates.first.distanceTo(origin) <= 300;
    final endsNearDestination =
        route.coordinates.last.distanceTo(destination) <= 300;

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

  String _messageFromResponse({required int statusCode, required String body}) {
    final providerMessage = _providerMessageFromResponse(body);
    final detail = providerMessage == null ? '' : ': $providerMessage';

    switch (statusCode) {
      case 400:
        return 'Invalid GraphHopper request$detail';
      case 401:
        return 'Authentication failed$detail';
      case 403:
        return 'Access denied by GraphHopper$detail';
      case 429:
        return 'GraphHopper quota or rate limit reached$detail';
      default:
        return 'GraphHopper request failed with HTTP $statusCode$detail';
    }
  }

  String? _providerMessageFromResponse(String body) {
    try {
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final message = decoded['message']?.toString();
      if (message != null && message.trim().isNotEmpty) {
        return _redactApiKey(message.trim());
      }
    } catch (_) {
      // Preserve the safe response body separately when provider JSON is absent.
    }

    return null;
  }

  String _safeResponseBody(String body) {
    final redacted = _redactApiKey(body).trim();
    if (redacted.length <= 1200) {
      return redacted;
    }

    return '${redacted.substring(0, 1200)}...';
  }

  String _redactApiKey(String value) {
    final apiKey = AppConfig.graphHopperApiKey;
    if (apiKey.trim().isEmpty) {
      return value;
    }

    return value.replaceAll(apiKey, '[redacted]');
  }
}

void _debugLog(String message) {
  assert(() {
    developer.log(message, name: 'GraphHopper');
    return true;
  }());
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
