import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

enum ConnectionTransitionAction { stayOffline, goOnline, stayOnline, goOffline }

class ConnectionTransitionModal extends StatelessWidget {
  const ConnectionTransitionModal({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.secondaryLabel,
    required this.secondaryAction,
    required this.primaryLabel,
    required this.primaryAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String secondaryLabel;
  final ConnectionTransitionAction secondaryAction;
  final String primaryLabel;
  final ConnectionTransitionAction primaryAction;

  static Future<ConnectionTransitionAction?> showInternetRestored(
    BuildContext context,
  ) {
    return showDialog<ConnectionTransitionAction>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) {
        return const ConnectionTransitionModal(
          icon: Icons.wifi_rounded,
          title: 'Internet Connection Restored',
          message:
              'You are now connected to the internet. Do you want to continue using Offline Mode or go back Online?',
          secondaryLabel: 'Stay Offline',
          secondaryAction: ConnectionTransitionAction.stayOffline,
          primaryLabel: 'Go Online',
          primaryAction: ConnectionTransitionAction.goOnline,
        );
      },
    );
  }

  static Future<ConnectionTransitionAction?> showInternetLost(
    BuildContext context,
  ) {
    return showDialog<ConnectionTransitionAction>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) {
        return const ConnectionTransitionModal(
          icon: Icons.wifi_off_rounded,
          title: 'Internet Connection Lost',
          message:
              'Your internet connection was lost. Do you want to wait for the connection or switch to Offline Mode?',
          secondaryLabel: 'Stay Online',
          secondaryAction: ConnectionTransitionAction.stayOnline,
          primaryLabel: 'Go Offline',
          primaryAction: ConnectionTransitionAction.goOffline,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colors.border),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withValues(alpha: 0.9),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: colors.surfaceMuted,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colors.accent.withValues(alpha: 0.14),
                          ),
                        ),
                        child: Icon(icon, color: colors.accent, size: 25),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.poppins(
                            color: colors.textPrimary,
                            fontSize: 19,
                            height: 1.18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: GoogleFonts.poppins(
                      color: colors.textSecondary,
                      fontSize: 14,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 22),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 330;
                      final buttons = [
                        _TransitionButton(
                          label: secondaryLabel,
                          action: secondaryAction,
                          isPrimary: false,
                          foreground: colors.accent,
                          background: colors.surface,
                          border: colors.accent.withValues(alpha: 0.24),
                        ),
                        _TransitionButton(
                          label: primaryLabel,
                          action: primaryAction,
                          isPrimary: true,
                          foreground: onPrimary,
                          background: colors.primary,
                          border: colors.primary,
                        ),
                      ];

                      if (compact) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            buttons[0],
                            const SizedBox(height: 10),
                            buttons[1],
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: buttons[0]),
                          const SizedBox(width: 12),
                          Expanded(child: buttons[1]),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ConnectionReconnectingDialog extends StatelessWidget {
  const ConnectionReconnectingDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 34, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colors.border),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withValues(alpha: 0.9),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      color: colors.accent,
                      strokeWidth: 4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Reconnecting',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: colors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Waiting for internet connection to return.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: colors.textSecondary,
                      fontSize: 13.5,
                      height: 1.42,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TransitionButton extends StatelessWidget {
  const _TransitionButton({
    required this.label,
    required this.action,
    required this.isPrimary,
    required this.foreground,
    required this.background,
    required this.border,
  });

  final String label;
  final ConnectionTransitionAction action;
  final bool isPrimary;
  final Color foreground;
  final Color background;
  final Color border;

  @override
  Widget build(BuildContext context) {
    final child = Text(
      label,
      textAlign: TextAlign.center,
      style: GoogleFonts.poppins(
        fontSize: 13.5,
        fontWeight: isPrimary ? FontWeight.w800 : FontWeight.w700,
      ),
    );

    if (isPrimary) {
      return ElevatedButton(
        onPressed: () => Navigator.of(
          context,
          rootNavigator: true,
        ).pop<ConnectionTransitionAction>(action),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: background,
          foregroundColor: foreground,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: child,
      );
    }

    return OutlinedButton(
      onPressed: () => Navigator.of(
        context,
        rootNavigator: true,
      ).pop<ConnectionTransitionAction>(action),
      style: OutlinedButton.styleFrom(
        foregroundColor: foreground,
        side: BorderSide(color: border),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      child: child,
    );
  }
}
