import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/trail_data/Sta.Cruz details.dart';
import '../../../data/trail_data/kapatagan_trail_data.dart';
import '../widgets/animated_mt_apo_banner.dart';
import '../widgets/custom_back_button.dart';

class MtApoScreen extends StatelessWidget {
  const MtApoScreen({super.key});

  static const _backgroundColor = Color(0xFFE3DDCF);
  static const _cardColor = Color(0xFFF4EFE5);
  static const _buttonColor = Color(0xFFB98914);
  static const _buttonShadow = Color(0xFF6A4A09);
  static const _headerImage = 'assets/images/mt apo.jpg';

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = context.isDarkMode;
    final trailButtons = [
      _TrailButtonConfig(
        title: staCruzSibulanTrail.name,
        subtitle: 'Open Trail Details',
        onTap: () {
          Navigator.of(context).pushNamed(
            AppRoutes.trail(
              AppRoutes.mtApoMountainId,
              AppRoutes.staCruzTrailId,
            ),
          );
        },
      ),
      _TrailButtonConfig(
        title: kapataganTrail.name,
        subtitle: 'Open Trail Details',
        onTap: () {
          Navigator.of(context).pushNamed(
            AppRoutes.trail(
              AppRoutes.mtApoMountainId,
              AppRoutes.kapataganTrailId,
            ),
          );
        },
      ),
      _TrailButtonConfig(
        title: 'Kidapawan Trail',
        subtitle: 'Coming Soon',
        onTap: () => _showPlaceholder(context, 'Kidapawan Trail'),
      ),
      _TrailButtonConfig(
        title: 'Magpet Trail',
        subtitle: 'Coming Soon',
        onTap: () => _showPlaceholder(context, 'Magpet Trail'),
      ),
      _TrailButtonConfig(
        title: 'Bansalan Trail',
        subtitle: 'Coming Soon',
        onTap: () => _showPlaceholder(context, 'Bansalan Trail'),
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
              AnimatedMtApoBanner(imageAsset: _headerImage, title: 'Mt. Apo'),
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
                    _InfoLine(label: 'Name:', value: 'Mt. Apo'),
                    _InfoLine(
                      label: 'Location:',
                      value:
                          'Mindanao, Philippines, between Davao City, Davao del Sur, and Cotabato.',
                    ),
                    _InfoLine(
                      label: 'Elevation:',
                      value:
                          '2,954 meters above sea level, making it the highest mountain in the Philippines.',
                    ),
                    _InfoLine(
                      label: 'Description:',
                      value:
                          'Mt. Apo is a dormant stratovolcano and part of Mt. Apo Natural Park. It is known for its forests, wildlife, sulfur vents, and importance as a habitat for the Philippine eagle.',
                    ),
                    _InfoLine(
                      label: 'Slope:',
                      value:
                          'Its slope is steep, rugged, and challenging, with some trails having rocky and forested terrain. This makes it suitable for experienced hikers.',
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

  static void _showPlaceholder(BuildContext context, String trailName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$trailName details will be added soon.')),
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
        : MtApoScreen._buttonColor;
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
          elevation: context.isDarkMode ? 0 : 3.5,
          shadowColor: context.isDarkMode
              ? colors.shadow
              : MtApoScreen._buttonShadow,
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
