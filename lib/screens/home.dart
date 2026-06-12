import 'dart:async';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../ButtonFunction/navbar_button_function.dart';
import '../TrailData/mountain.dart';
import '../services/data_service.dart';
import 'mountain_screen_resolver.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color _darkGreen = Color(0xFF0B6623);
  static const Color _mediumGreen = Color(0xFF2E7D32);
  static const Color _lightGreen = Color(0xFFE8F5E9);
  static const Color _surface = Color(0xFFF9FCF8);
  static const Color _textPrimary = Color(0xFF182319);
  static const Color _textSecondary = Color(0xFF5C6B5D);

  int selectedIndex = homeNavbarIndex;
  int _navTapSequence = 0;
  int _lastTappedNavIndex = homeNavbarIndex;

  @override
  Widget build(BuildContext context) {
    final mountains = DataService.getMountains()
        .where(
          (mountain) =>
              mountain.name == 'Mt. Apo' || mountain.name == 'Mt. Pulag',
        )
        .toList();

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 238, 238, 238),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF1F8F1), Color(0xFFFFFFFF), Color(0xFFF7FBF7)],
          ),
        ),
        child: SafeArea(
          top: false,
          bottom: false,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _HeaderSection(
                  darkGreen: _darkGreen,
                  mediumGreen: _mediumGreen,
                  onLogout: () async {
                    await FirebaseAuth.instance.signOut();
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _StatsSection(
                    darkGreen: _darkGreen,
                    mediumGreen: _mediumGreen,
                    lightGreen: _lightGreen,
                    textPrimary: _textPrimary,
                    textSecondary: _textSecondary,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 18)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _SearchSection(
                    lightGreen: _lightGreen,
                    mediumGreen: _mediumGreen,
                    textSecondary: _textSecondary,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 26, 20, 14),
                  child: _SectionHeading(
                    title: 'Featured Mountains',
                    subtitle: 'Choose a peak and explore its trail details.',
                    darkGreen: _darkGreen,
                    textSecondary: _textSecondary,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == mountains.length - 1 ? 0 : 16,
                      ),
                      child: _MountainCard(
                        key: ValueKey(mountains[index].name),
                        index: index,
                        mountain: mountains[index],
                        darkGreen: _darkGreen,
                        mediumGreen: _mediumGreen,
                        lightGreen: _lightGreen,
                        textPrimary: _textPrimary,
                        textSecondary: _textSecondary,
                        onTap: () {
                          openMountainScreen(context, mountains[index]);
                        },
                      ),
                    );
                  }, childCount: mountains.length),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _HomeBottomNavigationBar(
        currentIndex: selectedIndex,
        tapSequence: _navTapSequence,
        lastTappedIndex: _lastTappedNavIndex,
        darkGreen: _darkGreen,
        onTap: (index) {
          setState(() {
            selectedIndex = index;
            _lastTappedNavIndex = index;
            _navTapSequence++;
          });

          handleNavbarButtonTap(
            context,
            index,
            onHomeSelected: () {
              if (!mounted) {
                return;
              }

              setState(() {
                selectedIndex = homeNavbarIndex;
                _lastTappedNavIndex = homeNavbarIndex;
              });
            },
            onWeatherSelected: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Weather screen is not available yet.'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _HeaderSection extends StatefulWidget {
  const _HeaderSection({
    required this.darkGreen,
    required this.mediumGreen,
    required this.onLogout,
  });

  final Color darkGreen;
  final Color mediumGreen;
  final Future<void> Function() onLogout;

  @override
  State<_HeaderSection> createState() => _HeaderSectionState();
}

class _HeaderSectionState extends State<_HeaderSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const _headerShape = BorderRadius.only(
    bottomLeft: Radius.circular(34),
    bottomRight: Radius.circular(34),
  );

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: _buildHeaderContent(),
      builder: (context, child) {
        final breath = Curves.easeInOut.transform(_controller.value);
        final topInset = MediaQuery.paddingOf(context).top;
        final pulseOpacity = lerpDouble(0.62, 1.0, breath)!;
        final highlightOpacity = lerpDouble(0.08, 0.18, breath)!;
        final animatedBegin = Alignment.lerp(
          const Alignment(-1.2, 0),
          const Alignment(-0.2, 0),
          breath,
        )!;
        final animatedEnd = Alignment.lerp(
          const Alignment(1.2, 0),
          const Alignment(0.2, 0),
          breath,
        )!;
        final softGradientColors = [
          Color.lerp(const Color(0xFF2EEA16), Colors.white, 0.28)!,
          Color.lerp(const Color(0xFF60D94D), Colors.white, 0.24)!,
          Color.lerp(const Color(0xFFA6DEA0), Colors.white, 0.14)!,
          Color.lerp(const Color(0xFFDDE6D8), Colors.white, 0.06)!,
        ];

        return Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 196),
          padding: EdgeInsets.fromLTRB(20, topInset + 18, 20, 24),
          decoration: BoxDecoration(
            borderRadius: _headerShape,
            boxShadow: [
              BoxShadow(
                color: widget.darkGreen.withValues(
                  alpha: lerpDouble(0.14, 0.22, breath)!,
                ),
                blurRadius: lerpDouble(18, 24, breath)!,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: _headerShape,
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: softGradientColors,
                        stops: const [0.0, 0.34, 0.72, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: pulseOpacity,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: animatedBegin,
                            end: animatedEnd,
                            colors: const [
                              Color(0xFF2EEA16),
                              Color(0xFF60D94D),
                              Color.fromARGB(255, 151, 221, 143),
                              Color.fromARGB(255, 219, 243, 207),
                            ],
                            stops: [0.0, 0.36, 0.74, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: highlightOpacity,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.lerp(
                              const Alignment(-1.1, -0.1),
                              const Alignment(-0.1, -0.1),
                              breath,
                            )!,
                            end: Alignment.lerp(
                              const Alignment(1.0, 0.1),
                              const Alignment(0.2, 0.1),
                              breath,
                            )!,
                            colors: [
                              Colors.white.withValues(alpha: 0.30),
                              Colors.white.withValues(alpha: 0.12),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                child!,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              ),
              child: const Icon(
                Icons.landscape_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pre-Hike',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Explore, Push your limit',
                    style: TextStyle(
                      color: Color(0xFFE6F4E7),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: widget.onLogout,
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                splashRadius: 24,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          constraints: const BoxConstraints(minHeight: 46),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: const Row(
            children: [
              Icon(Icons.explore_rounded, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Plan your next summit with handpicked mountain guides.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatsSection extends StatelessWidget {
  const _StatsSection({
    required this.darkGreen,
    required this.mediumGreen,
    required this.lightGreen,
    required this.textPrimary,
    required this.textSecondary,
  });

  final Color darkGreen;
  final Color mediumGreen;
  final Color lightGreen;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;

        if (compact) {
          return Column(
            children: [
              _StatCard(
                label: 'Climb',
                value: '0',
                icon: Icons.hiking_rounded,
                darkGreen: darkGreen,
                mediumGreen: mediumGreen,
                lightGreen: lightGreen,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              const SizedBox(height: 12),
              _StatCard(
                label: 'Achievements',
                value: '0',
                icon: Icons.workspace_premium_rounded,
                darkGreen: darkGreen,
                mediumGreen: mediumGreen,
                lightGreen: lightGreen,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Climb',
                value: '0',
                icon: Icons.hiking_rounded,
                darkGreen: darkGreen,
                mediumGreen: mediumGreen,
                lightGreen: lightGreen,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Achievements',
                value: '0',
                icon: Icons.workspace_premium_rounded,
                darkGreen: darkGreen,
                mediumGreen: mediumGreen,
                lightGreen: lightGreen,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.darkGreen,
    required this.mediumGreen,
    required this.lightGreen,
    required this.textPrimary,
    required this.textSecondary,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color darkGreen;
  final Color mediumGreen;
  final Color lightGreen;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: lightGreen,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: mediumGreen, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchSection extends StatelessWidget {
  const _SearchSection({
    required this.lightGreen,
    required this.mediumGreen,
    required this.textSecondary,
  });

  final Color lightGreen;
  final Color mediumGreen;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: mediumGreen.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        cursorColor: mediumGreen,
        decoration: InputDecoration(
          hintText: 'Search mountains',
          hintStyle: TextStyle(
            color: textSecondary,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 14, right: 10),
            child: Icon(Icons.search_rounded, color: mediumGreen, size: 24),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 54,
            minHeight: 54,
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: lightGreen),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: mediumGreen.withValues(alpha: 0.40)),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.subtitle,
    required this.darkGreen,
    required this.textSecondary,
  });

  final String title;
  final String subtitle;
  final Color darkGreen;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: darkGreen,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(
            color: textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _MountainCard extends StatefulWidget {
  const _MountainCard({
    super.key,
    required this.index,
    required this.mountain,
    required this.darkGreen,
    required this.mediumGreen,
    required this.lightGreen,
    required this.textPrimary,
    required this.textSecondary,
    required this.onTap,
  });

  final int index;
  final Mountain mountain;
  final Color darkGreen;
  final Color mediumGreen;
  final Color lightGreen;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onTap;

  @override
  State<_MountainCard> createState() => _MountainCardState();
}

class _MountainCardState extends State<_MountainCard> {
  bool _isVisible = false;
  bool _isPressed = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(Duration(milliseconds: 120 * widget.index), () {
      if (mounted) {
        setState(() {
          _isVisible = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOut,
      opacity: _isVisible ? 1 : 0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        offset: _isVisible ? Offset.zero : const Offset(0, 0.06),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 160),
          scale: _isPressed ? 0.985 : 1,
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            elevation: 0,
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: widget.onTap,
              onHighlightChanged: (value) {
                setState(() {
                  _isPressed = value;
                });
              },
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white, Color(0xFFF7FBF7)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.darkGreen.withValues(alpha: 0.08),
                      blurRadius: 22,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -30,
                      right: -18,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.lightGreen.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final compact = constraints.maxWidth < 360;

                          if (compact) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildMountainImage(double.infinity),
                                const SizedBox(height: 16),
                                _buildMountainDetails(),
                              ],
                            );
                          }

                          return Row(
                            children: [
                              _buildMountainImage(112),
                              const SizedBox(width: 16),
                              Expanded(child: _buildMountainDetails()),
                            ],
                          );
                        },
                      ),
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

  Widget _buildMountainImage(double width) {
    final mountain = widget.mountain;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        width: width,
        height: 128,
        child: Image.asset(
          mountain.imageAsset ?? 'assets/images/apo.jpg',
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildMountainDetails() {
    final mountain = widget.mountain;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _InfoChip(
              icon: Icons.public_rounded,
              label: mountain.region,
              backgroundColor: widget.lightGreen,
              foregroundColor: widget.mediumGreen,
            ),
            _InfoChip(
              icon: Icons.vertical_align_top_rounded,
              label: '${mountain.elevation} m',
              backgroundColor: widget.lightGreen,
              foregroundColor: widget.mediumGreen,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          mountain.name,
          style: TextStyle(
            color: widget.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          mountain.location,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: widget.textSecondary,
            fontSize: 13.5,
            height: 1.4,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          mountain.slope,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: widget.mediumGreen,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: widget.darkGreen,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View Trail',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.arrow_outward_rounded,
                    color: Colors.white,
                    size: 17,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: foregroundColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: foregroundColor,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeBottomNavigationBar extends StatelessWidget {
  const _HomeBottomNavigationBar({
    required this.currentIndex,
    required this.tapSequence,
    required this.lastTappedIndex,
    required this.darkGreen,
    required this.onTap,
  });

  final int currentIndex;
  final int tapSequence;
  final int lastTappedIndex;
  final Color darkGreen;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: darkGreen.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: BottomNavigationBar(
              currentIndex: currentIndex,
              onTap: onTap,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              elevation: 0,
              selectedItemColor: darkGreen,
              unselectedItemColor: const Color(0xFF7B877D),
              showSelectedLabels: false,
              showUnselectedLabels: false,
              items: [
                _buildNavItem(
                  index: profileNavbarIndex,
                  currentIndex: currentIndex,
                  tapSequence: tapSequence,
                  lastTappedIndex: lastTappedIndex,
                  icon: Icons.person_rounded,
                ),
                _buildNavItem(
                  index: homeNavbarIndex,
                  currentIndex: currentIndex,
                  tapSequence: tapSequence,
                  lastTappedIndex: lastTappedIndex,
                  icon: Icons.home_rounded,
                ),
                _buildNavItem(
                  index: weatherNavbarIndex,
                  currentIndex: currentIndex,
                  tapSequence: tapSequence,
                  lastTappedIndex: lastTappedIndex,
                  icon: Icons.cloud_rounded,
                ),
                _buildNavItem(
                  index: settingsNavbarIndex,
                  currentIndex: currentIndex,
                  tapSequence: tapSequence,
                  lastTappedIndex: lastTappedIndex,
                  icon: Icons.settings_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem({
    required int index,
    required int currentIndex,
    required int tapSequence,
    required int lastTappedIndex,
    required IconData icon,
  }) {
    final bool isActive = currentIndex == index;
    final String keyId = isActive && lastTappedIndex == index
        ? 'nav-$index-$tapSequence'
        : 'nav-$index';

    return BottomNavigationBarItem(
      label: '',
      icon: KeyedSubtree(
        key: ValueKey<String>(keyId),
        child: _NavIcon(icon: icon, isActive: isActive, darkGreen: darkGreen),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.icon,
    required this.isActive,
    required this.darkGreen,
  });

  final IconData icon;
  final bool isActive;
  final Color darkGreen;

  @override
  Widget build(BuildContext context) {
    const inactiveColor = Color(0xFF7B877D);
    const duration = Duration(milliseconds: 300);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: isActive ? 1 : 0),
      duration: duration,
      curve: isActive ? Curves.easeOutBack : Curves.easeOutCubic,
      builder: (context, progress, _) {
        final lift = lerpDouble(0, -7, progress)!;
        final scale = lerpDouble(1, 1.12, progress)!;
        final iconSize = lerpDouble(24, 26.5, progress)!;
        final iconColor = Color.lerp(inactiveColor, darkGreen, progress)!;
        final backgroundColor = Color.lerp(
          Colors.transparent,
          darkGreen.withValues(alpha: 0.12),
          progress,
        )!;
        final borderColor = Color.lerp(
          Colors.transparent,
          darkGreen.withValues(alpha: 0.10),
          progress,
        )!;

        return Transform.translate(
          offset: Offset(0, lift),
          child: AnimatedSlide(
            duration: duration,
            curve: Curves.easeOutCubic,
            offset: isActive ? const Offset(0, -0.05) : Offset.zero,
            child: AnimatedScale(
              duration: duration,
              curve: isActive ? Curves.easeOutBack : Curves.easeOutCubic,
              scale: scale,
              child: AnimatedContainer(
                duration: duration,
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.symmetric(
                  horizontal: progress > 0.01 ? 14 : 12,
                  vertical: progress > 0.01 ? 11 : 9,
                ),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    if (progress > 0.01)
                      BoxShadow(
                        color: darkGreen.withValues(alpha: 0.18 * progress),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                  ],
                ),
                child: Icon(icon, size: iconSize, color: iconColor),
              ),
            ),
          ),
        );
      },
    );
  }
}
