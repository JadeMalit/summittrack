import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/routing/app_routes.dart';
import '../../data/navigation/navigation_trails.dart';
import '../../models/hike_navigation_metadata.dart';
import '../../services/location/location_service.dart';
import '../../services/routing/graphhopper_service.dart';

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
      '[Config] GraphHopper API key provided: ${AppConfig.hasGraphHopperApiKey}',
    );
  }

  Future<void> _testConnection() async {
    if (_isTesting) {
      return;
    }

    debugPrint(
      '[Config] GraphHopper API key provided: ${AppConfig.hasGraphHopperApiKey}',
    );

    if (!AppConfig.hasGraphHopperApiKey) {
      setState(() {
        _result = null;
        _startCoordinateAvailable = null;
        _destinationCoordinateAvailable = _hasDestinationCoordinate;
        _message = 'GraphHopper API key is not provided.';
      });
      return;
    }

    final metadata = _testMetadata;
    if (metadata == null) {
      setState(() {
        _result = null;
        _startCoordinateAvailable = null;
        _destinationCoordinateAvailable = false;
        _message =
            'API key detected successfully, but no verified destination coordinate is available for a real route test.';
      });
      return;
    }

    setState(() {
      _isTesting = true;
      _result = null;
      _startCoordinateAvailable = null;
      _destinationCoordinateAvailable = true;
      _message = 'Reading current GPS location...';
    });

    final readiness = await _locationService.requestNavigationReadiness();

    if (!mounted) {
      return;
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
      return;
    }

    final start = _locationService.coordinateFromPosition(position);

    debugPrint('[GraphHopper] Start coordinate available: true');
    debugPrint('[GraphHopper] Destination coordinate available: true');

    setState(() {
      _startCoordinateAvailable = true;
      _message = 'Testing GraphHopper route...';
    });

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
                label: 'API Key Provided',
                value: AppConfig.hasGraphHopperApiKey ? 'Yes' : 'No',
              ),
              _InfoRow(
                label: 'Routing Profile',
                value: AppConfig.graphHopperProfile,
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

  String _formatDuration(int seconds) {
    final minutes = (seconds / 60).round();
    return '$minutes minutes';
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
