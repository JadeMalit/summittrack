import 'dart:ui';

import 'package:flutter/material.dart';

class AnimatedNavIcon extends StatelessWidget {
  const AnimatedNavIcon({
    super.key,
    required this.icon,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
    this.isLifted = false,
  });

  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final bool isLifted;

  @override
  Widget build(BuildContext context) {
    const duration = Duration(milliseconds: 280);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: isActive ? 1 : 0),
      duration: duration,
      curve: isActive ? Curves.easeOutCubic : Curves.easeInOutCubic,
      builder: (context, progress, _) {
        final lift = isLifted ? lerpDouble(0, -7, progress)! : 0.0;
        final scale = isLifted ? lerpDouble(1, 1.12, progress)! : 1.0;
        final iconSize = lerpDouble(24, 26, progress)!;
        final color = Color.lerp(inactiveColor, activeColor, progress)!;

        return Transform.translate(
          offset: Offset(0, lift),
          child: AnimatedScale(
            scale: scale,
            duration: duration,
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: duration,
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: isLifted && progress > 0.01 ? 14 : 0,
                vertical: isLifted && progress > 0.01 ? 10 : 0,
              ),
              decoration: isLifted
                  ? BoxDecoration(
                      color: Color.lerp(
                        Colors.transparent,
                        activeColor.withValues(alpha: 0.11),
                        progress,
                      ),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Color.lerp(
                          Colors.transparent,
                          activeColor.withValues(alpha: 0.12),
                          progress,
                        )!,
                      ),
                      boxShadow: [
                        if (progress > 0.01)
                          BoxShadow(
                            color: activeColor.withValues(alpha: 0.18 * progress),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                      ],
                    )
                  : null,
              child: Icon(icon, size: iconSize, color: color),
            ),
          ),
        );
      },
    );
  }
}
