import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../widgets/animated_mt_apo_banner.dart'; 
import '../widgets/custom_back_button.dart';

class MtMariglemScreen extends StatelessWidget {
  const MtMariglemScreen({super.key});

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
        title: 'San Marcelino Classic Route',
        subtitle: 'Open Trail Details',
        onTap: () {
          Navigator.of(context).pushNamed('/mountain/mariglem/trail/classic');
        },
      ),
      _TrailButtonConfig(
        title: 'Mapanuepe Lake Ridge Link',
        subtitle: 'Open Trail Details',
        onTap: () {
          Navigator.of(context).pushNamed('/mountain/mariglem/trail/mapanuepe');
        },
      ),
      _TrailButtonConfig(
        title: 'Marella Riverbed Scramble',
        subtitle: 'Open Trail Details',
        onTap: () {
          Navigator.of(context).pushNamed('/mountain/mariglem/trail/marella');
        },
      ),
      _TrailButtonConfig(
        title: 'Aglao Technical Knife-Edge',
        subtitle: 'Open Trail Details',
        onTap: () {
          Navigator.of(context).pushNamed('/mountain/mariglem/trail/aglao');
        },
      ),
      _TrailButtonConfig(
        title: 'Consuelo Eco-Canyon Loop',
        subtitle: 'Open Trail Details',
        onTap: () {
          Navigator.of(context).pushNamed('/mountain/mariglem/trail/consuelo');
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
              AnimatedMtApoBanner(imageAsset: _headerImage, title: 'Mt. Mariglem'),
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
                    const _InfoLine(label: 'Name:', value: 'Mt. Mariglem'),
                    const _InfoLine(
                      label: 'Location:',
                      value: 'San Marcelino, Zambales, Philippines.',
                    ),
                    const _InfoLine(
                      label: 'Elevation:',
                      value: 'Around 845 MASL. A commanding volcanic-ash peak dominating the landscape of southern Zambales.',
                    ),
                    const _InfoLine(
                      label: 'Description:',
                      value: 'Mt. Mariglem is an unforgiving yet breathtaking destination in the Zambales mountain range. It is highly respected for its rolling, sun-baked grassland ridges, sprawling volcanic sand riverbeds, challenging knife-edges, and stunning high-angle overviews of the famous Mapanuepe Lake.',
                    ),
                    const _InfoLine(
                      label: 'Slope:',
                      value: 'Composed of intensely loose volcanic ash plains, steep clay hill sections, sliding gravel fields, and high-exposure razor crests that test both footing precision and balance.',
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
    final buttonColor = context.isDarkMode ? colors.accent : MtMariglemScreen._buttonColor;
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