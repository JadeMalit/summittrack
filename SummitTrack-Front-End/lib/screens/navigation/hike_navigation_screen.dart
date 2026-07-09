import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../core/config/app_config.dart';
import '../../models/hike_navigation_start_request.dart';
import '../../models/hiking_route.dart';
import '../../models/route_coordinate.dart';
import '../../services/tracking/hike_tracking_service.dart';

class HikeNavigationScreen extends StatefulWidget {
  const HikeNavigationScreen({super.key, this.startRequest});

  final HikeNavigationStartRequest? startRequest;

  @override
  State<HikeNavigationScreen> createState() => _HikeNavigationScreenState();
}

class _HikeNavigationScreenState extends State<HikeNavigationScreen> {
  final HikeTrackingService _trackingService = HikeTrackingService.instance;

  MapLibreMapController? _mapController;
  bool _styleReady = false;
  bool _autoFollow = true;
  bool _programmaticCameraMove = false;
  bool _starting = false;
  int _handledOffRouteWarningVersion = 0;
  int _handledCompletionPromptVersion = 0;
  HikingRoute? _drawnRoute;
  Line? _routeLine;
  Circle? _userCircle;
  Circle? _destinationCircle;
  final List<Circle> _checkpointCircles = <Circle>[];

  @override
  void initState() {
    super.initState();
    _trackingService.addListener(_handleTrackingChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startIfNeeded();
    });
  }

  @override
  void dispose() {
    _trackingService.removeListener(_handleTrackingChanged);
    super.dispose();
  }

  Future<void> _startIfNeeded() async {
    final request = widget.startRequest;
    if (request == null || _trackingService.hasActiveSession || _starting) {
      return;
    }

    setState(() {
      _starting = true;
    });

    await _trackingService.start(
      metadata: request.metadata,
      initialPosition: request.initialPosition,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _starting = false;
    });
    await _syncMapAnnotations();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) {
          return;
        }

        final shouldLeave = await _confirmLeaveKeepSession();
        if (shouldLeave && mounted) {
          Navigator.of(this.context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0B120D),
        body: Stack(
          children: [
            Positioned.fill(child: _buildMap()),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: _buildTopBar(),
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildStatusHud(),
                ),
              ),
            ),
            if (_starting)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.38),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    final target = _initialMapTarget();

    return MapLibreMap(
      styleString: AppConfig.openFreeMapStyleUrl,
      initialCameraPosition: CameraPosition(target: target, zoom: 14),
      compassEnabled: true,
      rotateGesturesEnabled: true,
      scrollGesturesEnabled: true,
      zoomGesturesEnabled: true,
      tiltGesturesEnabled: true,
      myLocationEnabled: false,
      onMapCreated: (controller) {
        _mapController = controller;
      },
      onStyleLoadedCallback: () async {
        _styleReady = true;
        await _syncMapAnnotations();
      },
      onCameraMove: (_) {
        if (_autoFollow && !_programmaticCameraMove) {
          setState(() {
            _autoFollow = false;
          });
        }
      },
    );
  }

  Widget _buildTopBar() {
    final metadata = _trackingService.metadata ?? widget.startRequest?.metadata;

    return Row(
      children: [
        _RoundMapButton(
          icon: Icons.arrow_back_rounded,
          tooltip: 'Leave map',
          onPressed: () async {
            final shouldLeave = await _confirmLeaveKeepSession();
            if (shouldLeave && mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: const Color(0xFF0B120D).withValues(alpha: 0.86),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  metadata?.trailName ?? 'Hiking navigation',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.fredoka(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  metadata?.destinationName ?? 'Preparing route',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFB8C7B7),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        _RoundMapButton(
          icon: Icons.stop_rounded,
          tooltip: 'End navigation',
          onPressed: _confirmStopNavigation,
        ),
      ],
    );
  }

  Widget _buildStatusHud() {
    final status = _trackingService.status;
    final position = _trackingService.currentPosition;
    final accuracy = position?.accuracy;
    final distanceFromRoute = _trackingService.distanceFromRouteMeters;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B120D).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.32),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(_statusIcon(status), color: _statusColor(status), size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _statusTitle(status),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _trackingService.statusMessage ??
                          'Waiting for navigation state...',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFFB8C7B7),
                        fontSize: 11.5,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              _RoundMapButton(
                icon: Icons.my_location_rounded,
                tooltip: 'Recenter',
                compact: true,
                onPressed: _recenterOnUser,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetricChip(
                icon: Icons.gps_fixed_rounded,
                label: accuracy == null
                    ? 'GPS pending'
                    : 'GPS ${accuracy.toStringAsFixed(0)}m',
              ),
              _MetricChip(
                icon: Icons.route_rounded,
                label: distanceFromRoute == null
                    ? 'Route pending'
                    : '${distanceFromRoute.toStringAsFixed(0)}m from route',
              ),
              _MetricChip(
                icon: _autoFollow
                    ? Icons.center_focus_strong_rounded
                    : Icons.explore_rounded,
                label: _autoFollow ? 'Auto-follow' : 'Manual map',
              ),
            ],
          ),
        ],
      ),
    );
  }

  LatLng _initialMapTarget() {
    final requestPosition = widget.startRequest?.initialPosition;
    if (requestPosition != null) {
      return LatLng(requestPosition.latitude, requestPosition.longitude);
    }

    final displayCoordinate = _trackingService.displayCoordinate;
    if (displayCoordinate != null) {
      return displayCoordinate.toLatLng();
    }

    final destination =
        _trackingService.metadata?.destination ??
        widget.startRequest?.metadata.destination;
    if (destination != null) {
      return destination.toLatLng();
    }

    return const LatLng(6.9875, 125.271);
  }

  void _handleTrackingChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});
    _syncUserMarker();
    _syncRouteIfNeeded();
    _showOffRouteWarningIfNeeded();
    _showCompletionPromptIfNeeded();

    if (_autoFollow) {
      _animateCameraToUser();
    }
  }

  Future<void> _syncRouteIfNeeded() async {
    if (_drawnRoute == _trackingService.route) {
      return;
    }

    await _syncMapAnnotations();
  }

  Future<void> _syncMapAnnotations() async {
    final controller = _mapController;
    if (controller == null || !_styleReady) {
      return;
    }

    final oldRouteLine = _routeLine;
    final oldDestination = _destinationCircle;
    final oldCheckpoints = List<Circle>.from(_checkpointCircles);
    _routeLine = null;
    _destinationCircle = null;
    _checkpointCircles.clear();

    if (oldRouteLine != null) {
      await controller.removeLine(oldRouteLine);
    }
    if (oldDestination != null) {
      await controller.removeCircle(oldDestination);
    }
    if (oldCheckpoints.isNotEmpty) {
      await controller.removeCircles(oldCheckpoints);
    }

    final route = _trackingService.route;
    final metadata = _trackingService.metadata ?? widget.startRequest?.metadata;

    if (route != null) {
      _routeLine = await controller.addLine(
        LineOptions(
          geometry: route.coordinates
              .map((coordinate) {
                return coordinate.toLatLng();
              })
              .toList(growable: false),
          lineColor: '#2F80ED',
          lineWidth: 5.0,
          lineOpacity: 0.88,
        ),
      );
      _drawnRoute = route;
    } else {
      _drawnRoute = null;
    }

    if (metadata != null) {
      _destinationCircle = await controller.addCircle(
        CircleOptions(
          geometry: metadata.destination.toLatLng(),
          circleColor: '#D92D20',
          circleRadius: 8.5,
          circleStrokeColor: '#FFFFFF',
          circleStrokeWidth: 2.0,
        ),
      );

      for (final checkpoint in metadata.checkpoints) {
        final circle = await controller.addCircle(
          CircleOptions(
            geometry: checkpoint.coordinate.toLatLng(),
            circleColor: '#F3B33D',
            circleRadius: 6.5,
            circleStrokeColor: '#1E261A',
            circleStrokeWidth: 1.5,
          ),
        );
        _checkpointCircles.add(circle);
      }
    }

    await _syncUserMarker();
  }

  Future<void> _syncUserMarker() async {
    final controller = _mapController;
    final coordinate = _trackingService.displayCoordinate;
    if (controller == null || !_styleReady || coordinate == null) {
      return;
    }

    final geometry = coordinate.toLatLng();
    final userCircle = _userCircle;
    if (userCircle == null) {
      _userCircle = await controller.addCircle(
        CircleOptions(
          geometry: geometry,
          circleColor: '#1D4ED8',
          circleRadius: 8.0,
          circleStrokeColor: '#FFFFFF',
          circleStrokeWidth: 2.5,
        ),
      );
      return;
    }

    await controller.updateCircle(
      userCircle,
      CircleOptions(geometry: geometry),
    );
  }

  Future<void> _animateCameraToUser() async {
    final controller = _mapController;
    final coordinate = _trackingService.displayCoordinate;
    if (controller == null || coordinate == null) {
      return;
    }

    _programmaticCameraMove = true;
    try {
      await controller.animateCamera(
        CameraUpdate.newLatLng(coordinate.toLatLng()),
        duration: const Duration(milliseconds: 500),
      );
    } finally {
      _programmaticCameraMove = false;
    }
  }

  void _recenterOnUser() {
    setState(() {
      _autoFollow = true;
    });
    _animateCameraToUser();
  }

  void _showOffRouteWarningIfNeeded() {
    final version = _trackingService.offRouteWarningVersion;
    if (version == 0 || version == _handledOffRouteWarningVersion) {
      return;
    }

    _handledOffRouteWarningVersion = version;
    HapticFeedback.heavyImpact();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Possible off-route'),
            content: const Text(
              'SummitTrack detected several reliable GPS readings away from the route. Keep the original route visible while the app checks for a valid recalculation.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _trackingService.recalculateRoute();
                },
                child: const Text('Recalculate'),
              ),
            ],
          );
        },
      );
    });
  }

  void _showCompletionPromptIfNeeded() {
    final version = _trackingService.completionPromptVersion;
    if (version == 0 || version == _handledCompletionPromptVersion) {
      return;
    }

    _handledCompletionPromptVersion = version;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Destination reached?'),
            content: const Text(
              'Your GPS has been near the selected destination for several reliable readings. Mark this hike as complete?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Continue'),
              ),
              FilledButton(
                onPressed: () async {
                  final dialogNavigator = Navigator.of(context);
                  await _trackingService.markCompleted();
                  if (!mounted) {
                    return;
                  }
                  dialogNavigator.pop();
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('Hike complete.')),
                  );
                  Navigator.of(this.context).pop();
                },
                child: const Text('Complete'),
              ),
            ],
          );
        },
      );
    });
  }

  Future<bool> _confirmLeaveKeepSession() async {
    if (!_trackingService.hasActiveSession) {
      return true;
    }

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Leave navigation map?'),
          content: const Text(
            'The foreground navigation session will keep running while SummitTrack stays open. You can return to the map from the trail navigation action.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Stay'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Leave'),
            ),
          ],
        );
      },
    );

    return shouldLeave ?? false;
  }

  Future<void> _confirmStopNavigation() async {
    final shouldStop = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('End navigation?'),
          content: const Text(
            'This stops the foreground GPS tracking session for this hike.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('End'),
            ),
          ],
        );
      },
    );

    if (shouldStop != true) {
      return;
    }

    await _trackingService.stop();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  IconData _statusIcon(HikeTrackingStatus status) {
    switch (status) {
      case HikeTrackingStatus.loadingRoute:
      case HikeTrackingStatus.rerouting:
        return Icons.sync_rounded;
      case HikeTrackingStatus.monitoringOffRoute:
        return Icons.visibility_rounded;
      case HikeTrackingStatus.offRoute:
        return Icons.warning_amber_rounded;
      case HikeTrackingStatus.routeUnavailable:
      case HikeTrackingStatus.error:
        return Icons.error_outline_rounded;
      case HikeTrackingStatus.completed:
        return Icons.flag_rounded;
      case HikeTrackingStatus.idle:
      case HikeTrackingStatus.active:
        return Icons.navigation_rounded;
    }
  }

  Color _statusColor(HikeTrackingStatus status) {
    switch (status) {
      case HikeTrackingStatus.offRoute:
      case HikeTrackingStatus.routeUnavailable:
      case HikeTrackingStatus.error:
        return const Color(0xFFF97066);
      case HikeTrackingStatus.monitoringOffRoute:
      case HikeTrackingStatus.loadingRoute:
      case HikeTrackingStatus.rerouting:
        return const Color(0xFFF3B33D);
      case HikeTrackingStatus.completed:
        return const Color(0xFF8DEB6B);
      case HikeTrackingStatus.idle:
      case HikeTrackingStatus.active:
        return const Color(0xFF3FA65B);
    }
  }

  String _statusTitle(HikeTrackingStatus status) {
    switch (status) {
      case HikeTrackingStatus.loadingRoute:
        return 'Loading route';
      case HikeTrackingStatus.rerouting:
        return 'Recalculating';
      case HikeTrackingStatus.monitoringOffRoute:
        return 'Monitoring route';
      case HikeTrackingStatus.offRoute:
        return 'Off-route warning';
      case HikeTrackingStatus.routeUnavailable:
        return 'Route unavailable';
      case HikeTrackingStatus.completed:
        return 'Hike complete';
      case HikeTrackingStatus.error:
        return 'Navigation issue';
      case HikeTrackingStatus.idle:
        return 'Navigation idle';
      case HikeTrackingStatus.active:
        return 'Navigation active';
    }
  }
}

class _RoundMapButton extends StatelessWidget {
  const _RoundMapButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.compact = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 38.0 : 46.0;
    return Material(
      color: const Color(0xFF0B120D).withValues(alpha: 0.88),
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        constraints: BoxConstraints.tight(Size(size, size)),
        padding: EdgeInsets.zero,
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFB8C7B7), size: 15),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

extension on RouteCoordinate {
  LatLng toLatLng() => LatLng(latitude, longitude);
}
