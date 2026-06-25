import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class ProfileActionButtons extends StatelessWidget {
  const ProfileActionButtons({super.key, required this.onLogout});

  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: ProfileLogoutButton(onPressed: onLogout),
    );
  }
}

class ProfileLogoutButton extends StatelessWidget {
  const ProfileLogoutButton({super.key, required this.onPressed});

  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await onPressed();
        },
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [colors.primary, colors.primaryPressed],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: colors.shadow,
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.logout_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'Log Out',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
