import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/state/app_mode_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/trail_data/trail_data.dart';
import '../../hike/screens/lets_hike_calendar_weather_modal.dart';
import '../widgets/first_aid_emergency_tips.dart';
import '../widgets/foldable_trail_checklist_card.dart';
import '../widgets/trail_photo_uploader.dart';

class TrailDetailScreen extends StatelessWidget {
  const TrailDetailScreen({
    super.key,
    required this.trail,
    required this.parentRoute,
    this.trailPhotoId = 'sta_cruz_sibulan',
  });

  final TrailData trail;
  final String parentRoute;
  final String trailPhotoId;

  static const _backgroundColor = Color(0xFFE3DDCF);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final isOfflineMode = AppModeProvider.instance.isOfflineMode;

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
                    if (trail.showTrailMap) ...[
                      const SizedBox(height: 18),
                      const _SectionHeading(title: 'Trail Map / Gradient Map'),
                      const SizedBox(height: 10),
                      const _TrailMapCard(),
                    ],
                    if (isOfflineMode) ...[
                      const SizedBox(height: 18),
                      const _SectionHeading(title: 'Offline Access'),
                      const SizedBox(height: 10),
                      const _OfflineTrailAccessCard(),
                    ] else ...[
                      const SizedBox(height: 18),
                      const _SectionHeading(title: 'Add Your Photo'),
                      const SizedBox(height: 10),
                      TrailPhotoUploader(trailId: trailPhotoId),
                      const SizedBox(height: 22),
                      _LetsHikeButton(trailName: trail.name),
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

class _TrailMapCard extends StatelessWidget {
  const _TrailMapCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? colors.surfaceHigh
            : Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: context.isDarkMode ? colors.border : const Color(0xFFC7C0B3),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sta. Cruz / Sibulan Trail to Mt. Apo Gradient Map',
            style: GoogleFonts.fredoka(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: 1.35,
              child: CustomPaint(
                painter: _TrailMapPainter(),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Elevation change from jump-off to summit',
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: context.isDarkMode
                              ? const Color(0xFF3A473A)
                              : const Color(0xFF625948),
                        ),
                      ),
                      const Spacer(),
                      const Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _MapLegendChip(
                            label: 'Jump-off',
                            color: Color(0xFF2AA64A),
                          ),
                          _MapLegendChip(
                            label: 'Mid Trail',
                            color: Color(0xFFE5B537),
                          ),
                          _MapLegendChip(
                            label: 'Boulder Face',
                            color: Color(0xFFF0702B),
                          ),
                          _MapLegendChip(
                            label: 'Summit Push',
                            color: Color(0xFFDE3F34),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapLegendChip extends StatelessWidget {
  const _MapLegendChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? colors.surface.withValues(alpha: 0.92)
            : Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.75)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LetsHikeButton extends StatelessWidget {
  const _LetsHikeButton({required this.trailName});

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
          onPressed: () async {
            final selectedDate = await showLetsHikeCalendarWeatherModal(
              context: context,
              trailName: trailName,
            );

            if (selectedDate == null || !context.mounted) {
              return;
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Hike date confirmed: ${_formatHikeDate(selectedDate)}',
                ),
              ),
            );
          },
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
}

class _TrailMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFF2F1ED), Color(0xFFE4E2DC)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, background);

    final contourPaint = Paint()
      ..color = const Color(0xFFCEC9BF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var i = 0; i < 8; i++) {
      final y = 18 + (i * size.height / 8.5);
      final path = Path()
        ..moveTo(0, y)
        ..quadraticBezierTo(size.width * 0.2, y - 12, size.width * 0.42, y + 8)
        ..quadraticBezierTo(size.width * 0.68, y + 18, size.width, y - 10);
      canvas.drawPath(path, contourPaint);
    }

    final routePath = Path()
      ..moveTo(size.width * 0.10, size.height * 0.78)
      ..quadraticBezierTo(
        size.width * 0.18,
        size.height * 0.73,
        size.width * 0.26,
        size.height * 0.69,
      )
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.67,
        size.width * 0.42,
        size.height * 0.61,
      )
      ..quadraticBezierTo(
        size.width * 0.50,
        size.height * 0.56,
        size.width * 0.58,
        size.height * 0.51,
      )
      ..quadraticBezierTo(
        size.width * 0.66,
        size.height * 0.44,
        size.width * 0.73,
        size.height * 0.36,
      )
      ..quadraticBezierTo(
        size.width * 0.80,
        size.height * 0.28,
        size.width * 0.90,
        size.height * 0.14,
      );

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 10;
    canvas.drawPath(routePath.shift(const Offset(0, 3)), shadowPaint);

    final routePaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF2AA64A),
          Color(0xFFE7C545),
          Color(0xFFF07A2F),
          Color(0xFFE33B33),
        ],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 8;
    canvas.drawPath(routePath, routePaint);

    final markerPaint = Paint()..color = const Color(0xFF1F3C20);
    final summitPaint = Paint()..color = const Color(0xFFB61E1B);

    canvas.drawCircle(
      Offset(size.width * 0.10, size.height * 0.78),
      5,
      markerPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.90, size.height * 0.14),
      5.5,
      summitPaint,
    );

    _drawMapLabel(
      canvas,
      size,
      text: 'Sibulan\nJump-off',
      offset: Offset(size.width * 0.04, size.height * 0.80),
      alignLeft: true,
    );
    _drawMapLabel(
      canvas,
      size,
      text: 'Forest and\nfarm trail',
      offset: Offset(size.width * 0.29, size.height * 0.64),
      alignLeft: true,
    );
    _drawMapLabel(
      canvas,
      size,
      text: 'Boulder Face',
      offset: Offset(size.width * 0.58, size.height * 0.47),
      alignLeft: true,
    );
    _drawMapLabel(
      canvas,
      size,
      text: 'Mt. Apo\nSummit',
      offset: Offset(size.width * 0.82, size.height * 0.13),
      alignLeft: true,
    );
  }

  void _drawMapLabel(
    Canvas canvas,
    Size size, {
    required String text,
    required Offset offset,
    required bool alignLeft,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: GoogleFonts.poppins(
          fontSize: size.width * 0.034,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF544A3A),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width * 0.26);

    painter.paint(
      canvas,
      alignLeft ? offset : offset - Offset(painter.width, 0),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
