import 'package:flutter/material.dart';

class PageTransitionWrapper extends StatefulWidget {
  const PageTransitionWrapper({
    super.key,
    required this.currentIndex,
    required this.pages,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOutCubic,
    this.slideDistance = 0.08,
  });

  final int currentIndex;
  final Map<int, Widget> pages;
  final Duration duration;
  final Curve curve;
  final double slideDistance;

  @override
  State<PageTransitionWrapper> createState() => _PageTransitionWrapperState();
}

class _PageTransitionWrapperState extends State<PageTransitionWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late CurvedAnimation _animation;
  int? _previousIndex;
  int _slideDirection = 1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: 1,
    );
    _animation = CurvedAnimation(parent: _controller, curve: widget.curve);
    _controller.addStatusListener(_handleAnimationStatus);
  }

  @override
  void didUpdateWidget(covariant PageTransitionWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration;
    }

    if (widget.curve != oldWidget.curve) {
      _animation.dispose();
      _animation = CurvedAnimation(parent: _controller, curve: widget.curve);
    }

    if (widget.currentIndex == oldWidget.currentIndex) {
      return;
    }

    _previousIndex = widget.pages.containsKey(oldWidget.currentIndex)
        ? oldWidget.currentIndex
        : null;
    _slideDirection = widget.currentIndex > oldWidget.currentIndex ? 1 : -1;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_handleAnimationStatus);
    _animation.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || _previousIndex == null) {
      return;
    }

    setState(() {
      _previousIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentPage = widget.pages[widget.currentIndex];
    if (currentPage == null) {
      return const SizedBox.shrink();
    }

    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion) {
      return _buildStaticStack();
    }

    final previousIndex = _previousIndex;
    final previousPage = previousIndex == null
        ? null
        : widget.pages[previousIndex];

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          for (final entry in widget.pages.entries)
            if (entry.key != widget.currentIndex && entry.key != previousIndex)
              Offstage(
                offstage: true,
                child: TickerMode(enabled: false, child: entry.value),
              ),
          if (previousPage != null)
            Positioned.fill(
              child: IgnorePointer(
                child: TickerMode(
                  enabled: false,
                  child: _OutgoingPageTransition(
                    animation: _animation,
                    slideDirection: _slideDirection,
                    slideDistance: widget.slideDistance,
                    child: previousPage,
                  ),
                ),
              ),
            ),
          Positioned.fill(
            child: TickerMode(
              enabled: true,
              child: _IncomingPageTransition(
                animation: _animation,
                slideDirection: _slideDirection,
                slideDistance: widget.slideDistance,
                child: currentPage,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaticStack() {
    return Stack(
      fit: StackFit.expand,
      children: [
        for (final entry in widget.pages.entries)
          Offstage(
            offstage: entry.key != widget.currentIndex,
            child: TickerMode(
              enabled: entry.key == widget.currentIndex,
              child: entry.value,
            ),
          ),
      ],
    );
  }
}

class _IncomingPageTransition extends StatelessWidget {
  const _IncomingPageTransition({
    required this.animation,
    required this.slideDirection,
    required this.slideDistance,
    required this.child,
  });

  final Animation<double> animation;
  final int slideDirection;
  final double slideDistance;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final progress = animation.value;
        final offset = Offset(
          slideDirection * slideDistance * (1 - progress),
          0,
        );

        return FadeTransition(
          opacity: animation,
          child: FractionalTranslation(translation: offset, child: child),
        );
      },
    );
  }
}

class _OutgoingPageTransition extends StatelessWidget {
  const _OutgoingPageTransition({
    required this.animation,
    required this.slideDirection,
    required this.slideDistance,
    required this.child,
  });

  final Animation<double> animation;
  final int slideDirection;
  final double slideDistance;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final opacity = ReverseAnimation(animation);

    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final progress = animation.value;
        final offset = Offset(-slideDirection * slideDistance * progress, 0);

        return FadeTransition(
          opacity: opacity,
          child: FractionalTranslation(translation: offset, child: child),
        );
      },
    );
  }
}
