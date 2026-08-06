import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/state/app_mode_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/navigation/navigation_trails.dart';
import '../../../data/trail_data/trail_data.dart';
import '../../../data/trail_data/trail_gps_helper.dart';
import '../../../data/trail_data/trail_waypoint_helper.dart';
import '../../../models/hike_navigation_metadata.dart';
import '../../../screens/navigation/hike_navigation_confirmation.dart';
import '../../../services/tracking/hike_tracking_service.dart';
import '../../hike/models/scheduled_hike.dart';
import '../../hike/screens/hike.dart'; // 🟢 ADDED: Import para sa HikeScreen
import '../../hike/screens/lets_hike_calendar_weather_modal.dart';
import '../../hike/services/hike_schedule_store.dart';
import '../../hike/utils/mountain_schedule_identity.dart';
import '../../notifications/services/hike_notification_service.dart';
import '../widgets/elevation_gradient_map_3d.dart';
import '../widgets/first_aid_emergency_tips.dart';
import '../widgets/foldable_trail_checklist_card.dart';
import '../widgets/trail_3d_satellite_widget.dart';
import '../widgets/trail_photo_uploader.dart';

@visibleForTesting
String hikeScheduledNotificationConfirmationMessage({
  required DateTime hikeDate,
  required HikeReminderDeliveryState deliveryState,
  DateTime? now,
}) {
  return switch (deliveryState) {
    HikeReminderDeliveryState.enabled =>
      _isSameManilaDate(hikeDate, now)
          ? 'Notifications are turned on. You will receive a reminder for your '
                'hike today.'
          : 'Notifications are turned on. You will receive a reminder on the '
                'scheduled date.',
    HikeReminderDeliveryState.disabled =>
      'Turn on Notifications in Settings to receive a hike reminder.',
    HikeReminderDeliveryState.unknown =>
      'Your hike was saved, but the notification status could not be '
          'confirmed.',
  };
}

bool _isSameManilaDate(DateTime hikeDate, DateTime? now) {
  final hikeDateKey = ScheduledHike.dateKey(hikeDate);
  final todayKey = ScheduledHike.dateKey(
    ScheduledHike.manilaDateForInstant(now ?? DateTime.now()),
  );
  return hikeDateKey == todayKey;
}

class TrailDetailScreen extends StatelessWidget {
  const TrailDetailScreen({
    super.key,
    required this.trail,
    required this.parentRoute,
    this.trailPhotoId = 'sta_cruz_sibulan',
    this.navigationTrailId,
  });

  final TrailData trail;
  final String parentRoute;
  final String trailPhotoId;
  final String? navigationTrailId;

  static const _backgroundColor = Color(0xFFE3DDCF);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final isOfflineMode = AppModeProvider.instance.isOfflineMode;
    final mountainId = MountainScheduleIdentity.idFromRoute(parentRoute);
    final mountainName = MountainScheduleIdentity.displayNameForMountainId(
      mountainId,
    );
    final navigationMetadata = NavigationTrails.forTrailId(
      navigationTrailId ?? trailPhotoId,
    );

    // 🏔️ Kinukuha ang totoong Peak Elevation at Total Distance ng bundok mula sa waypoints
    final waypoints = TrailWaypointHelper.getWaypointsForTrail(
      trail,
      trailPhotoId,
    );
    final maxElevation = waypoints.isNotEmpty
        ? waypoints.map((w) => w.elevation).reduce((a, b) => a > b ? a : b)
        : null;
    final totalDistance = waypoints.isNotEmpty ? waypoints.last.distance : null;

    return Scaffold(
      backgroundColor: context.isDarkMode
          ? colors.background
          : _backgroundColor,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TrailBanner(
                trail: trail,
                onBack: () async {
                  final navigator = Navigator.of(context);
                  final didHandlePop = await navigator.maybePop();
                  if (didHandlePop || !context.mounted) {
                    return;
                  }

                  navigator.pushReplacementNamed(parentRoute);
                },
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DetailCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _DetailSection(
                            label: 'Trail Name',
                            value: trail.name,
                          ),
                          const SizedBox(height: 12),
                          _DetailSection(
                            label: 'Location',
                            value: trail.location,
                          ),
                          const SizedBox(height: 12),
                          _DetailSection(
                            label: 'Description',
                            value: trail.description,
                          ),
                          const SizedBox(height: 12),
                          _DetailSection(
                            label: 'Slope / Difficulty',
                            value: trail.slopeDifficulty,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    FoldableTrailChecklistCard(trail: trail),
                    if (trail.safetyReminders.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      const _SectionHeading(title: 'Safety Reminders'),
                      const SizedBox(height: 10),
                      _SafetyReminderCard(reminders: trail.safetyReminders),
                    ],
                    const SizedBox(height: 18),
                    const _SectionHeading(title: 'First Aid / Emergency Tips'),
                    const SizedBox(height: 10),
                    const FirstAidEmergencyTips(),

                    // 🛰️ 1. STRAVA-STYLE HD SATELLITE TERRAIN MAP
                    const SizedBox(height: 18),
                    const _SectionHeading(title: 'Trail Map'),
                    const SizedBox(height: 10),
                    Trail3DSatelliteWidget(
                      trailName: trail.name,
                      routeCoordinates: TrailGpsHelper.getGpsRouteForTrail(
                        trail,
                        trailPhotoId,
                      ),
                      elevation: maxElevation,
                      distance: totalDistance, // 👈 TOTOONG DISTANCE NG BUNDOK
                    ),

                    // ⛰️ 2. 3D ELEVATION & SLOPE PROFILE
                    const SizedBox(height: 18),
                    const _SectionHeading(title: 'Gradient Map'),
                    const SizedBox(height: 10),
                    ElevationGradientMap3D(
                      trailTitle: trail.name,
                      waypoints: waypoints,
                    ),

                    if (isOfflineMode) ...[
                      const SizedBox(height: 18),
                      const _SectionHeading(title: 'Offline Access'),
                      const SizedBox(height: 10),
                      const _OfflineTrailAccessCard(),
                    ] else ...[
                      if (navigationMetadata?.isNavigationEnabled == true) ...[
                        const SizedBox(height: 18),
                        const _SectionHeading(title: 'Navigation'),
                        const SizedBox(height: 10),
                        _StartNavigationButton(metadata: navigationMetadata!),
                        const SizedBox(height: 10),
                        const _ViewLiveHikeDashboardButton(), // 🟢 ADDED: Live Hike Dashboard Button
                      ],
                      const SizedBox(height: 18),
                      const _SectionHeading(title: 'Add Photo or Video'),
                      const SizedBox(height: 10),
                      TrailPhotoUploader(trailId: trailPhotoId),
                      const SizedBox(height: 22),
                      _LetsHikeButton(
                        mountainId: mountainId,
                        mountainName: mountainName,
                        trailId: trailPhotoId,
                        trailName: trail.name,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _handleStartNavigation(
  BuildContext context,
  HikeNavigationMetadata metadata,
) async {
  if (HikeTrackingService.instance.hasActiveSession) {
    Navigator.of(context).pushNamed(AppRoutes.hikeNavigation);
    return;
  }

  final startRequest = await showHikeNavigationConfirmation(
    context: context,
    metadata: metadata,
  );

  if (startRequest == null || !context.mounted) {
    return;
  }

  Navigator.of(
    context,
  ).pushNamed(AppRoutes.hikeNavigation, arguments: startRequest);
}

/// 🟢 BAGONG WIDGET: Button para pumunta sa Live Hike Dashboard
class _ViewLiveHikeDashboardButton extends StatelessWidget {
  const _ViewLiveHikeDashboardButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: Color(0xFF3FA65B), width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const Icon(Icons.hiking_rounded, color: Color(0xFF3FA65B)),
        label: Text(
          'View Live Hike Dashboard',
          style: GoogleFonts.fredoka(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: context.isDarkMode ? Colors.white : const Color(0xFF1E261A),
          ),
        ),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const HikeScreen(),
            ),
          );
        },
      ),
    );
  }
}

class _OfflineTrailAccessCard extends StatelessWidget {
  const _OfflineTrailAccessCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.isDarkMode ? colors.surface : const Color(0xFFF5F1E8),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: context.isDarkMode ? colors.border : const Color(0xFFC9C1B1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.offline_bolt_rounded, color: colors.accent, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Photo uploads and hike planning are available when you are online.',
              style: GoogleFonts.poppins(
                color: colors.textSecondary,
                fontSize: 13.5,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.fredoka(
        fontSize: 19,
        fontWeight: FontWeight.w600,
        color: context.appColors.textPrimary,
      ),
    );
  }
}

class _TrailBanner extends StatelessWidget {
  const _TrailBanner({required this.trail, required this.onBack});

  final TrailData trail;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
      child: Stack(
        children: [
          SizedBox(
            height: 285,
            width: double.infinity,
            child: Image.asset(trail.imageAsset, fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.08),
                    Colors.black.withValues(alpha: 0.28),
                    Colors.black.withValues(alpha: 0.52),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 14,
            left: 14,
            child: Material(
              color: Colors.black.withValues(alpha: 0.3),
              shape: const CircleBorder(),
              child: IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                tooltip: 'Back',
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 18,
            child: Text(
              trail.name,
              textAlign: TextAlign.center,
              style: GoogleFonts.lilitaOne(
                fontSize: 28,
                color: context.isDarkMode
                    ? colors.softHighlight
                    : const Color(0xFF58FF42),
                letterSpacing: 0.8,
                shadows: const [
                  Shadow(
                    color: Color(0xFF103C0A),
                    blurRadius: 14,
                    offset: Offset(0, 2),
                  ),
                  Shadow(
                    color: Colors.black87,
                    blurRadius: 5,
                    offset: Offset(1.4, 1.4),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      decoration: BoxDecoration(
        color: context.isDarkMode ? colors.surface : const Color(0xFFF5F1E8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: context.isDarkMode ? colors.border : const Color(0xFFC9C1B1),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label:',
          style: GoogleFonts.fredoka(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.merriweather(
            fontSize: 13.5,
            height: 1.55,
            color: colors.textSecondary,
          ),
          textAlign: TextAlign.justify,
        ),
      ],
    );
  }
}

class _SafetyReminderCard extends StatelessWidget {
  const _SafetyReminderCard({required this.reminders});

  final List<String> reminders;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return _DetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: reminders
            .map(
              (reminder) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: colors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        reminder,
                        style: GoogleFonts.merriweather(
                          fontSize: 13.2,
                          height: 1.5,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _StartNavigationButton extends StatelessWidget {
  const _StartNavigationButton({required this.metadata});

  final HikeNavigationMetadata metadata;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: context.isDarkMode
                ? [const Color(0xFF1D4ED8), colors.accent]
                : const [Color(0xFF1D4ED8), Color(0xFF3FA65B)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: colors.shadow,
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () => _handleStartNavigation(context, metadata),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 18),
            minimumSize: const Size.fromHeight(64),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.navigation_rounded,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Start Navigation',
                style: GoogleFonts.fredoka(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LetsHikeButton extends StatelessWidget {
  const _LetsHikeButton({
    required this.mountainId,
    required this.mountainName,
    required this.trailId,
    required this.trailName,
  });

  final String mountainId;
  final String mountainName;
  final String trailId;
  final String trailName;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: context.isDarkMode
                ? [colors.primary, colors.accent]
                : const [
                    Color(0xFF41D11C),
                    Color(0xFF8DEB6B),
                    Color(0xFFEAF5E8),
                  ],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: colors.shadow,
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () => _handleLetsHike(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            'Let\'s Hike',
            style: GoogleFonts.fredoka(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: context.isDarkMode
                  ? Colors.white
                  : const Color(0xFF1E261A),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLetsHike(BuildContext context) async {
    final selectedDate = await showLetsHikeCalendarWeatherModal(
      context: context,
      trailName: trailName,
    );

    if (selectedDate == null || !context.mounted) {
      return;
    }

    if (_isPastHikeDate(selectedDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select today or a future date.')),
      );
      return;
    }

    final scheduledHike = ScheduledHike.create(
      mountainId: mountainId,
      mountainName: mountainName,
      trailId: trailId,
      trailName: trailName,
      hikeDate: selectedDate,
    );

    try {
      await HikeScheduleStore.instance.saveScheduledHike(scheduledHike);
    } on ArgumentError catch (_) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select today or a future date.')),
      );
      return;
    } on HikeScheduleException catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
      return;
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to save hike date. Please try again.'),
        ),
      );
      return;
    }

    final deliveryState = await HikeNotificationService.instance
        .currentReminderDeliveryState();

    if (!context.mounted) {
      return;
    }

    await _showHikeScheduledConfirmation(
      context,
      hikeDate: selectedDate,
      reminderMessage: hikeScheduledNotificationConfirmationMessage(
        hikeDate: selectedDate,
        deliveryState: deliveryState,
      ),
    );
  }

  Future<void> _showHikeScheduledConfirmation(
    BuildContext context, {
    required DateTime hikeDate,
    required String reminderMessage,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hike Scheduled'),
          content: Text(
            'Your hike at $mountainName is scheduled for '
            '${_formatHikeDate(hikeDate)}.\n\n'
            '$reminderMessage',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  String _formatHikeDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  bool _isPastHikeDate(DateTime date) {
    final today = ScheduledHike.manilaDateForInstant(DateTime.now());
    final hikeDate = _dateOnly(date);
    return hikeDate.isBefore(today);
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
