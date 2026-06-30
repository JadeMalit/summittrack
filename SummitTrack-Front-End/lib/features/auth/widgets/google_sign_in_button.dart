import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.text = 'Continue with Google',
  });

  final VoidCallback? onPressed;
  final bool isLoading;
  final String text;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isEnabled ? 0.18 : 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: OutlinedButton(
          onPressed: isEnabled ? onPressed : null,
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.96),
            disabledBackgroundColor: Colors.white.withValues(alpha: 0.82),
            foregroundColor: const Color(0xFF202124),
            disabledForegroundColor: const Color(0xFF6A6A6A),
            side: BorderSide(
              color: const Color(0xFFE1E9D9).withValues(alpha: 0.95),
              width: 1.4,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: isLoading
                ? const SizedBox(
                    key: ValueKey('google-loading'),
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Color(0xFF4CAF50),
                    ),
                  )
                : Row(
                    key: const ValueKey('google-content'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const GoogleLogo(size: 22),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                          ),
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

class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, this.size = 24});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  static const _blue = Color(0xFF4285F4);
  static const _red = Color(0xFFEA4335);
  static const _yellow = Color(0xFFFBBC05);
  static const _green = Color(0xFF34A853);

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.shortestSide * 0.16;
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    void drawArc(double startDegrees, double sweepDegrees, Color color) {
      paint.color = color;
      canvas.drawArc(
        rect,
        startDegrees * math.pi / 180,
        sweepDegrees * math.pi / 180,
        false,
        paint,
      );
    }

    drawArc(-38, 82, _blue);
    drawArc(44, 74, _green);
    drawArc(118, 72, _yellow);
    drawArc(190, 104, _red);

    paint
      ..color = _blue
      ..strokeCap = StrokeCap.square;
    canvas.drawLine(
      Offset(size.width * 0.52, size.height * 0.50),
      Offset(size.width * 0.88, size.height * 0.50),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _GoogleLogoPainter oldDelegate) => false;
}
