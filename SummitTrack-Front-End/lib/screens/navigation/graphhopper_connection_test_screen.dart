import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/routing/app_routes.dart';
import '../../data/navigation/navigation_trails.dart';
import '../../models/hike_navigation_metadata.dart';
import '../../models/route_coordinate.dart';
import '../../services/location/location_service.dart';
import '../../services/routing/graphhopper_service.dart';
import '../../services/routing/trailhead_proximity_guard.dart';

class GraphHopperConnectionTestScreen extends StatefulWidget {
  const GraphHopperConnectionTestScreen({super.key});

  @override
  State<GraphHopperConnectionTestScreen> createState() {
    return _GraphHopperConnectionTestScreenState();
  }
}

class _GraphHopperConnectionTestScreenState
    extends State<GraphHopperConnectionTestScreen> {
  final GraphHopperService _graphHopperService = const GraphHopperService();
  final LocationService _locationService = const LocationService();

  GraphHopperRouteResult? _result;
  String? _message;
  bool? _startCoordinateAvailable;
  bool? _destinationCoordinateAvailable;
  bool _isTesting = false;
  int _requestCount = 0;

  HikeNavigationMetadata? get _testMetadata {
    return NavigationTrails.forTrailId(AppRoutes.staCruzTrailId);
  }

  bool get _hasDestinationCoordinate => _testMetadata != null;

  @override
  void initState() {
    super.initState();
    debugPrint(
      '[Config] GraphHopper routes use Firebase callable secret storage.',
    );
  }

  Future<void> _testConnection({bool useDebugTrailheadStart = false}) async {
    if (_isTesting) {
      return;
    }

    debugPrint(
      '[Config] GraphHopper routes use Firebase callable secret storage.',
    );

    final metadata = _testMetadata;
    if (metadata == null) {
      setState(() {
        _result = null;
        _startCoordinateAvailable = null;
        _destinationCoordinateAvailable = false;
        _message =
            'No verified destination coordinate is available for a real route test.';
      });
      return;
    }

    setState(() {
      _isTesting = true;
      _result = null;
      _startCoordinateAvailable = null;
      _destinationCoordinateAvailable = true;
      _message = useDebugTrailheadStart
          ? 'Preparing debug trailhead start...'
          : 'Reading current GPS location...';
    });

    final start = useDebugTrailheadStart
        ? _debugTrailheadStart(metadata)
        : await _currentGpsStart(metadata);

    if (!mounted) {
      return;
    }

    if (start == null) {
      return;
    }

    final result = await _graphHopperService.testRoute(
      startLatitude: start.latitude,
      startLongitude: start.longitude,
      destinationLatitude: metadata.destination.latitude,
      destinationLongitude: metadata.destination.longitude,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isTesting = false;
      _result = result;
      _message =
          result.safeErrorMessage ??
          (result.isSuccessful
              ? 'GraphHopper route request successful.'
              : null);
      if (result.requestAttempted) {
        _requestCount += 1;
      }
    });
  }

  Future<RouteCoordinate?> _currentGpsStart(
    HikeNavigationMetadata metadata,
  ) async {
    final readiness = await _locationService.requestNavigationReadiness();

    if (!mounted) {
      return null;
    }

    final position = readiness.position;
    if (!readiness.isReady || position == null) {
      debugPrint('[GraphHopper] Start coordinate available: false');
      debugPrint('[GraphHopper] Destination coordinate available: true');

      setState(() {
        _isTesting = false;
        _startCoordinateAvailable = false;
        _message = readiness.message;
      });
      return null;
    }

    final start = _locationService.coordinateFromPosition(position);
    final proximity = TrailheadProximityGuard.evaluate(
      metadata: metadata,
      currentLocation: start,
    );
    if (!proximity.canStart) {
      debugPrint('[GraphHopper] Start coordinate available: true');
      debugPrint('[GraphHopper] Destination coordinate available: true');
      debugPrint('[GraphHopper] Trailhead proximity: blocked');

      setState(() {
        _isTesting = false;
        _startCoordinateAvailable = true;
        _message = proximity.message;
      });
      return null;
    }

    debugPrint('[GraphHopper] Start coordinate available: true');
    debugPrint('[GraphHopper] Destination coordinate available: true');
    debugPrint('[GraphHopper] Trailhead proximity: allowed');

    setState(() {
      _startCoordinateAvailable = true;
      _message = 'Testing GraphHopper route...';
    });
    return start;
  }

  RouteCoordinate? _debugTrailheadStart(HikeNavigationMetadata metadata) {
    final position = DebugTrailheadStartSimulator.simulatedPositionFor(
      metadata: metadata,
    );
    if (position == null) {
      setState(() {
        _isTesting = false;
        _startCoordinateAvailable = false;
        _message = 'Debug trailhead start is unavailable in this build.';
      });
      return null;
    }

    debugPrint('[GraphHopper] Start coordinate available: true');
    debugPrint('[GraphHopper] Destination coordinate available: true');
    debugPrint('[GraphHopper] Debug simulated trailhead start: true');

    setState(() {
      _startCoordinateAvailable = true;
      _message = 'Testing GraphHopper route from debug trailhead...';
    });
    return _locationService.coordinateFromPosition(position);
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;

    return Scaffold(
      appBar: AppBar(title: const Text('GraphHopper Connection Test')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GraphHopper Configuration',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              _InfoRow(
                label: 'API Key Source',
                value: 'Firebase Secret Manager via callable',
              ),
              _InfoRow(
                label: 'Routing Profile',
                value: _result?.profile ?? AppConfig.graphHopperProfile,
              ),
              _InfoRow(
                label: 'Start Coordinate Source',
                value: 'Current GPS via LocationService',
              ),
              _InfoRow(
                label: 'Destination Coordinate Source',
                value: _destinationSourceLabel,
              ),
              _InfoRow(
                label: 'Start Coordinate Available',
                value: _availabilityLabel(_startCoordinateAvailable),
              ),
              _InfoRow(
                label: 'Destination Coordinate Available',
                value: _availabilityLabel(
                  _destinationCoordinateAvailable ?? _hasDestinationCoordinate,
                ),
              ),
              _InfoRow(label: 'Requests Sent', value: _requestCount.toString()),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _isTesting ? null : _testConnection,
                child: Text(
                  _isTesting
                      ? 'Testing GraphHopper Route...'
                      : 'Test GraphHopper Route',
                ),
              ),
              if (_canDebugTrailheadStart) ...[
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: _isTesting
                      ? null
                      : () => _testConnection(useDebugTrailheadStart: true),
                  child: const Text('Test From Trailhead (Debug)'),
                ),
              ],
              if (_message != null) ...[
                const SizedBox(height: 20),
                Text(_message!),
              ],
              if (result != null) ...[
                const SizedBox(height: 24),
                Text(
                  'GraphHopper Test Result',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  label: 'Request Attempted',
                  value: result.requestAttempted ? 'Yes' : 'No',
                ),
                _InfoRow(
                  label: 'HTTP Status',
                  value: result.httpStatus?.toString() ?? 'None',
                ),
                _InfoRow(
                  label: 'Authentication',
                  value: result.authenticationSucceeded ? 'Success' : 'Failed',
                ),
                _InfoRow(label: 'Profile', value: result.profile),
                _InfoRow(
                  label: 'Route Returned',
                  value: result.routeReturned ? 'Yes' : 'No',
                ),
                _InfoRow(
                  label: 'Paths Returned',
                  value: result.pathCount.toString(),
                ),
                _InfoRow(
                  label: 'Route Geometry',
                  value: result.hasGeometry ? 'Present' : 'Missing',
                ),
                _InfoRow(
                  label: 'Distance',
                  value: result.distanceMeters == null
                      ? 'N/A'
                      : _formatDistance(result.distanceMeters!),
                ),
                _InfoRow(
                  label: 'Duration',
                  value: result.durationSeconds == null
                      ? 'N/A'
                      : _formatDuration(result.durationSeconds!),
                ),
                _InfoRow(
                  label: 'Ascent',
                  value: result.ascentMeters == null
                      ? 'N/A'
                      : '${result.ascentMeters!.toStringAsFixed(1)} m',
                ),
                _InfoRow(
                  label: 'Descent',
                  value: result.descentMeters == null
                      ? 'N/A'
                      : '${result.descentMeters!.toStringAsFixed(1)} m',
                ),
                _InfoRow(
                  label: 'Route Points',
                  value: result.pointCount.toString(),
                ),
                _InfoRow(
                  label: 'Requested Start',
                  value: _formatCoordinate(result.requestedStart),
                ),
                _InfoRow(
                  label: 'Requested Destination',
                  value: _formatCoordinate(result.requestedDestination),
                ),
                _InfoRow(
                  label: 'Returned First Point',
                  value: _formatCoordinate(result.returnedFirstRoutePoint),
                ),
                _InfoRow(
                  label: 'Returned Last Point',
                  value: _formatCoordinate(result.returnedLastRoutePoint),
                ),
                _InfoRow(
                  label: 'Endpoint Mismatch',
                  value: result.endpointToDestinationDistanceMeters == null
                      ? 'N/A'
                      : '${result.endpointToDestinationDistanceMeters!.toStringAsFixed(1)} m',
                ),
                if (result.safeResponseBody != null) ...[
                  const SizedBox(height: 16),
                  SelectableText(result.safeResponseBody!),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  String get _destinationSourceLabel {
    final metadata = _testMetadata;
    if (metadata == null) {
      return 'None';
    }

    return '${metadata.destinationName} (${metadata.trailName})';
  }

  String _availabilityLabel(bool? value) {
    if (value == null) {
      return 'Not checked';
    }

    return value ? 'Yes' : 'No';
  }

  String _formatDistance(double meters) {
    return '${(meters / 1000).toStringAsFixed(2)} km';
  }

  String _formatCoordinate(RouteCoordinate? coordinate) {
    if (coordinate == null) {
      return 'N/A';
    }

    return '${coordinate.latitude.toStringAsFixed(6)}, '
        '${coordinate.longitude.toStringAsFixed(6)}';
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds / 60).round();
    return '$minutes minutes';
  }

  bool get _canDebugTrailheadStart {
    return DebugTrailheadStartSimulator.isAvailable() &&
        _testMetadata?.trailhead != null;
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 190,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
