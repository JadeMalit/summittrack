import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/trail_data/trail_data.dart';

class FoldableTrailChecklistCard extends StatefulWidget {
  const FoldableTrailChecklistCard({super.key, required this.trail});

  final TrailData trail;

  @override
  State<FoldableTrailChecklistCard> createState() =>
      _FoldableTrailChecklistCardState();
}

class _FoldableTrailChecklistCardState extends State<FoldableTrailChecklistCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;
  late final Animation<double> _fade;

  bool _isChecklistOpen = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
      reverseDuration: const Duration(milliseconds: 620),
      value: 1.0,
    );
    _progress = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.1, 1.0, curve: Curves.easeOutCubic),
      reverseCurve: const Interval(0.0, 0.9, curve: Curves.easeInCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleChecklist() {
    setState(() {
      _isChecklistOpen = !_isChecklistOpen;
    });

    if (_isChecklistOpen) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final foldLift = 10 * (1 - _progress.value);
        final foldScale = 0.97 + (0.03 * _progress.value);

        return ClipPath(
          clipper: _ChecklistCardClipper(),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.isDarkMode
                  ? colors.surface
                  : Colors.white.withValues(alpha: 0.92),
              border: Border.all(
                color: context.isDarkMode
                    ? colors.border
                    : const Color(0xFFCFC8BB),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRect(
                  child: Align(
                    alignment: Alignment.topCenter,
                    heightFactor: _progress.value,
                    child: FadeTransition(
                      opacity: _fade,
                      child: Transform.translate(
                        offset: Offset(0, foldLift),
                        child: Transform.scale(
                          scale: foldScale,
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                            child: _ChecklistContent(trail: widget.trail),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 18),
                  color: context.isDarkMode
                      ? colors.divider
                      : const Color(0xFFDDD7C8).withValues(alpha: 0.85),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _toggleChecklist,
                    splashColor: colors.accent.withValues(alpha: 0.08),
                    highlightColor: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
                      child: Row(
                        children: [
                          Expanded(
                            child: AnimatedOpacity(
                              opacity: _isChecklistOpen ? 0.88 : 1.0,
                              duration: const Duration(milliseconds: 180),
                              child: Text(
                                _isChecklistOpen
                                    ? 'Tap to fold'
                                    : 'Tap to open',
                                style: GoogleFonts.fredoka(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                          AnimatedRotation(
                            turns: _isChecklistOpen ? 0.0 : 0.5,
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeInOutCubic,
                            child: Icon(
                              Icons.keyboard_arrow_up_rounded,
                              color: colors.textSecondary,
                              size: 26,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ChecklistContent extends StatelessWidget {
  const _ChecklistContent({required this.trail});

  final TrailData trail;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Before the hike, bring/prepare:',
          style: GoogleFonts.fredoka(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _ChecklistGroup(items: trail.preparationItems),
        const SizedBox(height: 12),
        Text(
          'Essential things to bring:',
          style: GoogleFonts.fredoka(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        _ChecklistGroup(items: trail.essentialItems),
        if (trail.overnightItems.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'If your hike is overnight or 3D2N, also bring:',
            style: GoogleFonts.fredoka(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          _ChecklistGroup(items: trail.overnightItems),
        ],
      ],
    );
  }
}

class _ChecklistGroup extends StatelessWidget {
  const _ChecklistGroup({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: colors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: GoogleFonts.merriweather(
                        fontSize: 13,
                        height: 1.45,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ChecklistCardClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const radius = 22.0;
    const pointDepth = 28.0;
    const sideCurve = 18.0;
    final pointWidth = size.width * 0.22;
    final centerX = size.width / 2;
    final bodyBottom = size.height - pointDepth;

    final path = Path()
      ..moveTo(0, radius)
      ..quadraticBezierTo(0, 0, radius, 0)
      ..lineTo(size.width - radius, 0)
      ..quadraticBezierTo(size.width, 0, size.width, radius)
      ..lineTo(size.width, bodyBottom - sideCurve)
      ..quadraticBezierTo(
        size.width,
        bodyBottom,
        size.width - sideCurve,
        bodyBottom,
      )
      ..lineTo(centerX + pointWidth / 2, bodyBottom)
      ..lineTo(centerX, size.height)
      ..lineTo(centerX - pointWidth / 2, bodyBottom)
      ..lineTo(sideCurve, bodyBottom)
      ..quadraticBezierTo(0, bodyBottom, 0, bodyBottom - sideCurve)
      ..close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
