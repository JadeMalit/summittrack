import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PreHikeHeaderCard extends StatefulWidget {
  const PreHikeHeaderCard({super.key});

  @override
  State<PreHikeHeaderCard> createState() => _PreHikeHeaderCardState();
}

class _PreHikeHeaderCardState extends State<PreHikeHeaderCard>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _ambientController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  bool _isHovered = false;
  bool _isPressed = false;

  static const Color _darkForest = Color(0xFF1B4332);
  static const Color _forest = Color(0xFF2D6A4F);
  static const Color _sage = Color(0xFF95D5B2);
  static const Color _cream = Color(0xFFF1F8F4);
  static const Color _earth = Color(0xFF8B6F47);
  static const BorderRadius _cardRadius = BorderRadius.all(Radius.circular(30));

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Curves.easeOutCubic,
          ),
        );
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  void _setHovered(bool value) {
    if (_isHovered == value || !mounted) {
      return;
    }
    setState(() {
      _isHovered = value;
    });
  }

  void _setPressed(bool value) {
    if (_isPressed == value || !mounted) {
      return;
    }
    setState(() {
      _isPressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final scale = _isPressed
        ? 0.985
        : _isHovered
        ? 1.01
        : 1.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, topInset + 16, 20, 0),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: MouseRegion(
            onEnter: (_) => _setHovered(true),
            onExit: (_) {
              _setHovered(false);
              _setPressed(false);
            },
            child: Listener(
              onPointerDown: (_) => _setPressed(true),
              onPointerUp: (_) => _setPressed(false),
              onPointerCancel: (_) => _setPressed(false),
              child: AnimatedScale(
                scale: scale,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: AnimatedBuilder(
                  animation: _ambientController,
                  builder: (context, child) {
                    final motion = Curves.easeInOut.transform(
                      _ambientController.value,
                    );
                    final iconFloat = lerpDouble(-3.5, 3.5, motion)!;
                    final shadowOpacity = _isHovered ? 0.22 : 0.15;

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 360;
                        final shimmerOffset = lerpDouble(
                          -constraints.maxWidth * 0.5,
                          constraints.maxWidth * 0.5,
                          motion,
                        )!;

                        return Container(
                          constraints: const BoxConstraints(minHeight: 198),
                          decoration: BoxDecoration(
                            borderRadius: _cardRadius,
                            boxShadow: [
                              BoxShadow(
                                color: _darkForest.withValues(
                                  alpha: shadowOpacity,
                                ),
                                blurRadius: _isHovered ? 30 : 24,
                                offset: const Offset(0, 16),
                              ),
                            ],
                            border: Border.all(
                              color: _cream.withValues(alpha: 0.16),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: _cardRadius,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: const [
                                          _darkForest,
                                          _forest,
                                          Color(0xFF5B7F65),
                                        ],
                                        stops: const [0.0, 0.58, 1.0],
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned.fill(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: RadialGradient(
                                        center: const Alignment(-0.85, -0.9),
                                        radius: 1.0,
                                        colors: [
                                          _cream.withValues(alpha: 0.18),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: -24,
                                  bottom: -36,
                                  child: IgnorePointer(
                                    child: Container(
                                      width: compact ? 132 : 164,
                                      height: compact ? 132 : 164,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _sage.withValues(alpha: 0.08),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: shimmerOffset,
                                  top: -18,
                                  bottom: -18,
                                  child: IgnorePointer(
                                    child: Opacity(
                                      opacity: 0.10,
                                      child: Transform.rotate(
                                        angle: -0.32,
                                        child: Container(
                                          width: compact ? 84 : 106,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Colors.transparent,
                                                _cream.withValues(alpha: 0.45),
                                                Colors.transparent,
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    compact ? 18 : 22,
                                    compact ? 18 : 22,
                                    compact ? 18 : 22,
                                    compact ? 18 : 22,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Transform.translate(
                                            offset: Offset(0, iconFloat),
                                            child: _MountainBadge(
                                              compact: compact,
                                            ),
                                          ),
                                          SizedBox(width: compact ? 14 : 18),
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                top: 2,
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    'Pre-Hike',
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: GoogleFonts.sora(
                                                      color: Colors.white,
                                                      fontSize: compact
                                                          ? 24
                                                          : 28,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      letterSpacing: -0.6,
                                                      height: 1.05,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    'Explore. Push your limit',
                                                    style: GoogleFonts.manrope(
                                                      color: _cream.withValues(
                                                        alpha: 0.88,
                                                      ),
                                                      fontSize: compact
                                                          ? 13.5
                                                          : 15,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      height: 1.3,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 18),
                                      Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: compact ? 14 : 16,
                                          vertical: compact ? 13 : 14,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _cream.withValues(alpha: 0.10),
                                          borderRadius: BorderRadius.circular(
                                            22,
                                          ),
                                          border: Border.all(
                                            color: _cream.withValues(
                                              alpha: 0.14,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 28,
                                              height: 28,
                                              decoration: BoxDecoration(
                                                color: _earth.withValues(
                                                  alpha: 0.22,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                              child: const Icon(
                                                Icons.explore_rounded,
                                                color: _cream,
                                                size: 15,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                'Plan your next summit with handpicked mountain guides.',
                                                style: GoogleFonts.manrope(
                                                  color: _cream.withValues(
                                                    alpha: 0.94,
                                                  ),
                                                  fontSize: compact
                                                      ? 12.8
                                                      : 13.8,
                                                  fontWeight: FontWeight.w600,
                                                  height: 1.45,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MountainBadge extends StatelessWidget {
  const _MountainBadge({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 60.0 : 70.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 20 : 24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.20),
            const Color(0xFF95D5B2).withValues(alpha: 0.12),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              Icons.terrain_rounded,
              color: Colors.white,
              size: compact ? 30 : 34,
            ),
          ),
          Positioned(
            right: 8,
            bottom: 8,
            child: Container(
              width: compact ? 17 : 19,
              height: compact ? 17 : 19,
              decoration: BoxDecoration(
                color: const Color(0xFF8B6F47),
                borderRadius: BorderRadius.circular(9.5),
                border: Border.all(color: Colors.white.withValues(alpha: 0.40)),
              ),
              child: Icon(
                Icons.navigation_rounded,
                color: const Color(0xFFF1F8F4),
                size: compact ? 10 : 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
