import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

Future<bool> showLogoutConfirmationDialog(BuildContext context) async {
  final shouldLogout = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Logout confirmation',
    barrierColor: Colors.black.withValues(
      alpha: context.isDarkMode ? 0.68 : 0.38,
    ),
    builder: (context) {
      return const PopScope(canPop: false, child: _LogoutConfirmationDialog());
    },
  );

  return shouldLogout ?? false;
}

class _LogoutConfirmationDialog extends StatelessWidget {
  const _LogoutConfirmationDialog();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final highlightedSurface = Color.alphaBlend(
      colors.primary.withValues(alpha: context.isDarkMode ? 0.2 : 0.1),
      colors.surfaceHigh,
    );

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [highlightedSurface, colors.surface],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: colors.border),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow,
                      blurRadius: 24,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colors.accent.withValues(alpha: 0.32),
                        ),
                      ),
                      child: Icon(
                        Icons.logout_rounded,
                        color: colors.accent,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Confirm Logout',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Are you sure you want to log out?',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colors.textPrimary,
                              side: BorderSide(color: colors.border),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text(
                              'Log Out',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
