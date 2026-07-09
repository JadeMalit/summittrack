import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:summittrack/core/config/app_config.dart';
import 'package:summittrack/services/routing/graphhopper_service.dart';

void main() {
  test('GraphHopper key presence matches the compile-time environment', () {
    expect(
      AppConfig.hasGraphHopperApiKey,
      AppConfig.graphHopperApiKey.trim().isNotEmpty,
    );
  });

  test('missing API key stops before any HTTP request', () async {
    if (AppConfig.hasGraphHopperApiKey) {
      return;
    }

    final client = _RecordingClient((_) => http.Response('{}', 500));
    final service = GraphHopperService(client: client);

    final result = await service.testRoute(
      startLatitude: 6.9,
      startLongitude: 125.2,
      destinationLatitude: 6.9875,
      destinationLongitude: 125.271,
      profile: 'hike',
    );

    expect(result.apiKeyProvided, isFalse);
    expect(result.requestAttempted, isFalse);
    expect(result.safeErrorMessage, contains('API key is missing'));
    expect(client.requestCount, 0);
  });

  test('provided API key is included in one route request', () async {
    if (!AppConfig.hasGraphHopperApiKey) {
      return;
    }

    final client = _RecordingClient((_) {
      return http.Response(
        jsonEncode({
          'paths': [
            {
              'distance': 1234.5,
              'time': 987000,
              'ascend': 45.6,
              'descend': 12.3,
              'points': {
                'type': 'LineString',
                'coordinates': [
                  [125.2, 6.9],
                  [125.271, 6.9875],
                ],
              },
            },
          ],
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final service = GraphHopperService(client: client);

    final result = await service.testRoute(
      startLatitude: 6.9,
      startLongitude: 125.2,
      destinationLatitude: 6.9875,
      destinationLongitude: 125.271,
      profile: 'hike',
    );

    expect(client.requestCount, 1);

    final uri = client.lastUri;
    expect(uri, isNotNull);
    expect(uri!.scheme, 'https');
    expect(uri.host, 'graphhopper.com');
    expect(uri.path, '/api/1/route');
    expect(uri.queryParametersAll['point'], ['6.9,125.2', '6.9875,125.271']);
    expect(uri.queryParameters['profile'], 'hike');
    expect(uri.queryParameters['points_encoded'], 'false');
    expect(uri.queryParameters['instructions'], 'true');
    expect(uri.queryParameters['locale'], 'en');
    expect(uri.queryParameters['key'], AppConfig.graphHopperApiKey);

    expect(result.requestAttempted, isTrue);
    expect(result.httpStatus, 200);
    expect(result.authenticationSucceeded, isTrue);
    expect(result.routeReturned, isTrue);
    expect(result.hasGeometry, isTrue);
    expect(result.distanceMeters, 1234.5);
    expect(result.durationSeconds, 987);
    expect(result.ascentMeters, 45.6);
    expect(result.descentMeters, 12.3);
    expect(result.pointCount, 2);
    expect(result.route?.coordinates.first.latitude, 6.9);
    expect(result.route?.coordinates.first.longitude, 125.2);
  });

  test('invalid coordinates are rejected before HTTP request', () async {
    final client = _RecordingClient((_) => http.Response('{}', 200));
    final service = GraphHopperService(client: client);

    final result = await service.testRoute(
      startLatitude: 91,
      startLongitude: 125.2,
      destinationLatitude: 6.9875,
      destinationLongitude: 125.271,
      profile: 'hike',
    );

    expect(result.requestAttempted, isFalse);
    expect(result.safeErrorMessage, contains('Invalid start latitude'));
    expect(client.requestCount, 0);
  });

  test('provider error response redacts the configured key', () async {
    if (!AppConfig.hasGraphHopperApiKey) {
      return;
    }

    final client = _RecordingClient((_) {
      return http.Response(
        jsonEncode({
          'message':
              'The provided key ${AppConfig.graphHopperApiKey} cannot use this profile.',
        }),
        401,
      );
    });
    final service = GraphHopperService(client: client);

    final result = await service.testRoute(
      startLatitude: 6.9,
      startLongitude: 125.2,
      destinationLatitude: 6.9875,
      destinationLongitude: 125.271,
      profile: 'unsupported-profile',
    );

    expect(result.requestAttempted, isTrue);
    expect(result.httpStatus, 401);
    expect(
      result.safeErrorMessage,
      isNot(contains(AppConfig.graphHopperApiKey)),
    );
    expect(
      result.safeResponseBody,
      isNot(contains(AppConfig.graphHopperApiKey)),
    );
    expect(result.safeErrorMessage, contains('[redacted]'));
    expect(client.requestCount, 1);
  });

  test('network failure is reported without crashing', () async {
    if (!AppConfig.hasGraphHopperApiKey) {
      return;
    }

    final client = _RecordingClient((_) {
      throw http.ClientException('Connection failed');
    });
    final service = GraphHopperService(client: client);

    final result = await service.testRoute(
      startLatitude: 6.9,
      startLongitude: 125.2,
      destinationLatitude: 6.9875,
      destinationLongitude: 125.271,
      profile: 'hike',
    );

    expect(result.requestAttempted, isTrue);
    expect(result.safeErrorMessage, contains('Unable to connect'));
    expect(client.requestCount, 1);
  });

  test('timeout is reported without crashing', () async {
    if (!AppConfig.hasGraphHopperApiKey) {
      return;
    }

    final client = _RecordingClient((_) {
      throw TimeoutException('Timed out');
    });
    final service = GraphHopperService(client: client);

    final result = await service.testRoute(
      startLatitude: 6.9,
      startLongitude: 125.2,
      destinationLatitude: 6.9875,
      destinationLongitude: 125.271,
      profile: 'hike',
    );

    expect(result.requestAttempted, isTrue);
    expect(result.safeErrorMessage, contains('timed out'));
    expect(client.requestCount, 1);
  });

  test('empty route response is reported as no route', () async {
    if (!AppConfig.hasGraphHopperApiKey) {
      return;
    }

    final client = _RecordingClient((_) {
      return http.Response(jsonEncode({'paths': []}), 200);
    });
    final service = GraphHopperService(client: client);

    final result = await service.testRoute(
      startLatitude: 6.9,
      startLongitude: 125.2,
      destinationLatitude: 6.9875,
      destinationLongitude: 125.271,
      profile: 'hike',
    );

    expect(result.requestAttempted, isTrue);
    expect(result.authenticationSucceeded, isTrue);
    expect(result.routeReturned, isFalse);
    expect(result.safeErrorMessage, contains('No route was returned'));
    expect(client.requestCount, 1);
  });
}

class _RecordingClient extends http.BaseClient {
  _RecordingClient(this._handler);

  final FutureOr<http.Response> Function(http.BaseRequest request) _handler;

  int requestCount = 0;
  Uri? lastUri;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requestCount += 1;
    lastUri = request.url;

    final response = await _handler(request);
    return http.StreamedResponse(
      Stream<List<int>>.value(response.bodyBytes),
      response.statusCode,
      contentLength: response.contentLength,
      request: request,
      headers: response.headers,
      reasonPhrase: response.reasonPhrase,
    );
  }
}
