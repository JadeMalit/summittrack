import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/animated_mt_apo_banner.dart'; 
import '../widgets/custom_back_button.dart';

class MtBatulaoScreen extends StatelessWidget {
  const MtBatulaoScreen({super.key});

  // Disenyo at kulay para sa uniformity ng SummitTrack app
  static const _backgroundColor = Color(0xFFE3DDCF);
  static const _cardColor = Color(0xFFF4EFE5);
  static const _buttonColor = Color(0xFFB98914); 
  static const _buttonShadow = Color(0xFF6A4A09);
  static const _headerImage = 'assets/images/sta_cruz_sibulan_trail.png'; // Pwedeng palitan ng Batulao asset kapag meron na

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = context.isDarkMode;

    final trailButtons = [
      _TrailButtonConfig(
        title: 'Old Trail',
        subtitle: 'Open Trail Details',
        onTap: () {
          // DIRECT HARDCODED ROUTING: Swabe ang pasok sa segment length == 4 ng AppRouter niyo
          Navigator.of(context).pushNamed('/mountain/batulao/trail/old');
        },
      ),
      _TrailButtonConfig(
        title: 'New Trail',
        subtitle: 'Open Trail Details',
        onTap: () {
          Navigator.of(context).pushNamed('/mountain/batulao/trail/new');
        },
      ),
    ];

    return Scaffold(
      backgroundColor: isDark ? colors.background : _backgroundColor,
      body: SafeArea(
        top: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedMtApoBanner(imageAsset: _headerImage, title: 'Mt. Batulao'),
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? colors.surface : _cardColor,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: isDark ? colors.border : const Color(0xFFB9B29F),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow,
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _InfoLine(label: 'Name:', value: 'Mt. Batulao'),
                    const _InfoLine(
                      label: 'Location:',
                      value: 'Nasugbu, Batangas, Philippines.',
                    ),
                    const _InfoLine(
                      label: 'Elevation:',
                      value: '761 meters above sea level. One of the most popular day-hike destinations near Metro Manila.',
                    ),
                    const _InfoLine(
                      label: 'Description:',
                      value: 'Mt. Batulao is famous for its cool breeze, rolling landscapes, and standard scenic mountain ridges. It offers a 360-degree clear view of Batangas and Cavite provinces, making it absolute for weekend warriors and beginner climbers.',
                    ),
                    const _InfoLine(
                      label: 'Slope:',
                      value: 'Grassy hills with sharp rocky knife-edges. Most parts are easy and straightforward, but some summit paths require light rope handling or standard rock balancing.',
                    ),
                    const SizedBox(height: 18),
                    for (
                      var index = 0;
                      index < trailButtons.length;
                      index++
                    ) ...[
                      if (index > 0) ...[
                        const SizedBox(height: 10),
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: isDark
                              ? colors.divider
                              : const Color(0xFFB8B09B),
                        ),
                        const SizedBox(height: 10),
                      ],
                      _TrailActionButton(config: trailButtons[index]),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 22),
              CustomBackButton(onTap: () => Navigator.of(context).maybePop()),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textStyle = GoogleFonts.merriweather(
      color: colors.textPrimary,
      fontSize: 13.5,
      height: 1.5,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: textStyle,
          children: [
            TextSpan(
              text: '$label ',
              style: textStyle.copyWith(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _TrailActionButton extends StatelessWidget {
  const _TrailActionButton({required this.config});

  final _TrailButtonConfig config;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final buttonColor = context.isDarkMode
        ? colors.accent
        : MtBatulaoScreen._buttonColor;
    final titleColor = context.isDarkMode
        ? colors.background
        : const Color(0xFF2D1E06);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: config.onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: titleColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              config.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              config.subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
                color: titleColor.withValues(alpha: 0.78),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrailButtonConfig {
  const _TrailButtonConfig({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
}