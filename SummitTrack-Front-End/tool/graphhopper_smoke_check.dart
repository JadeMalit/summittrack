import 'dart:async';
import 'dart:io';

import 'package:summittrack/services/routing/graphhopper_service.dart';

Future<void> main() async {
  stdout.writeln('GraphHopper callable smoke check');
  stdout.writeln('Client API key usage: disabled');

  await _checkInvalidCoordinateGuard();

  stdout.writeln(
    'Live route request: skipped; routing is handled by Firebase Functions.',
  );
}

Future<void> _checkInvalidCoordinateGuard() async {
  const service = GraphHopperService();

  final result = await service.testRoute(
    startLatitude: 91,
    startLongitude: 125.2,
    destinationLatitude: 6.9875,
    destinationLongitude: 125.271,
    profile: 'hike',
  );

  _expect(!result.requestAttempted, 'Invalid coordinate check sent a request.');
  _expect(
    result.safeErrorMessage?.contains('Invalid start latitude') ?? false,
    'Invalid coordinate check returned an unexpected message.',
  );

  stdout.writeln('Invalid-coordinate guard: passed');
}

void _expect(bool condition, String message) {
  if (!condition) {
    throw StateError(message);
  }
}
