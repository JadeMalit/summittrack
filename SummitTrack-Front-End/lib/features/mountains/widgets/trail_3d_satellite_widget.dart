import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/layout/app_responsive.dart';
import '../../../core/theme/app_colors.dart';

class Trail3DSatelliteWidget extends StatelessWidget {
  final String trailName;
  final List<LatLng> routeCoordinates;
  final double? elevation; // 🏔️ Peak Elevation ng bundok (m ASL)
  final double? distance; // 📏 Totoong Distance ng trail (km)

  const Trail3DSatelliteWidget({
    super.key,
    required this.trailName,
    required this.routeCoordinates,
    this.elevation,
    this.distance,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final LatLng centerPoint = routeCoordinates.isNotEmpty
        ? routeCoordinates[routeCoordinates.length ~/ 2]
        : const LatLng(7.0298, 125.2872);

    return LayoutBuilder(
      builder: (context, constraints) {
        final mapHeight = AppResponsive.clampedWidthHeight(
          constraints.maxWidth,
          ratio: 0.86,
          min: 260,
          max: 360,
        );

        return Container(
          height: mapHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: context.isDarkMode
                  ? colors.border
                  : const Color(0xFFC7C0B3),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                // 🛰️ ESRI WORLD SATELLITE MAP CANVAS
                FlutterMap(
                  options: MapOptions(
                    initialCenter: centerPoint,
                    initialZoom: 13.5,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                      userAgentPackageName: 'com.summittrack.app',
                      maxZoom: 19,
                    ),

                    // 🟧 NEON TRAIL POLYLINE
                    if (routeCoordinates.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: routeCoordinates,
                            strokeWidth: 9.0,
                            color: const Color(
                              0xFFFF5500,
                            ).withValues(alpha: 0.45),
                          ),
                          Polyline(
                            points: routeCoordinates,
                            strokeWidth: 4.5,
                            color: const Color(0xFFFF3300),
                            borderStrokeWidth: 1.2,
                            borderColor: Colors.white70,
                          ),
                        ],
                      ),

                    // 📍 START & FINISH MARKERS
                    if (routeCoordinates.isNotEmpty)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: routeCoordinates.first,
                            width: 30,
                            height: 30,
                            child: const Icon(
                              Icons.play_circle_fill_rounded,
                              color: Color(0xFF22C55E),
                              size: 30,
                            ),
                          ),
                          Marker(
                            point: routeCoordinates.last,
                            width: 30,
                            height: 30,
                            child: const Icon(
                              Icons.flag_circle_rounded,
                              color: Color(0xFFEF4444),
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),

                // 🎯 FLOATING HUD OVERLAY (REAL ELEVATION & DISTANCE ONLY)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.85),
                          Colors.black.withValues(alpha: 0.40),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          trailName.toUpperCase(),
                          style: GoogleFonts.fredoka(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                            letterSpacing: 1.2,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildHudStat(
                              label: 'Max Elevation',
                              value: elevation != null && elevation! > 0
                                  ? elevation!.toInt().toString()
                                  : '---',
                              unit: 'm ASL',
                            ),
                            _buildHudStat(
                              label: 'Trail Distance',
                              value: distance != null && distance! > 0
                                  ? distance!.toStringAsFixed(1)
                                  : '---',
                              unit: 'km',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // 📌 BOTTOM OVERLAY BADGE
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.70),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.satellite_alt_rounded,
                          color: Color(0xFFFF5500),
                          size: 14,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'HD SATELLITE TERRAIN',
                          style: GoogleFonts.fredoka(
                            fontSize: 9.5,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHudStat({
    required String label,
    required String value,
    required String unit,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.fredoka(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1.1,
          ),
        ),
        Text(
          unit,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFFF7043),
          ),
        ),
      ],
    );
  }
}
