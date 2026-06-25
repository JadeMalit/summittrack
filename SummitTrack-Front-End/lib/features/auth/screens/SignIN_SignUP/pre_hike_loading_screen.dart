import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _preHikeLogoAsset = 'assets/images/logo.jpg';

class PreHikeLoginTransition {
  static bool isActive = false;

  static void start() {
    isActive = true;
  }

  static void finish() {
    isActive = false;
  }
}

class PreHikeLoadingScreen extends StatefulWidget {
  const PreHikeLoadingScreen({
    super.key,
    required this.loginFuture,
    required this.nextRoute,
    this.minimumDuration = const Duration(milliseconds: 2600),
  });

  final Future<void> loginFuture;
  final String nextRoute;
  final Duration minimumDuration;

  @override
  State<PreHikeLoadingScreen> createState() => _PreHikeLoadingScreenState();
}

class _PreHikeLoadingScreenState extends State<PreHikeLoadingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _loopController;
  late final AnimationController _introController;
  late final Animation<double> _introAnimation;
  late final Animation<double> _introScaleAnimation;
  bool _transitionFinished = false;

  @override
  void initState() {
    super.initState();

    _loopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _introAnimation = CurvedAnimation(
      parent: _introController,
      curve: Curves.easeOutCubic,
    );
    _introScaleAnimation = Tween<double>(
      begin: 0.96,
      end: 1,
    ).animate(_introAnimation);

    _completeLoginFlow();
  }

  @override
  void dispose() {
    _finishTransition();
    _loopController.dispose();
    _introController.dispose();
    super.dispose();
  }

  Future<void> _completeLoginFlow() async {
    final stopwatch = Stopwatch()..start();

    try {
      await widget.loginFuture;

      final remainingDuration = widget.minimumDuration - stopwatch.elapsed;
      if (remainingDuration > Duration.zero) {
        await Future<void>.delayed(remainingDuration);
      }

      if (!mounted) {
        return;
      }

      _finishTransition();
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(widget.nextRoute, (route) => false);
    } catch (error) {
      if (!mounted) {
        return;
      }

      _finishTransition();
      Navigator.of(context).pop(error);
    }
  }

  void _finishTransition() {
    if (_transitionFinished) {
      return;
    }

    _transitionFinished = true;
    PreHikeLoginTransition.finish();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF06140F),
                Color(0xFF123C2B),
                Color(0xFF1F5A34),
                Color(0xFF8A6A37),
              ],
              stops: [0, 0.48, 0.78, 1],
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _loopController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _PreHikeBackdropPainter(
                        progress: _loopController.value,
                      ),
                    );
                  },
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.18),
                      radius: 0.88,
                      colors: [
                        const Color(0xFFF4D45F).withValues(alpha: 0.18),
                        const Color(0xFF102C20).withValues(alpha: 0.18),
                        const Color(0xFF06140F).withValues(alpha: 0.64),
                      ],
                      stops: const [0, 0.44, 1],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final shortestSide = math.min(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    );
                    final compact = shortestSide < 380;
                    final logoWidth = shortestSide
                        .clamp(190.0, 290.0)
                        .toDouble();
                    final trailWidth = math
                        .min(constraints.maxWidth - 48, 460)
                        .clamp(250.0, 460.0)
                        .toDouble();

                    return Center(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: compact ? 20 : 28,
                          vertical: compact ? 22 : 30,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: FadeTransition(
                            opacity: _introAnimation,
                            child: ScaleTransition(
                              scale: _introScaleAnimation,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedBuilder(
                                    animation: _loopController,
                                    builder: (context, _) {
                                      return _AnimatedLogoMark(
                                        progress: _loopController.value,
                                        width: logoWidth,
                                      );
                                    },
                                  ),
                                  SizedBox(height: compact ? 18 : 24),
                                  _PreHikeTitle(compact: compact),
                                  SizedBox(height: compact ? 8 : 10),
                                  Text(
                                    'Getting your trail ready...',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      color: const Color(
                                        0xFFEFE5C9,
                                      ).withValues(alpha: 0.94),
                                      fontSize: compact ? 15 : 17,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0,
                                    ),
                                  ),
                                  SizedBox(height: compact ? 22 : 30),
                                  SizedBox(
                                    width: trailWidth,
                                    height: compact ? 86 : 104,
                                    child: AnimatedBuilder(
                                      animation: _loopController,
                                      builder: (context, _) {
                                        return CustomPaint(
                                          painter: _TrailLoadingPainter(
                                            progress: _loopController.value,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  SizedBox(height: compact ? 18 : 22),
                                  AnimatedBuilder(
                                    animation: _loopController,
                                    builder: (context, _) {
                                      return _SoftLoadingBar(
                                        progress: _loopController.value,
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
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedLogoMark extends StatelessWidget {
  const _AnimatedLogoMark({required this.progress, required this.width});

  final double progress;
  final double width;

  @override
  Widget build(BuildContext context) {
    final breath = math.sin(progress * math.pi * 2);
    final float = math.sin(progress * math.pi * 2 + math.pi / 3);
    final glow = 0.55 + (breath + 1) * 0.14;
    final imageHeight = width * 0.62;

    return Transform.translate(
      offset: Offset(0, float * -7),
      child: Transform.scale(
        scale: 1 + breath * 0.018,
        child: SizedBox(
          width: width * 1.12,
          height: imageHeight * 1.38,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: width * 1.02,
                height: width * 1.02,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFF6D65E).withValues(alpha: glow * 0.34),
                      const Color(0xFF69A758).withValues(alpha: glow * 0.18),
                      Colors.transparent,
                    ],
                    stops: const [0, 0.43, 1],
                  ),
                ),
              ),
              Container(
                width: width * 0.86,
                height: width * 0.86,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFF4D45F).withValues(alpha: 0.18),
                    width: 1.2,
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: const Color(
                        0xFFF4D45F,
                      ).withValues(alpha: 0.14 + glow * 0.08),
                      blurRadius: 36,
                      spreadRadius: 4,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.38),
                      blurRadius: 28,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: Image.asset(
                  _preHikeLogoAsset,
                  width: width,
                  height: imageHeight,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreHikeTitle extends StatelessWidget {
  const _PreHikeTitle({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFE58A), Color(0xFFFFF5D3), Color(0xFF91D66F)],
          ).createShader(bounds),
          child: Text(
            'Pre-Hike',
            textAlign: TextAlign.center,
            style: GoogleFonts.raleway(
              color: Colors.white,
              fontSize: compact ? 42 : 54,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
              height: 1,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: compact ? 86 : 112,
          height: 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: const LinearGradient(
              colors: [Color(0xFF91D66F), Color(0xFFFFD55B), Color(0xFFB98745)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD55B).withValues(alpha: 0.24),
                blurRadius: 16,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SoftLoadingBar extends StatelessWidget {
  const _SoftLoadingBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final shimmerOffset = (progress * 2 - 1).clamp(-1.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        width: 176,
        height: 7,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFE8DDBE).withValues(alpha: 0.20),
              ),
            ),
            Align(
              alignment: Alignment(shimmerOffset, 0),
              child: FractionallySizedBox(
                widthFactor: 0.38,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0x00000000),
                        Color(0xFFFFD55B),
                        Color(0xFF91D66F),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreHikeBackdropPainter extends CustomPainter {
  _PreHikeBackdropPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    _drawAmbientLights(canvas, size);
    _drawStars(canvas, size);
    _drawMountainLayers(canvas, size);
    _drawGroundMist(canvas, size);
  }

  void _drawAmbientLights(Canvas canvas, Size size) {
    final goldGlow = Paint()
      ..color = const Color(0xFFFFD55B).withValues(alpha: 0.13)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);
    canvas.drawCircle(
      Offset(size.width * (0.5 + math.sin(progress * math.pi * 2) * 0.03), 0),
      size.shortestSide * 0.38,
      goldGlow,
    );

    final greenGlow = Paint()
      ..color = const Color(0xFF83BF5C).withValues(alpha: 0.10)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 74);
    canvas.drawCircle(
      Offset(size.width * 0.18, size.height * 0.32),
      size.shortestSide * 0.28,
      greenGlow,
    );
  }

  void _drawStars(Canvas canvas, Size size) {
    final starPaint = Paint()..color = const Color(0xFFFFE58A);
    const stars = [
      Offset(0.16, 0.11),
      Offset(0.29, 0.17),
      Offset(0.72, 0.12),
      Offset(0.84, 0.22),
      Offset(0.63, 0.27),
    ];

    for (var i = 0; i < stars.length; i++) {
      final twinkle = 0.44 + math.sin(progress * math.pi * 2 + i * 1.7) * 0.18;
      final center = Offset(
        stars[i].dx * size.width,
        stars[i].dy * size.height,
      );
      final radius = size.shortestSide * (0.0048 + i * 0.0006);
      starPaint.color = const Color(
        0xFFFFE58A,
      ).withValues(alpha: twinkle.clamp(0.2, 0.72));
      _drawFourPointStar(canvas, center, radius, starPaint);
    }
  }

  void _drawFourPointStar(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
  ) {
    final path = Path()
      ..moveTo(center.dx, center.dy - radius * 2.4)
      ..lineTo(center.dx + radius * 0.48, center.dy - radius * 0.48)
      ..lineTo(center.dx + radius * 2.4, center.dy)
      ..lineTo(center.dx + radius * 0.48, center.dy + radius * 0.48)
      ..lineTo(center.dx, center.dy + radius * 2.4)
      ..lineTo(center.dx - radius * 0.48, center.dy + radius * 0.48)
      ..lineTo(center.dx - radius * 2.4, center.dy)
      ..lineTo(center.dx - radius * 0.48, center.dy - radius * 0.48)
      ..close();

    canvas.drawPath(path, paint);
  }

  void _drawMountainLayers(Canvas canvas, Size size) {
    final farMountain = Path()
      ..moveTo(-size.width * 0.12, size.height * 0.82)
      ..lineTo(size.width * 0.18, size.height * 0.50)
      ..lineTo(size.width * 0.42, size.height * 0.80)
      ..lineTo(size.width * 0.62, size.height * 0.42)
      ..lineTo(size.width * 1.14, size.height * 0.84)
      ..lineTo(size.width * 1.14, size.height)
      ..lineTo(-size.width * 0.12, size.height)
      ..close();

    canvas.drawPath(
      farMountain,
      Paint()..color = const Color(0xFF204D36).withValues(alpha: 0.58),
    );

    final nearMountain = Path()
      ..moveTo(-size.width * 0.10, size.height)
      ..lineTo(size.width * 0.18, size.height * 0.72)
      ..lineTo(size.width * 0.37, size.height * 0.92)
      ..lineTo(size.width * 0.57, size.height * 0.60)
      ..lineTo(size.width * 0.83, size.height * 0.88)
      ..lineTo(size.width * 1.12, size.height * 0.68)
      ..lineTo(size.width * 1.12, size.height)
      ..close();

    canvas.drawPath(
      nearMountain,
      Paint()..color = const Color(0xFF082018).withValues(alpha: 0.72),
    );
  }

  void _drawGroundMist(Canvas canvas, Size size) {
    final mistPaint = Paint()
      ..shader =
          LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              const Color(0xFFE8DDBE).withValues(alpha: 0.07),
            ],
          ).createShader(
            Rect.fromLTWH(
              0,
              size.height * 0.55,
              size.width,
              size.height * 0.45,
            ),
          );

    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.55, size.width, size.height * 0.45),
      mistPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _PreHikeBackdropPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _TrailLoadingPainter extends CustomPainter {
  _TrailLoadingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final trail = _trailPath(size);
    final metric = trail.computeMetrics().first;
    final pulse = math.sin(progress * math.pi * 2);

    final glowPaint = Paint()
      ..color = const Color(
        0xFFFFD55B,
      ).withValues(alpha: 0.12 + pulse.abs() * 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height * 0.18
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawPath(trail, glowPaint);

    final basePaint = Paint()
      ..color = const Color(0xFFDDC389).withValues(alpha: 0.34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height * 0.055
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(trail, basePaint);

    _drawAnimatedTrailDashes(canvas, metric, size);
    _drawSummitFlag(canvas, size);
    _drawHiker(canvas, metric, size);
  }

  Path _trailPath(Size size) {
    return Path()
      ..moveTo(size.width * 0.08, size.height * 0.78)
      ..cubicTo(
        size.width * 0.24,
        size.height * 0.92,
        size.width * 0.35,
        size.height * 0.45,
        size.width * 0.50,
        size.height * 0.58,
      )
      ..cubicTo(
        size.width * 0.62,
        size.height * 0.68,
        size.width * 0.68,
        size.height * 0.18,
        size.width * 0.91,
        size.height * 0.27,
      );
  }

  void _drawAnimatedTrailDashes(Canvas canvas, PathMetric metric, Size size) {
    final dashLength = size.width * 0.055;
    final gap = size.width * 0.04;
    final shift = progress * (dashLength + gap);
    final dashPaint = Paint()
      ..color = const Color(0xFFFFE58A).withValues(alpha: 0.92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height * 0.035
      ..strokeCap = StrokeCap.round;

    for (
      var distance = -shift;
      distance < metric.length;
      distance += dashLength + gap
    ) {
      final start = distance.clamp(0.0, metric.length);
      final end = (distance + dashLength).clamp(0.0, metric.length);
      if (end > start) {
        canvas.drawPath(metric.extractPath(start, end), dashPaint);
      }
    }
  }

  void _drawSummitFlag(Canvas canvas, Size size) {
    final flagBase = Offset(size.width * 0.91, size.height * 0.27);
    final polePaint = Paint()
      ..color = const Color(0xFFEFE5C9).withValues(alpha: 0.85)
      ..strokeWidth = size.height * 0.018
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      flagBase + Offset(0, size.height * 0.13),
      flagBase + Offset(0, -size.height * 0.10),
      polePaint,
    );

    final flag = Path()
      ..moveTo(flagBase.dx, flagBase.dy - size.height * 0.10)
      ..lineTo(
        flagBase.dx + size.width * 0.055,
        flagBase.dy - size.height * 0.06,
      )
      ..lineTo(flagBase.dx, flagBase.dy - size.height * 0.025)
      ..close();

    canvas.drawPath(flag, Paint()..color = const Color(0xFFFFD55B));
  }

  void _drawHiker(Canvas canvas, PathMetric metric, Size size) {
    final easedProgress = Curves.easeInOutSine.transform(progress);
    final tangent = metric.getTangentForOffset(metric.length * easedProgress);
    if (tangent == null) {
      return;
    }

    final step = math.sin(progress * math.pi * 8);
    final scale = size.height * 0.22;
    final bodyPaint = Paint()
      ..color = const Color(0xFF2D1F15)
      ..strokeWidth = scale * 0.12
      ..strokeCap = StrokeCap.round;
    final shirtPaint = Paint()
      ..color = const Color(0xFFD9A441)
      ..strokeWidth = scale * 0.18
      ..strokeCap = StrokeCap.round;
    final bootPaint = Paint()
      ..color = const Color(0xFF10291E)
      ..strokeWidth = scale * 0.14
      ..strokeCap = StrokeCap.round;
    final polePaint = Paint()
      ..color = const Color(0xFFE8DDBE).withValues(alpha: 0.9)
      ..strokeWidth = scale * 0.045
      ..strokeCap = StrokeCap.round;

    canvas.save();
    canvas.translate(tangent.position.dx, tangent.position.dy - scale * 0.12);
    canvas.rotate(tangent.angle + math.pi / 10);

    canvas.drawCircle(
      Offset(0, -scale * 0.72),
      scale * 0.18,
      Paint()..color = const Color(0xFFE0B176),
    );
    canvas.drawLine(
      Offset(-scale * 0.03, -scale * 0.48),
      Offset(scale * 0.03, scale * 0.02),
      shirtPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-scale * 0.22, -scale * 0.28),
        width: scale * 0.34,
        height: scale * 0.46,
      ),
      Paint()..color = const Color(0xFF2C6539),
    );
    canvas.drawLine(
      Offset(scale * 0.03, -scale * 0.24),
      Offset(scale * (0.32 + step * 0.05), scale * 0.04),
      bodyPaint,
    );
    canvas.drawLine(
      Offset(scale * (0.32 + step * 0.05), scale * 0.04),
      Offset(scale * 0.50, scale * 0.62),
      polePaint,
    );
    canvas.drawLine(
      Offset(0, scale * 0.04),
      Offset(scale * (0.25 + step * 0.06), scale * 0.48),
      bootPaint,
    );
    canvas.drawLine(
      Offset(0, scale * 0.04),
      Offset(-scale * (0.25 - step * 0.06), scale * 0.44),
      bootPaint,
    );
    canvas.drawLine(
      Offset(scale * (0.25 + step * 0.06), scale * 0.48),
      Offset(scale * (0.43 + step * 0.06), scale * 0.48),
      bootPaint,
    );
    canvas.drawLine(
      Offset(-scale * (0.25 - step * 0.06), scale * 0.44),
      Offset(-scale * (0.43 - step * 0.06), scale * 0.44),
      bootPaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TrailLoadingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
