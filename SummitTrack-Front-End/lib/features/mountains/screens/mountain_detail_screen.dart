import 'package:flutter/material.dart';

import '../../../core/layout/app_responsive.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/state/app_mode_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/trail_data/mountain.dart';
import 'mt_apo.dart';

class MountainDetailScreen extends StatelessWidget {
  final Mountain mountain;

  const MountainDetailScreen({super.key, required this.mountain});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isOfflineMode = AppModeProvider.instance.isOfflineMode;
    final elevationText = mountain.hasSpecifiedElevation
        ? '${mountain.elevation} meters'
        : mountain.elevationLabel;

    if (mountain.name == 'Mt. Apo') {
      return const MtApoScreen();
    }

    return Scaffold(
      appBar: AppBar(title: Text(mountain.name)),
      backgroundColor: colors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER IMAGE
            LayoutBuilder(
              builder: (context, constraints) {
                final headerHeight = AppResponsive.clampedWidthHeight(
                  constraints.maxWidth,
                  ratio: 0.58,
                  min: 180,
                  max: 240,
                );

                return SizedBox(
                  height: headerHeight,
                  width: double.infinity,
                  child: mountain.imageAsset == null
                      ? _MountainHeaderPlaceholder(colors: colors)
                      : Image.asset(mountain.imageAsset!, fit: BoxFit.cover),
                );
              },
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// NAME
                  Text(
                    mountain.name,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  /// BASIC INFO
                  Text("Region: ${mountain.region}"),
                  Text("Location: ${mountain.location}"),
                  Text("Elevation: $elevationText"),
                  Text("Slope: ${mountain.slope}"),

                  const SizedBox(height: 20),

                  /// DESCRIPTION
                  Text(
                    "Description",
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(mountain.description),

                  const SizedBox(height: 30),

                  /// TRAILS
                  Text(
                    "Trails",
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (!mountain.hasTrails)
                    const _NoTrailDetailsNotice()
                  else
                    for (final trail in mountain.trails) ...[
                      ElevatedButton.icon(
                        icon: const Icon(Icons.hiking),
                        label: Text(trail),
                        onPressed: () => _openTrail(context, mountain, trail),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                  const SizedBox(height: 20),

                  if (isOfflineMode)
                    const _OfflineMountainDetailNotice()
                  else ...[
                    /// ACTION BUTTONS
                    ElevatedButton.icon(
                      icon: const Icon(Icons.camera_alt),
                      label: const Text("Upload Photo"),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Photo upload soon")),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),

                    const SizedBox(height: 15),

                    ElevatedButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text("Write Reflection"),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Reflection soon")),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.warning,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openTrail(BuildContext context, Mountain mountain, String trail) {
    if (mountain.name == 'Mt. Apo' && trail == 'Sta. Cruz / Sibulan Trail') {
      Navigator.of(context).pushNamed(
        AppRoutes.trail(AppRoutes.mtApoMountainId, AppRoutes.staCruzTrailId),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$trail details will be added soon.')),
    );
  }
}

class _MountainHeaderPlaceholder extends StatelessWidget {
  const _MountainHeaderPlaceholder({required this.colors});

  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: colors.surfaceMuted,
      child: Icon(Icons.terrain_rounded, size: 96, color: colors.accent),
    );
  }
}

class _NoTrailDetailsNotice extends StatelessWidget {
  const _NoTrailDetailsNotice();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.route_rounded, color: colors.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trail details coming soon',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Trail details for this mountain are not available yet. This mountain has been added and trail information will be updated soon.',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 13.5,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OfflineMountainDetailNotice extends StatelessWidget {
  const _OfflineMountainDetailNotice();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.offline_bolt_rounded, color: colors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Account features are available when you are online.',
              style: TextStyle(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
