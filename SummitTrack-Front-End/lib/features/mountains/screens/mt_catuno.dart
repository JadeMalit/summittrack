import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/animated_mt_apo_banner.dart'; 
import '../widgets/custom_back_button.dart';

class MtCatunoScreen extends StatelessWidget {
  const MtCatunoScreen({super.key});

  static const _backgroundColor = Color(0xFFE3DDCF);
  static const _cardColor = Color(0xFFF4EFE5);
  static const _buttonColor = Color(0xFFB98914); 
  static const _headerImage = 'assets/images/sta_cruz_sibulan_trail.png'; 

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = context.isDarkMode;

    final trailButtons = [
      _TrailButtonConfig(
        title: 'Traditional Catuno Summit Loop',
        subtitle: 'Open Trail Details',
        onTap: () {
          Navigator.of(context).pushNamed('/mountain/catuno/trail/summit');
        },
      ),
      _TrailButtonConfig(
        title: 'Catuno-Lubog Twin Peak Traverse',
        subtitle: 'Open Trail Details',
        onTap: () {
          Navigator.of(context).pushNamed('/mountain/catuno/trail/lubog');
        },
      ),
      _TrailButtonConfig(
        title: 'Limestone Formations Explorer',
        subtitle: 'Open Trail Details',
        onTap: () {
          Navigator.of(context).pushNamed('/mountain/catuno/trail/explorer');
        },
      ),
      _TrailButtonConfig(
        title: 'Backcountry River Back-Trail',
        subtitle: 'Open Trail Details',
        onTap: () {
          Navigator.of(context).pushNamed('/mountain/catuno/trail/river');
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
              AnimatedMtApoBanner(imageAsset: _headerImage, title: 'Mt. Catuno'),
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
                    const _InfoLine(label: 'Name:', value: 'Mt. Catuno (Mt. Katingno)'),
                    const _InfoLine(
                      label: 'Location:',
                      value: 'Tanay, Rizal, Philippines.',
                    ),
                    const _InfoLine(
                      label: 'Elevation:',
                      value: 'Approximately 740+ MASL. Positioned elegantly along the scenic karst boundaries of Rizal.',
                    ),
                    const _InfoLine(
                      label: 'Description:',
                      value: 'Mt. Catuno stands proudly as a hidden wonderland within Rizal\'s rich eco-tourism mapping. It heavily showcases ancient limestone formations, scenic karst bridges, and forested trails that provide an exceptional technical hike. Conquering its summit rewards adventurers with beautiful panoramic viewing decks of the vast Sierra Madre, the neighboring Mt. Lubog pinnacle, and pristine mountain watershed networks.',
                    ),
                    const _InfoLine(
                      label: 'Slope:',
                      value: 'Highly technical rolling patterns. Shifts from gradual muddy woodland paths and switchbacks into extremely sharp, exposed limestone rock scrambles. Navigating the ridge segments demands strong deliberate balance and handhold checks due to complex vertical stone pockets.',
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
                          color: isDark ? colors.divider : const Color(0xFFB8B09B),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.merriweather(color: colors.textPrimary, fontSize: 13.5, height: 1.5),
          children: [
            TextSpan(text: '$label ', style: const TextStyle(fontWeight: FontWeight.w700)),
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
    final buttonColor = context.isDarkMode ? colors.accent : MtCatunoScreen._buttonColor;
    final titleColor = context.isDarkMode ? colors.background : const Color(0xFF2D1E06);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: config.onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: titleColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Column(
          children: [
            Text(config.title, style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.w700, color: titleColor)),
            const SizedBox(height: 2),
            Text(config.subtitle, style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, fontStyle: FontStyle.italic, color: titleColor.withAlpha(200))),
          ],
        ),
      ),
    );
  }
}

class _TrailButtonConfig {
  const _TrailButtonConfig({required this.title, required this.subtitle, required this.onTap});
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}