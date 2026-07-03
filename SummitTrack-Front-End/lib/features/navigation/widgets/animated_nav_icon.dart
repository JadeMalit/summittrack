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
    final isLiftedActive = isLifted && isActive;
    final iconSize = isActive ? 26.0 : 24.0;
    final color = isActive ? activeColor : inactiveColor;
    final iconContent = Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLiftedActive ? 14 : 0,
        vertical: isLiftedActive ? 10 : 0,
      ),
      decoration: isLiftedActive
          ? BoxDecoration(
              color: activeColor.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: activeColor.withValues(alpha: 0.12)),
              boxShadow: [
                BoxShadow(
                  color: activeColor.withValues(alpha: 0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            )
          : null,
      child: Icon(icon, size: iconSize, color: color),
    );

    return SizedBox(
      width: 58,
      height: 54,
      child: Center(
        child: Transform.translate(
          offset: isLiftedActive ? const Offset(0, -7) : Offset.zero,
          child: Transform.scale(
            scale: isLiftedActive ? 1.12 : 1,
            child: iconContent,
          ),
        ),
      ),
    );
  }
}
