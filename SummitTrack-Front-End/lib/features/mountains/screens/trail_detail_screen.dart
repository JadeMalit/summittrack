import 'dart:async';

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
import '../../hike/models/scheduled_hike.dart';
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

const _staCruzSibulanTrailPhotoId = 'sta_cruz_sibulan';

@visibleForTesting
bool shouldGateTrailNavigationBehindScheduledHike({
  required String mountainId,
  required String trailPhotoId,
  String? navigationTrailId,
}) {
  final normalizedMountainId = MountainScheduleIdentity.normalizeMountainId(
    mountainId,
  );
  final isStaCruzSibulanTrail =
      trailPhotoId == _staCruzSibulanTrailPhotoId ||
      navigationTrailId == AppRoutes.staCruzTrailId;

  return normalizedMountainId == AppRoutes.mtApoMountainId &&
      isStaCruzSibulanTrail;
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
    final isOfflineMode = AppModeProvider.instance.isOfflineMode;
    final mountainId = MountainScheduleIdentity.idFromRoute(parentRoute);
    final mountainName = MountainScheduleIdentity.displayNameForMountainId(
      mountainId,
    );
    final navigationMetadata = NavigationTrails.forTrailId(trailPhotoId);

    // 🏔️ Waypoints, Peak Elevation & Distance
    final waypoints = TrailWaypointHelper.getWaypointsForTrail(
      trail,
      trailPhotoId,
    );
    final maxElevation = waypoints.isNotEmpty
        ? waypoints.map((w) => w.elevation).reduce((a, b) => a > b ? a : b)
        : null;
    final totalDistance = waypoints.isNotEmpty ? waypoints.last.distance : null;

    final isDark = context.isDarkMode;
    final bgColor = isDark ? colors.background : _backgroundColor;

    return Scaffold(
      backgroundColor: bgColor,
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
                // 100 bottom padding para hindi matakpan ng floating button ang huling item sa scroll view
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
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
                      distance: totalDistance,
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
                      _TrailNavigationSection(
                        navigationMetadata: navigationMetadata,
                        mountainId: mountainId,
                        trailPhotoId: trailPhotoId,
                        navigationTrailId: navigationTrailId,
                        trailName: trail.name,
                      ),
                      const SizedBox(height: 18),
                      const _SectionHeading(title: 'Add Photo or Video'),
                      const SizedBox(height: 10),
                      TrailPhotoUploader(trailId: trailPhotoId),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // 🟢 STYLED & ANIMATED FLOATING BOTTOM DOCK
      bottomNavigationBar: isOfflineMode
          ? null
          : Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              color: Colors.transparent,
              child: SafeArea(
                top: false,
                child: _LetsHikeAnimatedButton(
                  mountainId: mountainId,
                  mountainName: mountainName,
                  trailId: trailPhotoId,
                  trailName: trail.name,
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
  // if (HikeTrackingService.instance.hasActiveSession) {
  //  Navigator.of(context).pushNamed(AppRoutes.hikeNavigation);
  //  return;
  //}

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

/// 🟢 TRIPLE-ANIMATED FLOATING "LET'S HIKE" BUTTON
class _LetsHikeAnimatedButton extends StatefulWidget {
  const _LetsHikeAnimatedButton({
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
  State<_LetsHikeAnimatedButton> createState() =>
      __LetsHikeAnimatedButtonState();
}

class __LetsHikeAnimatedButtonState extends State<_LetsHikeAnimatedButton>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _yOffsetAnimation;
  late Animation<double> _glowRadiusAnimation;

  late AnimationController _shimmerController;
  late Animation<double> _shimmerTranslation;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    // 🌊 1. Floating & Breathing Glow Setup (Smooth Loop)
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);

    _yOffsetAnimation = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _glowRadiusAnimation = Tween<double>(begin: 12, end: 26).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // ✨ 2. Shimmer Light Sweep Effect
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2400),
      vsync: this,
    )..repeat();

    _shimmerTranslation = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = context.isDarkMode;

    return AnimatedBuilder(
      animation: Listenable.merge([_floatController, _shimmerController]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _yOffsetAnimation.value),
          child: GestureDetectingWrapper(
            onTapDown: () => setState(() => _isPressed = true),
            onTapUp: () => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            onTap: () => _handleLetsHike(context),
            child: AnimatedScale(
              scale: _isPressed ? 0.92 : 1.0,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
              child: Container(
                height: 64,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [colors.primary, colors.accent]
                        : const [
                            Color(0xFF38C812),
                            Color(0xFF63E33B),
                            Color(0xFF2FA20E),
                          ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF38C812).withOpacity(0.50),
                      blurRadius: _glowRadiusAnimation.value,
                      spreadRadius: 2,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withOpacity(0.45),
                    width: 1.5,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Shimmer Light Sweep Layer
                      Positioned.fill(
                        child: FractionalTranslation(
                          translation: Offset(_shimmerTranslation.value, 0),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.white.withOpacity(0.35),
                                  Colors.transparent,
                                ],
                                stops: const [0.35, 0.5, 0.65],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Button Content
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Transform.scale(
                            scale: 1.0 + (_floatController.value * 0.08),
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.explore_rounded,
                                color: Color(0xFF1E261A),
                                size: 26,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Let\'s Hike',
                            style: GoogleFonts.fredoka(
                              fontSize: 23,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1E261A),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleLetsHike(BuildContext context) async {
    final selectedDate = await showLetsHikeCalendarWeatherModal(
      context: context,
      trailName: widget.trailName,
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
      mountainId: widget.mountainId,
      mountainName: widget.mountainName,
      trailId: widget.trailId,
      trailName: widget.trailName,
      hikeDate: selectedDate,
    );

    try {
      await HikeScheduleStore.instance.saveScheduledHike(scheduledHike);
    } on ArgumentError catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select today or a future date.')),
      );
      return;
    } on HikeScheduleException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
      return;
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to save hike date. Please try again.'),
        ),
      );
      return;
    }

    final deliveryState = await HikeNotificationService.instance
        .currentReminderDeliveryState();

    if (!context.mounted) return;

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
            'Your hike at ${widget.mountainName} is scheduled for '
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
    return _dateOnly(date).isBefore(today);
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}

/// Helper Wrapper para sa Touch Events
class GestureDetectingWrapper extends StatelessWidget {
  const GestureDetectingWrapper({
    super.key,
    required this.child,
    required this.onTapDown,
    required this.onTapUp,
    required this.onTapCancel,
    required this.onTap,
  });

  final Widget child;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;
  final VoidCallback onTapCancel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onTapDown(),
      onTapUp: (_) => onTapUp(),
      onTapCancel: () => onTapCancel(),
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }
}

class _TrailNavigationSection extends StatefulWidget {
  const _TrailNavigationSection({
    required this.navigationMetadata,
    required this.mountainId,
    required this.trailPhotoId,
    required this.trailName,
    this.navigationTrailId,
  });

  final HikeNavigationMetadata? navigationMetadata;
  final String mountainId;
  final String trailPhotoId;
  final String trailName;
  final String? navigationTrailId;

  @override
  State<_TrailNavigationSection> createState() =>
      _TrailNavigationSectionState();
}

class _TrailNavigationSectionState extends State<_TrailNavigationSection> {
  final HikeScheduleStore _scheduleStore = HikeScheduleStore.instance;

  @override
  void initState() {
    super.initState();
    _loadScheduleIfNeeded();
  }

  @override
  void didUpdateWidget(covariant _TrailNavigationSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadScheduleIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    final metadata = widget.navigationMetadata;
    if (metadata?.isNavigationEnabled != true) {
      return const SizedBox.shrink();
    }

    if (!_requiresScheduledHike) {
      return _NavigationControls(metadata: metadata!);
    }

    return ListenableBuilder(
      listenable: _scheduleStore,
      builder: (context, _) {
        final activeHike = _scheduleStore.activeHikeForTrailToday(
          widget.mountainId,
          widget.trailPhotoId,
          trailName: widget.trailName,
        );

        if (activeHike == null) {
          return const SizedBox.shrink();
        }

        return _NavigationControls(metadata: metadata!);
      },
    );
  }

  bool get _requiresScheduledHike {
    return shouldGateTrailNavigationBehindScheduledHike(
      mountainId: widget.mountainId,
      trailPhotoId: widget.trailPhotoId,
      navigationTrailId: widget.navigationTrailId,
    );
  }

  void _loadScheduleIfNeeded() {
    if (_requiresScheduledHike) {
      unawaited(_scheduleStore.load());
    }
  }
}

class _NavigationControls extends StatelessWidget {
  const _NavigationControls({required this.metadata});

  final HikeNavigationMetadata metadata;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        const _SectionHeading(title: 'Navigation'),
        const SizedBox(height: 10),
        _StartNavigationButton(metadata: metadata),
      ],
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
