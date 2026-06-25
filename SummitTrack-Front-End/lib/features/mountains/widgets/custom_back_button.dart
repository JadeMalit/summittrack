import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';

class CustomBackButton extends StatefulWidget {
  const CustomBackButton({
    super.key,
    required this.onTap,
    this.label = 'Back',
    this.icon = Icons.arrow_back_rounded,
  });

  final VoidCallback onTap;
  final String label;
  final IconData icon;

  @override
  State<CustomBackButton> createState() => _CustomBackButtonState();
}

class _CustomBackButtonState extends State<CustomBackButton> {
  bool _isPressed = false;
  bool _isHovered = false;

  void _setPressed(bool value) {
    if (_isPressed == value) return;
    setState(() => _isPressed = value);
  }

  void _setHovered(bool value) {
    if (_isHovered == value) return;
    setState(() => _isHovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final shadowStrength = _isPressed ? 0.10 : (_isHovered ? 0.22 : 0.16);
    final offsetY = _isPressed ? 1.5 : (_isHovered ? 3.5 : 2.5);

    return Semantics(
      button: true,
      label: widget.label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => _setHovered(true),
        onExit: (_) => _setHovered(false),
        child: Align(
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 110),
              curve: Curves.easeOutCubic,
              scale: _isPressed ? 0.97 : 1.0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 140),
                opacity: _isPressed ? 0.95 : 1.0,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onTap,
                    onHighlightChanged: _setPressed,
                    borderRadius: BorderRadius.circular(18),
                    splashColor: const Color(0x223D6B33),
                    highlightColor: const Color(0x113D6B33),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 54),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colors.danger,
                            colors.danger.withValues(alpha: 0.90),
                            colors.danger.withValues(alpha: 0.62),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: colors.border.withValues(alpha: 0.55),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colors.shadow.withValues(
                              alpha: shadowStrength,
                            ),
                            blurRadius: _isHovered ? 16 : 12,
                            offset: Offset(0, offsetY),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.icon,
                            size: 20,
                            color: const Color(0xFFF3F1E8),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.label,
                            style: GoogleFonts.fredoka(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                              color: const Color(0xFFF3F1E8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
