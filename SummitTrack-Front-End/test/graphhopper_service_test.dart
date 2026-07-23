import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart'
    show FirebaseFunctionsException;
// ignore: depend_on_referenced_packages
import 'package:cloud_functions_platform_interface/cloud_functions_platform_interface.dart'
    as functions_platform;
import 'package:firebase_core/firebase_core.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart'
    as core_platform;
// ignore: depend_on_referenced_packages
import 'package:firebase_core_platform_interface/test.dart' as core_test;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:summittrack/models/route_coordinate.dart';
import 'package:summittrack/services/routing/graphhopper_service.dart';

void main() {
  final functionState = _MockFunctionState();

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    _resetFirebaseCoreMocks();
    await Firebase.initializeApp();
    functions_platform.FirebaseFunctionsPlatform.instance =
        _MockFirebaseFunctionsPlatform(
          region: 'us-central1',
          state: functionState,
        );
  });

  setUp(functionState.reset);

  test(
    'sends allowed route values to the deployed callable function',
    () async {
      functionState.handler = (_) => _successfulGraphHopperResponse();
      final service = GraphHopperService(client: _RecordingClient());

      final result = await service.testRoute(
        startLatitude: 6.9,
        startLongitude: 125.2,
        destinationLatitude: 6.9875,
        destinationLongitude: 125.271,
        profile: 'hike',
      );

      final invocation = functionState.lastInvocation;
      expect(invocation, isNotNull);
      expect(invocation!.functionName, 'getGraphHopperRoute');
      expect(invocation.region, 'asia-southeast1');
      expect(invocation.timeout, const Duration(seconds: 30));
      expect(invocation.parameters, {
        'startLat': 6.9,
        'startLng': 125.2,
        'endLat': 6.9875,
        'endLng': 125.271,
        'profile': 'hike',
      });
      expect((invocation.parameters as Map).keys, hasLength(5));

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
      expect(result.requestedStart?.latitude, 6.9);
      expect(result.requestedStart?.longitude, 125.2);
      expect(result.requestedDestination?.latitude, 6.9875);
      expect(result.requestedDestination?.longitude, 125.271);
      expect(result.returnedFirstRoutePoint?.latitude, 6.9);
      expect(result.returnedFirstRoutePoint?.longitude, 125.2);
      expect(result.returnedLastRoutePoint?.latitude, 6.9875);
      expect(result.returnedLastRoutePoint?.longitude, 125.271);
      expect(result.endpointToDestinationDistanceMeters, lessThan(1));
      expect(result.route?.coordinates.first.latitude, 6.9);
      expect(result.route?.coordinates.first.longitude, 125.2);
    },
  );

  test(
    'parses GraphHopper longitude-latitude geometry into Flutter latitude-longitude order',
    () async {
      functionState.handler = (_) => _successfulGraphHopperResponse(
        startLatitude: 6.95525,
        startLongitude: 125.32062,
        destinationLatitude: 6.9875,
        destinationLongitude: 125.271,
      );
      final service = const GraphHopperService();

      final result = await service.testRoute(
        startLatitude: 6.95525,
        startLongitude: 125.32062,
        destinationLatitude: 6.9875,
        destinationLongitude: 125.271,
        profile: 'hike',
      );

      expect(result.route?.coordinates.first.latitude, 6.95525);
      expect(result.route?.coordinates.first.longitude, 125.32062);
      expect(result.route?.coordinates.last.latitude, 6.9875);
      expect(result.route?.coordinates.last.longitude, 125.271);
    },
  );

  test('fetchRoute accepts returned endpoint within tolerance', () async {
    const origin = RouteCoordinate(latitude: 6.95525, longitude: 125.32062);
    const destination = RouteCoordinate(latitude: 6.9875, longitude: 125.271);
    functionState.handler = (_) => _successfulGraphHopperResponse(
      startLatitude: origin.latitude,
      startLongitude: origin.longitude,
      destinationLatitude: 6.9877,
      destinationLongitude: 125.2711,
    );
    final service = const GraphHopperService();

    final route = await service.fetchRoute(
      origin: origin,
      destination: destination,
    );

    expect(
      route.coordinates.last.distanceTo(destination),
      lessThan(GraphHopperService.routeEndpointToleranceMeters),
    );
  });

  test('fetchRoute rejects returned endpoint outside tolerance', () async {
    const origin = RouteCoordinate(latitude: 6.95525, longitude: 125.32062);
    const destination = RouteCoordinate(latitude: 6.9875, longitude: 125.271);
    functionState.handler = (_) => _successfulGraphHopperResponse(
      startLatitude: origin.latitude,
      startLongitude: origin.longitude,
      destinationLatitude: 6.9912,
      destinationLongitude: 125.2739,
    );
    final service = const GraphHopperService();

    await expectLater(
      service.fetchRoute(origin: origin, destination: destination),
      throwsA(
        isA<GraphHopperRouteException>().having(
          (error) => error.message,
          'message',
          contains('returned path does not match'),
        ),
      ),
    );
  });

  test('invalid coordinates are rejected before callable request', () async {
    final client = _RecordingClient();
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
    expect(functionState.callCount, 0);
    expect(client.requestCount, 0);
  });

  test('empty callable route response is reported as no route', () async {
    functionState.handler = (_) => {'paths': []};
    final service = const GraphHopperService();

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
    expect(functionState.callCount, 1);
  });

  test('non-map callable response is reported safely', () async {
    functionState.handler = (_) => ['unexpected'];
    final service = const GraphHopperService();

    final result = await service.testRoute(
      startLatitude: 6.9,
      startLongitude: 125.2,
      destinationLatitude: 6.9875,
      destinationLongitude: 125.271,
      profile: 'hike',
    );

    expect(result.requestAttempted, isTrue);
    expect(result.safeErrorMessage, contains('invalid response'));
    expect(functionState.callCount, 1);
  });

  test('Firebase callable errors map to safe user-facing messages', () async {
    final service = const GraphHopperService();
    final expectedMessages = <String, String>{
      'unauthenticated': 'Please sign in before starting navigation.',
      'invalid-argument': 'The start or destination coordinates are invalid.',
      'deadline-exceeded': 'The route request timed out. Please try again.',
      'unavailable': 'The route service is temporarily unavailable.',
      'permission-denied': 'You do not have permission to request this route.',
      'resource-exhausted': 'The route service usage limit has been reached.',
      'unknown': 'Unable to retrieve the hiking route.',
    };

    for (final entry in expectedMessages.entries) {
      functionState.reset();
      functionState.handler = (_) {
        throw _TestFirebaseFunctionsException(
          code: entry.key,
          message: 'Raw backend error detail that must not be displayed.',
        );
      };

      final result = await service.testRoute(
        startLatitude: 6.9,
        startLongitude: 125.2,
        destinationLatitude: 6.9875,
        destinationLongitude: 125.271,
        profile: 'hike',
      );

      expect(result.requestAttempted, isTrue);
      expect(result.safeErrorMessage, entry.value);
      expect(
        result.safeErrorMessage,
        isNot(contains('Raw backend error detail')),
      );
    }
  });

  test('generic callable failures are reported safely', () async {
    functionState.handler = (_) {
      throw StateError('Sensitive backend detail');
    };
    final service = const GraphHopperService();

    final result = await service.testRoute(
      startLatitude: 6.9,
      startLongitude: 125.2,
      destinationLatitude: 6.9875,
      destinationLongitude: 125.271,
      profile: 'hike',
    );

    expect(result.requestAttempted, isTrue);
    expect(
      result.safeErrorMessage,
      'Unable to read the route server response.',
    );
    expect(
      result.safeErrorMessage,
      isNot(contains('Sensitive backend detail')),
    );
  });
}

void _resetFirebaseCoreMocks() {
  core_platform.MethodChannelFirebase.appInstances = {};
  core_platform.MethodChannelFirebase.isCoreInitialized = false;
  core_platform.FirebasePlatform.instance =
      core_platform.MethodChannelFirebase();
  core_test.setupFirebaseCoreMocks();
}

Map<String, dynamic> _successfulGraphHopperResponse({
  double startLatitude = 6.9,
  double startLongitude = 125.2,
  double destinationLatitude = 6.9875,
  double destinationLongitude = 125.271,
}) {
  return {
    'paths': [
      {
        'distance': 1234.5,
        'time': 987000,
        'ascend': 45.6,
        'descend': 12.3,
        'points': {
          'type': 'LineString',
          'coordinates': [
            [startLongitude, startLatitude],
            [destinationLongitude, destinationLatitude],
          ],
        },
      },
    ],
  };
}

typedef _CallableHandler = FutureOr<dynamic> Function(dynamic parameters);

class _MockFunctionState {
  _CallableHandler? handler;
  _CallableInvocation? lastInvocation;
  int callCount = 0;

  void reset() {
    handler = null;
    lastInvocation = null;
    callCount = 0;
  }
}

class _CallableInvocation {
  const _CallableInvocation({
    required this.functionName,
    required this.region,
    required this.timeout,
    required this.parameters,
  });

  final String? functionName;
  final String region;
  final Duration timeout;
  final dynamic parameters;
}

class _MockFirebaseFunctionsPlatform
    extends functions_platform.FirebaseFunctionsPlatform {
  _MockFirebaseFunctionsPlatform({
    required String region,
    required this.state,
    FirebaseApp? app,
  }) : super(app, region);

  final _MockFunctionState state;

  @override
  functions_platform.FirebaseFunctionsPlatform delegateFor({
    FirebaseApp? app,
    required String region,
  }) {
    return _MockFirebaseFunctionsPlatform(
      app: app,
      region: region,
      state: state,
    );
  }

  @override
  functions_platform.HttpsCallablePlatform httpsCallable(
    String? origin,
    String name,
    functions_platform.HttpsCallableOptions options,
  ) {
    return _MockHttpsCallablePlatform(this, origin, name, options, null, state);
  }

  @override
  functions_platform.HttpsCallablePlatform httpsCallableWithUri(
    String? origin,
    Uri uri,
    functions_platform.HttpsCallableOptions options,
  ) {
    return _MockHttpsCallablePlatform(this, origin, null, options, uri, state);
  }
}

class _MockHttpsCallablePlatform
    extends functions_platform.HttpsCallablePlatform {
  _MockHttpsCallablePlatform(
    super.functions,
    super.origin,
    super.name,
    super.options,
    super.uri,
    this.state,
  );

  final _MockFunctionState state;

  @override
  Future<dynamic> call([dynamic parameters]) async {
    state.callCount += 1;
    state.lastInvocation = _CallableInvocation(
      functionName: name,
      region: functions.region,
      timeout: options.timeout,
      parameters: parameters,
    );

    final handler = state.handler;
    if (handler == null) {
      return {'paths': []};
    }

    return handler(parameters);
  }
}

class _TestFirebaseFunctionsException extends FirebaseFunctionsException {
  _TestFirebaseFunctionsException({
    required super.code,
    required super.message,
  });
}

class _RecordingClient extends http.BaseClient {
  int requestCount = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    requestCount += 1;
    throw StateError('HTTP client should not be used for GraphHopper routes.');
  }
}
