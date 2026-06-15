import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../TrailData/Sta.Cruz details.dart';
import 'foldable_trail_checklist_card.dart';
import 'lets_hike_calendar_weather_modal.dart';

class TrailDetailScreen extends StatelessWidget {
  const TrailDetailScreen({
    super.key,
    required this.trail,
    required this.parentRoute,
  });

  final TrailData trail;
  final String parentRoute;

  static const _backgroundColor = Color(0xFFE3DDCF);

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TrailBanner(
                trail: trail,
                onBack: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                    return;
                  }

                  Navigator.of(context).pushReplacementNamed(parentRoute);
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    FoldableTrailChecklistCard(trail: trail),
                    const SizedBox(height: 18),
                    const _SectionHeading(
                      title: 'First Aid / Emergency Tips',
                    ),
                    const SizedBox(height: 10),
                    const _EmergencyTipsCard(),
                    const SizedBox(height: 18),
                    const _SectionHeading(
                      title: 'Trail Map / Gradient Map',
                    ),
                    const SizedBox(height: 10),
                    const _TrailMapCard(),
                    const SizedBox(height: 18),
                    const _SectionHeading(
                      title: 'Add Your Photo',
                    ),
                    const SizedBox(height: 10),
                    const _AddPhotoSection(),
                    const SizedBox(height: 22),
                    _LetsHikeButton(
                      trailName: trail.name,
                    ),
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

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.fredoka(
        fontSize: 19,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF2B2419),
      ),
    );
  }
}

class _TrailBanner extends StatelessWidget {
  const _TrailBanner({
    required this.trail,
    required this.onBack,
  });

  final TrailData trail;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(30),
      ),
      child: Stack(
        children: [
          SizedBox(
            height: 285,
            width: double.infinity,
            child: Image.asset(
              trail.imageAsset,
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.08),
                    Colors.black.withOpacity(0.28),
                    Colors.black.withOpacity(0.52),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 14,
            left: 14,
            child: Material(
              color: Colors.black.withOpacity(0.3),
              shape: const CircleBorder(),
              child: IconButton(
                onPressed: onBack,
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                ),
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
                color: const Color(0xFF58FF42),
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
  const _DetailCard({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F1E8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFC9C1B1)),
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label:',
          style: GoogleFonts.fredoka(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2F281D),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.merriweather(
            fontSize: 13.5,
            height: 1.55,
            color: const Color(0xFF3F372B),
          ),
          textAlign: TextAlign.justify,
        ),
      ],
    );
  }
}

class _EmergencyTipsCard extends StatelessWidget {
  const _EmergencyTipsCard();

  @override
  Widget build(BuildContext context) {
    final tipTextStyle = GoogleFonts.merriweather(
      fontSize: 12.8,
      height: 1.5,
      color: const Color(0xFF40382B),
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFC7C0B3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
        ),
        child: Column(
          children: [
            _EmergencyTipTile(
              title: 'Essential first-aid kit to bring before hiking',
              body:
                  'Adhesive bandages, gauze pads, medical tape, antiseptic wipes, antibacterial ointment, burn gel, disposable gloves, elastic wrap bandage, instant cold pack, scissors, tweezers, splint, sterile saline, emergency blanket, thermometer, hand sanitizer, pain relievers, antihistamines, anti-diarrheal medicine, insect repellent, and personal medications.',
              textStyle: tipTextStyle,
              initiallyExpanded: true,
            ),
            const SizedBox(height: 8),
            _EmergencyTipTile(
              title: 'For sprains, strains, or possible fractures',
              body: 'Stop hiking and protect the injured part.',
              textStyle: tipTextStyle,
            ),
            const SizedBox(height: 8),
            _EmergencyTipTile(
              title: 'For heat exhaustion or dehydration',
              body: 'Move to shade and cool down.',
              textStyle: tipTextStyle,
            ),
            const SizedBox(height: 8),
            _EmergencyTipTile(
              title: 'For heat stroke',
              body:
                  'Treat it as an emergency. Warning signs include confusion, altered mental status, loss of consciousness, seizures, and very high body temperature. Call emergency services immediately, move the person to a cool shaded area, remove outer clothing, and cool them quickly with cold wet cloths, cold water, and airflow. Put cool wet cloths or ice on the head, neck, armpits, and groin.',
              textStyle: tipTextStyle,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmergencyTipTile extends StatelessWidget {
  const _EmergencyTipTile({
    required this.title,
    required this.body,
    required this.textStyle,
    this.initiallyExpanded = false,
  });

  final String title;
  final String body;
  final TextStyle textStyle;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F5F1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFB7B0A4)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        iconColor: const Color(0xFF2F2A22),
        collapsedIconColor: const Color(0xFF2F2A22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        initiallyExpanded: initiallyExpanded,
        title: Text(
          title,
          style: GoogleFonts.fredoka(
            fontSize: 14.4,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF2F2A22),
          ),
        ),
        children: [
          Text(
            body,
            style: textStyle,
          ),
        ],
      ),
    );
  }
}

class _TrailMapCard extends StatelessWidget {
  const _TrailMapCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFC7C0B3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 4),
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
              color: const Color(0xFF2C251A),
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
                          color: const Color(0xFF625948),
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
  const _MapLegendChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.86),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.75)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF4A4033),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddPhotoSection extends StatelessWidget {
  const _AddPhotoSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Photo upload UI is ready. Backend hookup is not added yet.'),
              ),
            );
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF2D261D),
            side: const BorderSide(
              color: Color(0xFF92876F),
              width: 1.6,
            ),
            backgroundColor: Colors.white.withOpacity(0.7),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.add_rounded, size: 34),
              const SizedBox(width: 10),
              Text(
                'Add your photo',
                style: GoogleFonts.fredoka(
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          constraints: const BoxConstraints(minHeight: 250),
          decoration: BoxDecoration(
            color: const Color(0xFFD7D7D7),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF7A766F),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.image_outlined,
                    size: 54,
                    color: Color(0xFF686868),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Your uploaded trail photo will appear here.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF5C5C5C),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LetsHikeButton extends StatelessWidget {
  const _LetsHikeButton({
    required this.trailName,
  });

  final String trailName;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF41D11C),
              Color(0xFF8DEB6B),
              Color(0xFFEAF5E8),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 10,
              offset: Offset(0, 5),
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
              color: const Color(0xFF1E261A),
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
        colors: [
          Color(0xFFF2F1ED),
          Color(0xFFE4E2DC),
        ],
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
        ..quadraticBezierTo(
          size.width * 0.2,
          y - 12,
          size.width * 0.42,
          y + 8,
        )
        ..quadraticBezierTo(
          size.width * 0.68,
          y + 18,
          size.width,
          y - 10,
        );
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
      ..color = Colors.black.withOpacity(0.12)
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
