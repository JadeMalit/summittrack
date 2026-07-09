import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:summittrack/core/config/app_config.dart';
import 'package:summittrack/services/routing/graphhopper_service.dart';

Future<void> main() async {
  final keyProvided = AppConfig.hasGraphHopperApiKey;
  stdout.writeln('GraphHopper smoke check');
  stdout.writeln('API key provided: ${keyProvided ? 'Yes' : 'No'}');

  await _checkMissingKeyGuard();
  await _checkInvalidCoordinateGuard();

  if (keyProvided) {
    await _checkRequestConstructionAndParsing();
    await _checkInvalidKeyFailure();
    await _checkUnsupportedProfileFailure();
    await _checkNetworkFailure();
    await _checkTimeoutFailure();
    await _checkNoRouteFailure();
  } else {
    stdout.writeln(
      'Request construction: skipped because API key is not provided',
    );
    stdout.writeln(
      'Authenticated error checks: skipped because API key is not provided',
    );
  }
}

Future<void> _checkMissingKeyGuard() async {
  if (AppConfig.hasGraphHopperApiKey) {
    stdout.writeln('Missing-key guard: skipped because API key is provided');
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

  _expect(!result.apiKeyProvided, 'Missing-key result reported a key.');
  _expect(!result.requestAttempted, 'Missing-key result attempted a request.');
  _expect(client.requestCount == 0, 'Missing-key check sent HTTP.');

  stdout.writeln('Missing-key guard: passed');
}

Future<void> _checkInvalidCoordinateGuard() async {
  final client = _RecordingClient((_) => http.Response('{}', 200));
  final service = GraphHopperService(client: client);

  final result = await service.testRoute(
    startLatitude: 91,
    startLongitude: 125.2,
    destinationLatitude: 6.9875,
    destinationLongitude: 125.271,
    profile: 'hike',
  );

  _expect(!result.requestAttempted, 'Invalid coordinate result sent HTTP.');
  _expect(client.requestCount == 0, 'Invalid coordinate check sent HTTP.');

  stdout.writeln('Invalid-coordinate guard: passed');
}

Future<void> _checkRequestConstructionAndParsing() async {
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

  _expect(client.requestCount == 1, 'Expected exactly one HTTP request.');

  final uri = client.lastUri;
  _expect(uri != null, 'No request URI was captured.');
  _expect(uri!.scheme == 'https', 'Route request was not HTTPS.');
  _expect(uri.host == 'graphhopper.com', 'Route request host was wrong.');
  _expect(uri.path == '/api/1/route', 'Route request path was wrong.');
  _expect(
    _listEquals(uri.queryParametersAll['point'], [
      '6.9,125.2',
      '6.9875,125.271',
    ]),
    'Route request point format was wrong.',
  );
  _expect(uri.queryParameters['profile'] == 'hike', 'Profile was wrong.');
  _expect(
    uri.queryParameters['points_encoded'] == 'false',
    'points_encoded was wrong.',
  );
  _expect(
    uri.queryParameters['instructions'] == 'true',
    'instructions was wrong.',
  );
  _expect(uri.queryParameters['locale'] == 'en', 'locale was wrong.');
  _expect(
    uri.queryParameters['key'] == AppConfig.graphHopperApiKey,
    'API key was not attached from AppConfig.',
  );

  _expect(result.authenticationSucceeded, 'Mock request did not succeed.');
  _expect(result.routeReturned, 'No route path was parsed.');
  _expect(result.hasGeometry, 'No geometry was parsed.');
  _expect(result.distanceMeters == 1234.5, 'Distance parse was wrong.');
  _expect(result.durationSeconds == 987, 'Duration parse was wrong.');
  _expect(result.ascentMeters == 45.6, 'Ascent parse was wrong.');
  _expect(result.descentMeters == 12.3, 'Descent parse was wrong.');
  _expect(result.pointCount == 2, 'Route point count was wrong.');
  _expect(
    result.route?.coordinates.first.latitude == 6.9 &&
        result.route?.coordinates.first.longitude == 125.2,
    'GraphHopper longitude,latitude geometry was parsed incorrectly.',
  );

  stdout.writeln('Request construction: passed');
  stdout.writeln('Mock HTTP status: ${result.httpStatus}');
  stdout.writeln('Mock route distance: ${result.distanceMeters} m');
  stdout.writeln('Mock route duration: ${result.durationSeconds} s');
  stdout.writeln('Mock route ascent: ${result.ascentMeters} m');
  stdout.writeln('Mock route descent: ${result.descentMeters} m');
  stdout.writeln('Mock route points: ${result.pointCount}');
}

Future<void> _checkInvalidKeyFailure() async {
  final result = await _failureResult(
    statusCode: 401,
    profile: 'hike',
    message:
        'The provided key ${AppConfig.graphHopperApiKey} is not authorized.',
  );

  _expect(result.httpStatus == 401, 'Invalid-key status was wrong.');
  _expect(!result.authenticationSucceeded, 'Invalid key authenticated.');
  _expect(
    result.safeErrorMessage?.contains('[redacted]') == true,
    'Invalid-key message did not redact the key.',
  );

  stdout.writeln('Invalid-key failure handling: passed');
}

Future<void> _checkUnsupportedProfileFailure() async {
  final result = await _failureResult(
    statusCode: 400,
    profile: 'unsupported-profile',
    message: 'Vehicle not supported: unsupported-profile',
  );

  _expect(result.httpStatus == 400, 'Unsupported-profile status was wrong.');
  _expect(
    result.safeErrorMessage?.contains('Vehicle not supported') == true,
    'Unsupported-profile message was not preserved safely.',
  );

  stdout.writeln('Unsupported-profile failure handling: passed');
}

Future<GraphHopperRouteResult> _failureResult({
  required int statusCode,
  required String profile,
  required String message,
}) async {
  final client = _RecordingClient((_) {
    return http.Response(jsonEncode({'message': message}), statusCode);
  });
  final service = GraphHopperService(client: client);

  final result = await service.testRoute(
    startLatitude: 6.9,
    startLongitude: 125.2,
    destinationLatitude: 6.9875,
    destinationLongitude: 125.271,
    profile: profile,
  );

  _expect(result.requestAttempted, 'Failure result did not attempt a request.');
  _expect(client.requestCount == 1, 'Failure check did not send one request.');
  return result;
}

Future<void> _checkNetworkFailure() async {
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

  _expect(result.requestAttempted, 'Network result did not attempt a request.');
  _expect(
    result.safeErrorMessage?.contains('Unable to connect') == true,
    'Network failure message was wrong.',
  );
  _expect(client.requestCount == 1, 'Network check did not send one request.');

  stdout.writeln('Network failure handling: passed');
}

Future<void> _checkTimeoutFailure() async {
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

  _expect(result.requestAttempted, 'Timeout result did not attempt a request.');
  _expect(
    result.safeErrorMessage?.contains('timed out') == true,
    'Timeout message was wrong.',
  );
  _expect(client.requestCount == 1, 'Timeout check did not send one request.');

  stdout.writeln('Timeout handling: passed');
}

Future<void> _checkNoRouteFailure() async {
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

  _expect(
    result.requestAttempted,
    'No-route result did not attempt a request.',
  );
  _expect(result.authenticationSucceeded, 'No-route response was not HTTP OK.');
  _expect(!result.routeReturned, 'No-route response reported a route.');
  _expect(
    result.safeErrorMessage?.contains('No route was returned') == true,
    'No-route message was wrong.',
  );
  _expect(client.requestCount == 1, 'No-route check did not send one request.');

  stdout.writeln('No-route handling: passed');
}

bool _listEquals(List<String>? left, List<String> right) {
  if (left == null || left.length != right.length) {
    return false;
  }

  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) {
      return false;
    }
  }

  return true;
}

void _expect(bool condition, String message) {
  if (!condition) {
    throw StateError(message);
  }
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
