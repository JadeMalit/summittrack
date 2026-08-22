import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/hike_navigation_metadata.dart';
import '../../models/hike_navigation_start_request.dart';
import '../../services/location/location_service.dart';
import '../../services/routing/trailhead_proximity_guard.dart';
import '../../services/weather_service.dart';

Future<HikeNavigationStartRequest?> showHikeNavigationConfirmation({
  required BuildContext context,
  required HikeNavigationMetadata metadata,
}) {
  return showDialog<HikeNavigationStartRequest>(
    context: context,
    barrierDismissible: true,
    builder: (_) => HikeNavigationConfirmationDialog(metadata: metadata),
  );
}

class HikeNavigationConfirmationDialog extends StatefulWidget {
  const HikeNavigationConfirmationDialog({super.key, required this.metadata});

  final HikeNavigationMetadata metadata;

  @override
  State<HikeNavigationConfirmationDialog> createState() =>
      _HikeNavigationConfirmationDialogState();
}

class _HikeNavigationConfirmationDialogState
    extends State<HikeNavigationConfirmationDialog> {
  static const _panelColor = Color(0xFF0B120D);
  static const _cardColor = Color(0xFF121C14);
  static const _accentColor = Color(0xFF3FA65B);
  static const _warningColor = Color(0xFFF3B33D);
  static const _mutedTextColor = Color(0xFFB8C7B7);

  final LocationService _locationService = const LocationService();
  final WeatherService _weatherService = WeatherService();

  LocationReadiness? _readiness;
  TrailheadProximityResult? _trailheadProximity;
  bool _checkingGps = true;
  bool _loadingWeather = true;
  bool _useDebugTrailheadStart = true;
  String? _weatherSummary;

  @override
  void initState() {
    super.initState();
    _refreshGpsReadiness();
    _loadWeatherPreview();
  }

  Future<void> _refreshGpsReadiness() async {
    setState(() {
      _checkingGps = true;
    });

    final readiness = await _locationService.requestNavigationReadiness();
    final position = readiness.position;
    final trailheadProximity = position == null
        ? null
        : TrailheadProximityGuard.evaluate(
            metadata: widget.metadata,
            currentLocation: _locationService.coordinateFromPosition(position),
          );
    if (!mounted) {
      return;
    }

    setState(() {
      _readiness = readiness;
      _trailheadProximity = trailheadProximity;
      _checkingGps = false;
    });
  }

  Future<void> _loadWeatherPreview() async {
    try {
      final data = await _weatherService.getWeather(
        _weatherLookupName(widget.metadata.trailName),
      );
      final current = data['current'] as Map<String, dynamic>?;
      final condition = current?['condition'] as Map<String, dynamic>?;
      final text = condition?['text']?.toString();
      final temp = current?['temp_c'];

      if (!mounted) {
        return;
      }

      setState(() {
        if (text != null && temp != null) {
          _weatherSummary = '$text, ${temp.toString()}°C';
        } else {
          _weatherSummary = 'Weather preview unavailable';
        }
        _loadingWeather = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _weatherSummary = 'Weather preview unavailable';
        _loadingWeather = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final readiness = _readiness;
    final canUseDebugStart =
        _debugTrailheadStartAvailable && _useDebugTrailheadStart;
    final canUseGpsStart =
        readiness?.isReady == true && (_trailheadProximity?.canStart ?? true);
    final canStart = !_checkingGps && (canUseGpsStart || canUseDebugStart);
    final size = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 430,
          maxHeight: size.height * 0.88,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: _panelColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 28,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildRouteSummary(),
                  const SizedBox(height: 12),
                  _StatusCard(
                    icon: Icons.gps_fixed_rounded,
                    title: 'GPS readiness',
                    value: _checkingGps
                        ? 'Checking location signal...'
                        : readiness?.message ?? 'Unable to check GPS.',
                    color: readiness?.isReady == true
                        ? _accentColor
                        : _warningColor,
                    trailing: _checkingGps
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            tooltip: 'Retry GPS check',
                            onPressed: _refreshGpsReadiness,
                            icon: const Icon(Icons.refresh_rounded),
                            color: Colors.white,
                          ),
                  ),
                  const SizedBox(height: 12),
                  if (widget.metadata.trailhead != null) ...[
                    _StatusCard(
                      icon: Icons.place_rounded,
                      title: 'Trailhead proximity',
                      value: _trailheadProximityMessage,
                      color: _trailheadProximityColor,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_debugTrailheadStartAvailable) ...[
                    _StatusCard(
                      icon: Icons.bug_report_rounded,
                      title: 'Debug start',
                      value:
                          'Simulated start at ${widget.metadata.trailheadName ?? 'selected trailhead'}.',
                      color: _warningColor,
                      trailing: Switch(
                        value: _useDebugTrailheadStart,
                        activeColor: _accentColor,
                        onChanged: (value) {
                          setState(() {
                            _useDebugTrailheadStart = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  _StatusCard(
                    icon: Icons.cloud_queue_rounded,
                    title: 'Route and map data',
                    value:
                        'Internet is required to load the GraphHopper route and map tiles before navigation starts.',
                    color: _accentColor,
                  ),
                  const SizedBox(height: 12),
                  _StatusCard(
                    icon: Icons.wb_cloudy_rounded,
                    title: 'Weather preview',
                    value: _loadingWeather
                        ? 'Checking latest trail weather...'
                        : _weatherSummary ?? 'Weather preview unavailable',
                    color: _accentColor,
                  ),
                  if (widget.metadata.validationNote != null) ...[
                    const SizedBox(height: 12),
                    _StatusCard(
                      icon: Icons.info_outline_rounded,
                      title: 'Pilot note',
                      value: widget.metadata.validationNote!,
                      color: _warningColor,
                    ),
                  ],
                  const SizedBox(height: 18),
                  _buildActions(canStart),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Start navigation',
                style: GoogleFonts.fredoka(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.metadata.trailName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  color: _mutedTextColor,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded, color: Colors.white70),
          tooltip: 'Close',
        ),
      ],
    );
  }

  Widget _buildRouteSummary() {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.metadata.destinationName,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Destination: ${widget.metadata.destination.latitude.toStringAsFixed(4)}, ${widget.metadata.destination.longitude.toStringAsFixed(4)}',
            style: GoogleFonts.poppins(
              color: _mutedTextColor,
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(bool canStart) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: canStart ? _startNavigation : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.white.withValues(alpha: 0.12),
              disabledForegroundColor: Colors.white.withValues(alpha: 0.36),
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'Start',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }

  void _startNavigation() {
    if (_useDebugTrailheadStart) {
      Position? debugPosition;
      try {
        debugPosition = DebugTrailheadStartSimulator.simulatedPositionFor(
          metadata: widget.metadata,
        );
      } catch (_) {
        debugPosition = null;
      }

      if (debugPosition == null) {
        final fallbackCoord =
            widget.metadata.trailhead ?? widget.metadata.destination;
        debugPosition = Position(
          latitude: fallbackCoord.latitude,
          longitude: fallbackCoord.longitude,
          timestamp: DateTime.now(),
          accuracy: 5.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );
      }

      Navigator.of(context).pop(
        HikeNavigationStartRequest(
          metadata: widget.metadata,
          initialPosition: debugPosition,
        ),
      );
      return;
    }

    final position = _readiness?.position;
    if (position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Waiting for GPS signal...')),
      );
      return;
    }

    final proximity = TrailheadProximityGuard.evaluate(
      metadata: widget.metadata,
      currentLocation: _locationService.coordinateFromPosition(position),
    );
    if (!proximity.canStart) {
      setState(() {
        _trailheadProximity = proximity;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            proximity.message ?? 'You are too far from the trailhead.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.of(context).pop(
      HikeNavigationStartRequest(
        metadata: widget.metadata,
        initialPosition: position,
      ),
    );
  }

  static String _weatherLookupName(String trailName) {
    final normalizedTrailName = trailName.toLowerCase();
    if (normalizedTrailName.contains('apo') ||
        normalizedTrailName.contains('sta. cruz') ||
        normalizedTrailName.contains('sibulan')) {
      return 'Mount Apo';
    }

    if (trailName.startsWith('Mt. ')) {
      return trailName.replaceFirst('Mt. ', 'Mount ');
    }

    return trailName;
  }

  bool get _debugTrailheadStartAvailable => true;

  String get _trailheadProximityMessage {
    if (_debugTrailheadStartAvailable && _useDebugTrailheadStart) {
      return 'Using simulated start at ${widget.metadata.trailheadName ?? 'selected trailhead'}.';
    }

    if (_checkingGps) {
      return 'Checking distance to ${widget.metadata.trailheadName ?? 'the selected trailhead'}...';
    }

    return _trailheadProximity?.message ??
        'Trailhead coordinate unavailable for this route.';
  }

  Color get _trailheadProximityColor {
    if (_debugTrailheadStartAvailable && _useDebugTrailheadStart) {
      return _accentColor;
    }

    return (_trailheadProximity?.canStart ?? true)
        ? _accentColor
        : _warningColor;
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _HikeNavigationConfirmationDialogState._cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    color:
                        _HikeNavigationConfirmationDialogState._mutedTextColor,
                    fontSize: 12.2,
                    height: 1.38,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}