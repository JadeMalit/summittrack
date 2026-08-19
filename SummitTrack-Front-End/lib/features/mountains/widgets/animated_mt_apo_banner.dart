import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/layout/app_responsive.dart';

class AnimatedMtApoBanner extends StatefulWidget {
  const AnimatedMtApoBanner({
    super.key,
    required this.imageAsset,
    required this.title,
    this.height = _defaultHeight,
    this.borderRadius = 30,
  });

  static const double _defaultHeight = 245;

  final String imageAsset;
  final String title;
  final double height;
  final double borderRadius;

  @override
  State<AnimatedMtApoBanner> createState() => _AnimatedMtApoBannerState();
}

class _AnimatedMtApoBannerState extends State<AnimatedMtApoBanner>
    with TickerProviderStateMixin {
  late final AnimationController _loopController;
  late final AnimationController _introController;

  @override
  void initState() {
    super.initState();
    _loopController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _loopController.dispose();
    _introController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_loopController, _introController]),
        builder: (context, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final loopT = _loopController.value;
              final introT = Curves.easeOutCubic.transform(
                _introController.value,
              );
              final breathing = math.sin(loopT * math.pi * 2);
              final drift = math.sin(loopT * math.pi * 2 * 0.72 + 1.1);
              final sweep = (math.sin(loopT * math.pi * 2 - 0.4) + 1.0) / 2.0;
              final imageScale = 1.045 + (0.024 * breathing);
              final imageDx = 7.0 * drift;
              final imageDy = 4.5 * math.sin(loopT * math.pi * 2 * 0.58 + 0.8);
              final titleOpacity = introT;
              final titleOffsetDy = 18.0 * (1.0 - introT);
              final titleScale = 0.98 + (0.02 * introT);
              final pulse = 0.5 + (0.5 * math.sin(loopT * math.pi * 2 * 0.9));
              final titleFontSize = (width * 0.102)
                  .clamp(30.0, 44.0)
                  .toDouble();
              final glowBlur = 10.0 + (10.0 * pulse);
              final glowAlpha = 0.22 + (0.10 * pulse);
              final bannerHeight =
                  widget.height == AnimatedMtApoBanner._defaultHeight
                  ? AppResponsive.clampedWidthHeight(
                      width,
                      ratio: 0.68,
                      min: 205,
                      max: AnimatedMtApoBanner._defaultHeight,
                    )
                  : widget.height;

              return ClipRRect(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: bannerHeight,
                      width: double.infinity,
                      child: Transform.translate(
                        offset: Offset(imageDx, imageDy),
                        child: Transform.scale(
                          scale: imageScale,
                          child: Image.asset(
                            widget.imageAsset,
                            fit: BoxFit.cover,
                            alignment: const Alignment(0, -0.08),
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              const Color(0x06161F10),
                              const Color(0x1A14250D),
                              const Color(0x4A101B0A),
                              const Color(0x84071006),
                            ],
                            stops: const [0.0, 0.45, 0.78, 1.0],
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Stack(
                          children: [
                            Positioned(
                              left: -45 + (18 * drift),
                              bottom: 10 + (4 * math.sin(loopT * math.pi * 2)),
                              child: Opacity(
                                opacity: 0.16 + (0.04 * sweep),
                                child: _MistCloud(
                                  width: width * 0.48,
                                  height: bannerHeight * 0.18,
                                  tint: const Color(0xFFF4FFF1),
                                ),
                              ),
                            ),
                            Positioned(
                              right:
                                  -55 +
                                  (14 * math.sin(loopT * math.pi * 2 * 0.64)),
                              bottom: 0,
                              child: Opacity(
                                opacity: 0.13 + (0.03 * (1.0 - sweep)),
                                child: _MistCloud(
                                  width: width * 0.42,
                                  height: bannerHeight * 0.15,
                                  tint: const Color(0xFFE8F6E1),
                                ),
                              ),
                            ),
                            Positioned(
                              left: width * 0.18 + (width * 0.08 * sweep),
                              top: 18,
                              child: Opacity(
                                opacity: 0.10,
                                child: _LightOrb(
                                  size: width * 0.24,
                                  tint: const Color(0x66DFF6C9),
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: Opacity(
                                opacity: 0.18,
                                child: Transform.translate(
                                  offset: Offset(
                                    -width * 0.35 + (width * 1.1 * sweep),
                                    -22,
                                  ),
                                  child: Transform.rotate(
                                    angle: -0.33,
                                    child: Container(
                                      width: width * 0.48,
                                      height: bannerHeight * 0.92,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.transparent,
                                            const Color(0x30F3FFE7),
                                            Colors.white.withValues(
                                              alpha: 0.16,
                                            ),
                                            const Color(0x1AF4FFF1),
                                            Colors.transparent,
                                          ],
                                          stops: const [
                                            0.0,
                                            0.38,
                                            0.50,
                                            0.62,
                                            1.0,
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 18,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Transform.translate(
                          offset: Offset(0, titleOffsetDy),
                          child: Opacity(
                            opacity: titleOpacity,
                            child: Transform.scale(
                              scale: titleScale,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Text(
                                    widget.title,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.lilitaOne(
                                      fontSize: titleFontSize,
                                      color: const Color(0xFFBDE7B2),
                                      letterSpacing: 1.1,
                                      shadows: [
                                        Shadow(
                                          color: const Color(
                                            0xFF2E6B2A,
                                          ).withValues(alpha: glowAlpha),
                                          blurRadius: glowBlur,
                                          offset: const Offset(0, 0),
                                        ),
                                        Shadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.55,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    widget.title,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.lilitaOne(
                                      fontSize: titleFontSize,
                                      color: Colors.white,
                                      letterSpacing: 1.1,
                                      shadows: [
                                        Shadow(
                                          color: const Color(0xFF11320E)
                                              .withValues(
                                                alpha: 0.40 + (0.10 * pulse),
                                              ),
                                          blurRadius: 14 + (4 * pulse),
                                          offset: const Offset(0, 2),
                                        ),
                                        Shadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.72,
                                          ),
                                          blurRadius: 4,
                                          offset: const Offset(1.2, 1.2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _MistCloud extends StatelessWidget {
  const _MistCloud({
    required this.width,
    required this.height,
    required this.tint,
  });

  final double width;
  final double height;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: RadialGradient(
          colors: [
            tint.withValues(alpha: 0.28),
            tint.withValues(alpha: 0.14),
            Colors.transparent,
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
    );
  }
}

class _LightOrb extends StatelessWidget {
  const _LightOrb({required this.size, required this.tint});

  final double size;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [tint, tint.withValues(alpha: 0.14), Colors.transparent],
          stops: const [0.0, 0.42, 1.0],
        ),
      ),
    );
  }
}
