import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/layout/app_responsive.dart';
import '../../../core/theme/app_colors.dart';

class TrailWaypoint {
  final String name;
  final double elevation; // meters (m ASL)
  final double distance; // kilometers (km)
  final double slope; // steepness percentage (%)
  final Color color;

  const TrailWaypoint({
    required this.name,
    required this.elevation,
    required this.distance,
    required this.slope,
    required this.color,
  });
}

class ElevationGradientMap3D extends StatefulWidget {
  final String trailTitle;
  final List<TrailWaypoint> waypoints;

  const ElevationGradientMap3D({
    super.key,
    required this.trailTitle,
    required this.waypoints,
  });

  @override
  State<ElevationGradientMap3D> createState() => _ElevationGradientMap3DState();
}

class _ElevationGradientMap3DState extends State<ElevationGradientMap3D> {
  double? _touchX;
  TrailWaypoint? _selectedWaypoint;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final compact = AppResponsive.isCompactWidth(context);

    return Container(
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? colors.surfaceHigh
            : Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: context.isDarkMode ? colors.border : const Color(0xFFC7C0B3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.trailTitle} Terrain Profile',
                      style: GoogleFonts.fredoka(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Interactive 3D Topographic Elevation & Slope Model',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: colors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colors.accent.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  '3D GIS MAP',
                  style: GoogleFonts.fredoka(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: colors.accent,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (widget.waypoints.isEmpty)
            Container(
              height: compact ? 130 : 150,
              alignment: Alignment.center,
              child: Text(
                'Elevation gradient data coming soon for this trail.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: colors.textSecondary,
                ),
              ),
            )
          else ...[
            // 3D Canvas Topo Map Area
            GestureDetector(
              onPanUpdate: (details) {
                setState(() => _touchX = details.localPosition.dx);
              },
              onPanDown: (details) {
                setState(() => _touchX = details.localPosition.dx);
              },
              onPanEnd: (_) {
                setState(() {
                  _touchX = null;
                  _selectedWaypoint = null;
                });
              },
              child: SizedBox(
                height: compact ? 178 : 210,
                width: double.infinity,
                child: CustomPaint(
                  painter: _TopographicTerrain3DPainter(
                    waypoints: widget.waypoints,
                    touchX: _touchX,
                    isDarkMode: context.isDarkMode,
                    onHoverWaypoint: (wp) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_selectedWaypoint != wp && mounted) {
                          setState(() => _selectedWaypoint = wp);
                        }
                      });
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Live Altitude & Segment Inspector Box (Overflow Safe)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: context.isDarkMode
                    ? colors.surface
                    : const Color(0xFFF2EFE9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _selectedWaypoint != null
                      ? _getSlopeColor(_selectedWaypoint!.slope)
                      : (context.isDarkMode
                            ? colors.border
                            : const Color(0xFFD0C8BC)),
                  width: 1.5,
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final useStackedStats = constraints.maxWidth < 330;
                  final landmark = _buildStatItem(
                    context,
                    label: 'Landmark Segment',
                    value: _selectedWaypoint?.name ?? 'Drag across profile',
                    icon: Icons.place_rounded,
                    color: _selectedWaypoint != null
                        ? _getSlopeColor(_selectedWaypoint!.slope)
                        : colors.textPrimary,
                  );
                  final altitude = _buildStatItem(
                    context,
                    label: 'Altitude',
                    value: _selectedWaypoint != null
                        ? '${_selectedWaypoint!.elevation.toInt()} m ASL'
                        : '-- m',
                    icon: Icons.terrain_rounded,
                    color: colors.textPrimary,
                  );
                  final slope = _buildStatItem(
                    context,
                    label: 'Grade / Slope',
                    value: _selectedWaypoint != null
                        ? '${_selectedWaypoint!.slope.toInt()}%'
                        : '-- %',
                    icon: Icons.trending_up_rounded,
                    color: _selectedWaypoint != null
                        ? _getSlopeColor(_selectedWaypoint!.slope)
                        : colors.textPrimary,
                  );

                  if (useStackedStats) {
                    return Column(
                      children: [
                        landmark,
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: altitude),
                            const SizedBox(width: 8),
                            Expanded(child: slope),
                          ],
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(flex: 4, child: landmark),
                      const SizedBox(width: 4),
                      Expanded(flex: 3, child: altitude),
                      const SizedBox(width: 4),
                      Expanded(flex: 3, child: slope),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 14),

            // Waypoint Badges Legend
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.waypoints.map((wp) {
                final badgeColor = _getSlopeColor(wp.slope);
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: badgeColor.withValues(alpha: 0.8),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: badgeColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${wp.name} (${wp.elevation.toInt()}m)',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final colors = context.appColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  color: colors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                value,
                style: GoogleFonts.fredoka(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Helper Function: Dynamic Color Matching Based on Actual Slope %
Color _getSlopeColor(double slope) {
  if (slope < 12.0) {
    return const Color(0xFF4CAF50); // Chill / Green
  } else if (slope < 22.0) {
    return const Color(0xFFFFB300); // Moderate / Yellow
  } else if (slope < 32.0) {
    return const Color(0xFFFF7043); // Steep / Orange
  } else {
    return const Color(0xFFE53935); // Very Steep / Red
  }
}

/// 🎨 PRO-GIS TOPOGRAPHIC 3D CANVAS PAINTER
class _TopographicTerrain3DPainter extends CustomPainter {
  final List<TrailWaypoint> waypoints;
  final double? touchX;
  final bool isDarkMode;
  final ValueChanged<TrailWaypoint?> onHoverWaypoint;

  _TopographicTerrain3DPainter({
    required this.waypoints,
    required this.touchX,
    required this.isDarkMode,
    required this.onHoverWaypoint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (waypoints.isEmpty) return;

    const double leftPadding = 40.0;
    const double bottomPadding = 20.0;
    const double rightPadding = 12.0;
    const double topPadding = 20.0;

    final double chartWidth = size.width - leftPadding - rightPadding;
    final double chartHeight = size.height - topPadding - bottomPadding;

    final double minElev = waypoints.map((w) => w.elevation).reduce(math.min);
    final double maxElev = waypoints.map((w) => w.elevation).reduce(math.max);
    final double minDist = waypoints.first.distance;
    final double maxDist = waypoints.last.distance;

    final double distRange = (maxDist - minDist) == 0
        ? 1.0
        : (maxDist - minDist);
    final double elevRange = (maxElev - minElev) == 0
        ? 1.0
        : (maxElev - minElev);

    // 1. DRAW Y-AXIS ELEVATION GRID & LABELS
    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    final Paint gridLinePaint = Paint()
      ..color = (isDarkMode ? Colors.white12 : Colors.black12)
      ..strokeWidth = 0.8;

    const int yDivisions = 4;
    for (int i = 0; i <= yDivisions; i++) {
      final double yRatio = i / yDivisions;
      final double y = topPadding + (chartHeight * (1 - yRatio));
      final double elevVal = minElev + (elevRange * yRatio);

      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width - rightPadding, y),
        gridLinePaint,
      );

      textPainter.text = TextSpan(
        text: '${elevVal.toInt()}m',
        style: GoogleFonts.poppins(
          fontSize: 8.5,
          fontWeight: FontWeight.w500,
          color: isDarkMode ? Colors.white54 : const Color(0xFF7A7265),
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          leftPadding - textPainter.width - 5,
          y - (textPainter.height / 2),
        ),
      );
    }

    // 2. DRAW X-AXIS DISTANCE LABELS
    for (int i = 0; i < waypoints.length; i++) {
      final wp = waypoints[i];
      final double xRatio = (wp.distance - minDist) / distRange;
      final double x = leftPadding + (xRatio * chartWidth);

      textPainter.text = TextSpan(
        text: '${wp.distance.toStringAsFixed(1)}km',
        style: GoogleFonts.poppins(
          fontSize: 8.5,
          color: isDarkMode ? Colors.white38 : const Color(0xFF8C8476),
        ),
      );
      textPainter.layout();

      double labelX = x - (textPainter.width / 2);
      if (labelX + textPainter.width > size.width) {
        labelX = size.width - textPainter.width;
      }
      if (labelX < leftPadding) {
        labelX = leftPadding;
      }

      textPainter.paint(
        canvas,
        Offset(labelX, size.height - bottomPadding + 3),
      );
    }

    // 3. GENERATE WAYPOINT POINTS
    final List<Offset> waypointPoints = [];
    final List<Offset> detailedTerrainPoints = [];

    for (int i = 0; i < waypoints.length; i++) {
      final wp = waypoints[i];
      final double xRatio = (wp.distance - minDist) / distRange;
      final double yRatio = (wp.elevation - minElev) / elevRange;

      final double x = leftPadding + (xRatio * chartWidth);
      final double y = topPadding + (chartHeight * (1 - yRatio));
      waypointPoints.add(Offset(x, y));
    }

    // Micro-Terrain Bumps Calculation
    for (int i = 0; i < waypointPoints.length - 1; i++) {
      final p0 = waypointPoints[i];
      final p1 = waypointPoints[i + 1];
      const int steps = 10;

      for (int step = 0; step < steps; step++) {
        final double t = step / steps;
        final double currentX = p0.dx + (p1.dx - p0.dx) * t;
        double currentY = p0.dy + (p1.dy - p0.dy) * t;

        if (step > 0 && step < steps) {
          final double sineBump =
              math.sin(t * math.pi * 2) * 2.5 * (i % 2 == 0 ? 1 : -1);
          currentY += sineBump;
        }

        detailedTerrainPoints.add(Offset(currentX, currentY));
      }
    }
    detailedTerrainPoints.add(waypointPoints.last);

    // 4. VERTICAL ALTITUDE MESH LINES
    final Paint meshLinePaint = Paint()
      ..color = (isDarkMode
          ? Colors.white10
          : Colors.black.withValues(alpha: 0.05))
      ..strokeWidth = 1.0;

    for (int i = 0; i < detailedTerrainPoints.length; i += 3) {
      final pt = detailedTerrainPoints[i];
      canvas.drawLine(
        Offset(pt.dx, pt.dy),
        Offset(pt.dx, size.height - bottomPadding),
        meshLinePaint,
      );
    }

    // 5. VOLUMETRIC TERRAIN AREA FILL (DYNAMIC BASED ON MAX TRAIL SLOPE)
    final Path fullPath = Path();
    fullPath.moveTo(
      detailedTerrainPoints.first.dx,
      detailedTerrainPoints.first.dy,
    );
    for (int i = 0; i < detailedTerrainPoints.length - 1; i++) {
      final p0 = detailedTerrainPoints[i];
      final p1 = detailedTerrainPoints[i + 1];
      final controlX = (p0.dx + p1.dx) / 2;
      fullPath.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
    }

    final Path fillPath = Path.from(fullPath);
    fillPath.lineTo(waypointPoints.last.dx, size.height - bottomPadding);
    fillPath.lineTo(waypointPoints.first.dx, size.height - bottomPadding);
    fillPath.close();

    final double maxSlope = waypoints.map((w) => w.slope).reduce(math.max);
    final Color topFillColor = _getSlopeColor(maxSlope).withValues(alpha: 0.30);

    final Paint volumetricFill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [topFillColor, const Color(0xFF4CAF50).withValues(alpha: 0.03)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, volumetricFill);

    // 6. DYNAMIC TRAIL SEGMENTS (SLOPE-BASED COLORING)
    for (int i = 0; i < waypointPoints.length - 1; i++) {
      final p0 = waypointPoints[i];
      final p1 = waypointPoints[i + 1];
      final targetWaypoint = waypoints[i + 1];

      // Kinukuha ang tunay na slope percentage ng partikular na segment na ito
      final Color segmentColor = _getSlopeColor(targetWaypoint.slope);

      final Path segPath = Path();
      segPath.moveTo(p0.dx, p0.dy);
      final controlX = (p0.dx + p1.dx) / 2;
      segPath.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);

      // Segment Drop Shadow
      canvas.drawPath(
        segPath.shift(const Offset(0, 3)),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0),
      );

      // Segment Ribbon Stroke
      canvas.drawPath(
        segPath,
        Paint()
          ..color = segmentColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.5
          ..strokeCap = StrokeCap.round,
      );
    }

    // 7. WAYPOINT PINS & TOUCH INSPECTION CURSOR
    TrailWaypoint? hoveredWp;
    double closestDist = double.infinity;

    final double clampedTouchX = touchX != null
        ? touchX!.clamp(leftPadding, size.width - rightPadding)
        : -1;

    for (int i = 0; i < waypointPoints.length; i++) {
      final p = waypointPoints[i];
      final wp = waypoints[i];
      final pinColor = _getSlopeColor(wp.slope);

      canvas.drawLine(
        Offset(p.dx, p.dy),
        Offset(p.dx, size.height - bottomPadding),
        Paint()
          ..color = pinColor.withValues(alpha: 0.30)
          ..strokeWidth = 1.0,
      );

      canvas.drawCircle(
        p,
        6.5,
        Paint()..color = pinColor.withValues(alpha: 0.22),
      );
      canvas.drawCircle(p, 4.0, Paint()..color = pinColor);
      canvas.drawCircle(p, 1.8, Paint()..color = Colors.white);

      if (touchX != null) {
        final dist = (clampedTouchX - p.dx).abs();
        if (dist < closestDist) {
          closestDist = dist;
          hoveredWp = wp;
        }
      }
    }

    if (touchX != null && hoveredWp != null) {
      onHoverWaypoint(hoveredWp);

      final Color activeColor = _getSlopeColor(hoveredWp.slope);
      final Paint touchCursorPaint = Paint()
        ..color = activeColor
        ..strokeWidth = 1.6;

      canvas.drawLine(
        Offset(clampedTouchX, topPadding),
        Offset(clampedTouchX, size.height - bottomPadding),
        touchCursorPaint,
      );

      canvas.drawCircle(
        Offset(clampedTouchX, topPadding),
        3.5,
        Paint()..color = activeColor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TopographicTerrain3DPainter oldDelegate) {
    return oldDelegate.touchX != touchX || oldDelegate.isDarkMode != isDarkMode;
  }
}
