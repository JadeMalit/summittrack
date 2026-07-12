import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../widgets/animated_mt_apo_banner.dart'; 
import '../widgets/custom_back_button.dart';

class MtDamasScreen extends StatelessWidget {
  const MtDamasScreen({super.key});

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
        title: 'Papaac Traditional Summit Assault',
        subtitle: 'Open Trail Details',
        onTap: () {
          Navigator.of(context).pushNamed('/mountain/damas/trail/papaac');
        },
      ),
      _TrailButtonConfig(
        title: 'Ubod Falls Eco-Adventure Link',
        subtitle: 'Open Trail Details',
        onTap: () {
          Navigator.of(context).pushNamed('/mountain/damas/trail/ubod');
        },
      ),
      _TrailButtonConfig(
        title: 'Dueg San Felipe Traverse Route',
        subtitle: 'Open Trail Details',
        onTap: () {
          Navigator.of(context).pushNamed('/mountain/damas/trail/dueg');
        },
      ),
      _TrailButtonConfig(
        title: 'Canding Falls Baseline Circuit',
        subtitle: 'Open Trail Details',
        onTap: () {
          Navigator.of(context).pushNamed('/mountain/damas/trail/canding');
        },
      ),
      _TrailButtonConfig(
        title: 'Siwsiw Technical Knife-Edge',
        subtitle: 'Open Trail Details',
        onTap: () {
          Navigator.of(context).pushNamed('/mountain/damas/trail/siwsiw');
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
              AnimatedMtApoBanner(imageAsset: _headerImage, title: 'Mt. Damas'),
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
                    const _InfoLine(label: 'Name:', value: 'Mt. Damas'),
                    const _InfoLine(
                      label: 'Location:',
                      value: 'San Clemente, Tarlac, Philippines.',
                    ),
                    const _InfoLine(
                      label: 'Elevation:',
                      value: '682 meters above sea level. A notoriously rugged mountain rising prominently out of the flat farmlands of western Tarlac.',
                    ),
                    const _InfoLine(
                      label: 'Description:',
                      value: 'Mt. Damas is respected among local mountaineers for its unforgiving trail environment. It combines extreme heat exposure across unshaded cogon ridges with raw, deep riverbed trekking, technical roped canyon walls, and hidden majestic waterfalls.',
                    ),
                    const _InfoLine(
                      label: 'Slope:',
                      value: 'Composed of intensely sharp vertical soil assaults, loose volcanic gravel slide zones, slippery river boulder complexes, and a technical knife-edge crest requiring careful multi-point balance.',
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
    final buttonColor = context.isDarkMode ? colors.accent : MtDamasScreen._buttonColor;
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