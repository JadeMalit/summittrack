import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../helpers/profile_constants.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.onBackTap});

  final VoidCallback onBackTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: ProfileConstants.topBarHeight,
      child: Align(
        alignment: Alignment.centerLeft,
        child: _TopIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: onBackTap,
        ),
      ),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  const _TopIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: context.isDarkMode
                ? colors.surfaceHigh
                : Colors.white.withValues(alpha: 0.75),
            shape: BoxShape.circle,
            border: Border.all(
              color: context.isDarkMode
                  ? colors.border
                  : ProfileConstants.surfaceBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.shadow,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: colors.textPrimary, size: 20),
        ),
      ),
    );
  }
}
