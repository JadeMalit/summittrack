import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../helpers/profile_constants.dart';

class ProfileBackground extends StatelessWidget {
  const ProfileBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: context.isDarkMode
                    ? [colors.background, colors.backgroundAlt, colors.surface]
                    : [
                        ProfileConstants.pageBackground,
                        const Color(0xFFEAF1E4),
                        const Color(0xFFF9FBF6),
                      ],
              ),
            ),
          ),
        ),
        Positioned(
          top: -72,
          right: -60,
          child: _SoftOrb(
            size: 180,
            color: colors.accent.withValues(
              alpha: context.isDarkMode ? 0.08 : 0.09,
            ),
          ),
        ),
        Positioned(
          top: 140,
          left: -70,
          child: _SoftOrb(
            size: 150,
            color: colors.softHighlight.withValues(
              alpha: context.isDarkMode ? 0.08 : 0.12,
            ),
          ),
        ),
      ],
    );
  }
}

class _SoftOrb extends StatelessWidget {
  const _SoftOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, Colors.transparent],
            stops: const [0.0, 1.0],
          ),
        ),
      ),
    );
  }
}
