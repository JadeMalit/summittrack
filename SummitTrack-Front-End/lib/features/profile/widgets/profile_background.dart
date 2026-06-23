import 'package:flutter/material.dart';

import '../helpers/profile_constants.dart';

class ProfileBackground extends StatelessWidget {
  const ProfileBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
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
            color: ProfileConstants.cardTop.withValues(alpha: 0.09),
          ),
        ),
        Positioned(
          top: 140,
          left: -70,
          child: _SoftOrb(
            size: 150,
            color: ProfileConstants.cardBottom.withValues(alpha: 0.12),
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
