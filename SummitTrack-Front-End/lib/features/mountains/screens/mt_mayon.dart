import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../widgets/animated_mt_apo_banner.dart'; 
import '../widgets/custom_back_button.dart';

class MtMayonScreen extends StatelessWidget {
  const MtMayonScreen({super.key});

  // Eksaktong disenyo at kulay mula sa Mt. Pulag para sa uniformity ng app niyo
  static const _backgroundColor = Color(0xFFE3DDCF);
  static const _cardColor = Color(0xFFF4EFE5);
  static const _buttonColor = Color(0xFFB98914); 
  static const _buttonShadow = Color(0xFF6A4A09);
  static const _headerImage = 'assets/images/sta_cruz_sibulan_trail.png'; // Palitan ng Mayon banner image asset kapag meron na

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = context.isDarkMode;

    final trailButtons = [
      _TrailButtonConfig(
        title: 'Buyohan Trail',
        subtitle: 'Open Trail Details',
        onTap: () {
          // DIRECT HARDCODED ROUTING: Para 100% mag-match sa segment length == 4 ng AppRouter niyo
          Navigator.of(context).pushNamed('/mountain/mayon/trail/buyohan');
        },
      ),
      _TrailButtonConfig(
        title: 'Anoling Trail',
        subtitle: 'Open Trail Details',
        onTap: () {
          Navigator.of(context).pushNamed('/mountain/mayon/trail/anoling');
        },
      ),
      _TrailButtonConfig(
        title: 'Mi-isi Trail',
        subtitle: 'Open Trail Details',
        onTap: () {
          Navigator.of(context).pushNamed('/mountain/mayon/trail/miisi');
        },
      ),
      _TrailButtonConfig(
        title: 'Tabaco Trail',
        subtitle: 'Open Trail Details', // IN-UPDATE: Aktibo na ang Tabaco Trail detalye!
        onTap: () {
          Navigator.of(context).pushNamed('/mountain/mayon/trail/tabaco');
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
              AnimatedMtApoBanner(imageAsset: _headerImage, title: 'Mt. Mayon'),
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
                    const _InfoLine(label: 'Name:', value: 'Mt. Mayon'),
                    const _InfoLine(
                      label: 'Location:',
                      value: 'Albay, Bicol Region, Luzon, Philippines.',
                    ),
                    const _InfoLine(
                      label: 'Elevation:',
                      value: '2,463 meters above sea level, globally renowned for its perfectly symmetrical stratovolcano cone shape.',
                    ),
                    const _InfoLine(
                      label: 'Description:',
                      value: 'Mt. Mayon is the most active volcano in the Philippines, famous for its majestic beauty and historical eruptions. It features volcanic ash fields, rocky ridges, and panoramic views of the Pacific Ocean and Albay Gulf.',
                    ),
                    const _InfoLine(
                      label: 'Slope:',
                      value: 'Highly steep, rugged, and completely exposed terrain near the upper sections. The presence of loose volcanic rocks, scoria, and heat makes it a very challenging and advanced climb.',
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
        : MtMayonScreen._buttonColor;
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
              : MtMayonScreen._buttonShadow,
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