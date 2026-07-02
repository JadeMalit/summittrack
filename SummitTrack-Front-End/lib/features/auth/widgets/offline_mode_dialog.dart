import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum OfflineModeDialogAction { stayOnline, useOfflineMode }

class OfflineModeDialog extends StatefulWidget {
  const OfflineModeDialog({super.key, this.onStayOnline});

  final Future<bool> Function()? onStayOnline;

  static Future<OfflineModeDialogAction?> show(
    BuildContext context, {
    Future<bool> Function()? onStayOnline,
  }) {
    return showDialog<OfflineModeDialogAction>(
      context: context,
      barrierDismissible: false,
      builder: (_) => OfflineModeDialog(onStayOnline: onStayOnline),
    );
  }

  @override
  State<OfflineModeDialog> createState() => _OfflineModeDialogState();
}

class _OfflineModeDialogState extends State<OfflineModeDialog> {
  bool _checkingConnection = false;

  Future<void> _handleStayOnline() async {
    if (_checkingConnection) {
      return;
    }

    final onStayOnline = widget.onStayOnline;
    if (onStayOnline == null) {
      Navigator.of(context).pop(OfflineModeDialogAction.stayOnline);
      return;
    }

    setState(() {
      _checkingConnection = true;
    });

    final canClose = await onStayOnline();
    if (!mounted) {
      return;
    }

    if (canClose) {
      Navigator.of(context).pop(OfflineModeDialogAction.stayOnline);
      return;
    }

    setState(() {
      _checkingConnection = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.wifi_off_rounded,
              color: colorScheme.primary,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No Internet Connection',
              style: GoogleFonts.poppins(
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        'You are currently offline. You can stay on the sign-in page and wait for connection, or start a limited offline hike mode.',
        style: GoogleFonts.poppins(
          color: colorScheme.onSurface.withValues(alpha: 0.76),
          fontSize: 14,
          height: 1.45,
          fontWeight: FontWeight.w500,
        ),
      ),
      actions: [
        TextButton(
          onPressed: _handleStayOnline,
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.primary,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          child: _checkingConnection
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.primary,
                  ),
                )
              : Text(
                  'Stay Online',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                ),
        ),
        ElevatedButton(
          onPressed: _checkingConnection
              ? null
              : () {
                  Navigator.of(
                    context,
                  ).pop(OfflineModeDialogAction.useOfflineMode);
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            disabledBackgroundColor: colorScheme.primary.withValues(
              alpha: 0.58,
            ),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            'Use Offline Mode',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}
