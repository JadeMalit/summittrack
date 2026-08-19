import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/layout/app_responsive.dart';
import '../../../core/routing/mountain_screen_resolver.dart';
import '../../../core/state/app_mode_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/trail_data/mountain.dart';
import '../../offline/data/offline_mountains_data.dart';
import '../../../services/data_service.dart';
import '../widgets/pre_hike_header_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final List<Mountain> _allMountains;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _allMountains = List<Mountain>.unmodifiable(
      AppModeProvider.instance.isOfflineMode
          ? offlineMountainsData
          : DataService.getMountains(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Mountain> get _filteredMountains {
    if (_searchQuery.isEmpty) {
      return _allMountains;
    }

    return _allMountains.where((mountain) {
      return _searchableMountainText(mountain).contains(_searchQuery);
    }).toList();
  }

  void _handleSearchChanged(String value) {
    final normalizedQuery = _normalizeSearchTerm(value);

    if (normalizedQuery == _searchQuery) {
      return;
    }

    setState(() {
      _searchQuery = normalizedQuery;
    });
  }

  void _clearSearch() {
    _searchController.clear();

    if (_searchQuery.isEmpty) {
      return;
    }

    setState(() {
      _searchQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final darkGreen = colors.primary;
    final mediumGreen = colors.accent;
    final lightGreen = colors.surfaceMuted;
    final textPrimary = colors.textPrimary;
    final textSecondary = colors.textSecondary;
    final mountains = _filteredMountains;
    final isOfflineMode = AppModeProvider.instance.isOfflineMode;
    final hasActiveSearch = _searchQuery.isNotEmpty;
    final resultCountLabel = mountains.length == 1
        ? '1 mountain'
        : '${mountains.length} mountains';
    final bottomClearance = AppResponsive.floatingNavClearance(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: context.isDarkMode
                ? [colors.background, colors.backgroundAlt, colors.background]
                : const [
                    Color(0xFFF1F8F1),
                    Color(0xFFFFFFFF),
                    Color(0xFFF7FBF7),
                  ],
          ),
        ),
        child: SafeArea(
          top: false,
          bottom: false,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverToBoxAdapter(child: PreHikeHeaderCard()),
              if (isOfflineMode)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: _OfflineHomeNotice(
                      mediumGreen: mediumGreen,
                      lightGreen: lightGreen,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: _StatsSection(
                      darkGreen: darkGreen,
                      mediumGreen: mediumGreen,
                      lightGreen: lightGreen,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 18)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _SearchSection(
                    controller: _searchController,
                    onChanged: _handleSearchChanged,
                    onClear: _clearSearch,
                    showClearButton: _searchController.text.trim().isNotEmpty,
                    lightGreen: lightGreen,
                    mediumGreen: mediumGreen,
                    textSecondary: textSecondary,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 26, 20, 14),
                  child: _SectionHeading(
                    title: 'Explore Mountains',
                    subtitle: hasActiveSearch
                        ? 'Showing $resultCountLabel from the mountains available in the app.'
                        : 'Browse all available mountains and open their trail details.',
                    darkGreen: darkGreen,
                    textSecondary: textSecondary,
                  ),
                ),
              ),
              if (mountains.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, bottomClearance),
                    child: _EmptyMountainState(
                      hasActiveSearch: hasActiveSearch,
                      darkGreen: darkGreen,
                      mediumGreen: mediumGreen,
                      lightGreen: lightGreen,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, bottomClearance),
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
                          darkGreen: darkGreen,
                          mediumGreen: mediumGreen,
                          lightGreen: lightGreen,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
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
    );
  }
}

String _normalizeSearchTerm(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ');
}

String _searchableMountainText(Mountain mountain) {
  final normalizedName = _normalizeSearchTerm(mountain.name);
  final mountAlias = normalizedName.replaceFirst(RegExp(r'^mt\b'), 'mount');

  return '$normalizedName $mountAlias';
}

class _OfflineHomeNotice extends StatelessWidget {
  const _OfflineHomeNotice({
    required this.mediumGreen,
    required this.lightGreen,
    required this.textPrimary,
    required this.textSecondary,
  });

  final Color mediumGreen;
  final Color lightGreen;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: lightGreen,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.offline_bolt_rounded, color: mediumGreen),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Offline Mode',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Limited access only. You can view mountain information from the Home screen.',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 13.5,
                    height: 1.4,
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
    final colors = context.appColors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        final achievementAccent = context.isDarkMode
            ? colors.softHighlight
            : const Color(0xFF7E8A55);
        final achievementTint = context.isDarkMode
            ? colors.surfaceMuted
            : const Color(0xFFF3F6EA);

        if (compact) {
          return Column(
            children: [
              _StatCard(
                label: 'Climb',
                value: '0',
                icon: Icons.hiking_rounded,
                animationDelay: Duration.zero,
                darkGreen: darkGreen,
                accentColor: mediumGreen,
                accentTint: lightGreen,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              const SizedBox(height: 12),
              _StatCard(
                label: 'Achievements',
                value: '0',
                icon: Icons.workspace_premium_rounded,
                animationDelay: const Duration(milliseconds: 110),
                darkGreen: darkGreen,
                accentColor: achievementAccent,
                accentTint: achievementTint,
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
                animationDelay: Duration.zero,
                darkGreen: darkGreen,
                accentColor: mediumGreen,
                accentTint: lightGreen,
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
                animationDelay: const Duration(milliseconds: 110),
                darkGreen: darkGreen,
                accentColor: achievementAccent,
                accentTint: achievementTint,
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

class _StatCard extends StatefulWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.animationDelay,
    required this.darkGreen,
    required this.accentColor,
    required this.accentTint,
    required this.textPrimary,
    required this.textSecondary,
  });

  final String label;
  final String value;
  final IconData icon;
  final Duration animationDelay;
  final Color darkGreen;
  final Color accentColor;
  final Color accentTint;
  final Color textPrimary;
  final Color textSecondary;

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _isVisible = false;
  bool _isHovered = false;
  bool _isPressed = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.animationDelay, () {
      if (!mounted) {
        return;
      }

      setState(() {
        _isVisible = true;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isInteractive = _isHovered || _isPressed;
    final borderColor = isInteractive
        ? widget.accentColor.withValues(alpha: 0.24)
        : colors.border;
    final shadowColor = isInteractive
        ? widget.accentColor.withValues(alpha: 0.14)
        : colors.shadow;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOut,
      opacity: _isVisible ? 1 : 0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
        offset: _isVisible ? Offset.zero : const Offset(0, 0.08),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          scale: _isPressed ? 0.985 : (_isHovered ? 1.01 : 1),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () {},
              onHover: (value) {
                if (_isHovered == value) {
                  return;
                }

                setState(() {
                  _isHovered = value;
                });
              },
              onHighlightChanged: (value) {
                if (_isPressed == value) {
                  return;
                }

                setState(() {
                  _isPressed = value;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor,
                      blurRadius: isInteractive ? 24 : 18,
                      offset: Offset(0, isInteractive ? 12 : 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: widget.accentTint,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: widget.accentColor.withValues(alpha: 0.14),
                        ),
                      ),
                      child: Icon(
                        widget.icon,
                        color: widget.accentColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: widget.accentColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  widget.label,
                                  style: TextStyle(
                                    color: widget.textSecondary,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            widget.value,
                            style: TextStyle(
                              color: widget.textPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                              height: 1,
                            ),
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
    );
  }
}

class _SearchSection extends StatelessWidget {
  const _SearchSection({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.showClearButton,
    required this.lightGreen,
    required this.mediumGreen,
    required this.textSecondary,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool showClearButton;
  final Color lightGreen;
  final Color mediumGreen;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        cursorColor: mediumGreen,
        style: TextStyle(color: colors.textPrimary),
        textInputAction: TextInputAction.search,
        onTapOutside: (_) => FocusScope.of(context).unfocus(),
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
          suffixIcon: showClearButton
              ? IconButton(
                  onPressed: onClear,
                  icon: Icon(
                    Icons.close_rounded,
                    color: textSecondary.withValues(alpha: 0.8),
                  ),
                )
              : null,
          filled: true,
          fillColor: colors.surface,
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

class _EmptyMountainState extends StatelessWidget {
  const _EmptyMountainState({
    required this.hasActiveSearch,
    required this.darkGreen,
    required this.mediumGreen,
    required this.lightGreen,
    required this.textPrimary,
    required this.textSecondary,
  });

  final bool hasActiveSearch;
  final Color darkGreen;
  final Color mediumGreen;
  final Color lightGreen;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: lightGreen,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.terrain_rounded, color: mediumGreen, size: 30),
          ),
          const SizedBox(height: 16),
          Text(
            hasActiveSearch ? 'No mountain found' : 'No mountains available',
            style: TextStyle(
              color: textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            hasActiveSearch
                ? 'Try a different mountain name from the available list.'
                : 'Available mountains will appear here once data is ready.',
            style: TextStyle(
              color: textSecondary,
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
    final colors = context.appColors;

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
            color: colors.surface,
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
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [colors.surface, colors.surfaceHigh],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow,
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
    final imageAsset = _homeImageAssetFor(mountain);

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        width: width,
        height: 128,
        child: imageAsset == null
            ? _MountainImagePlaceholder(
                backgroundColor: widget.lightGreen,
                foregroundColor: widget.mediumGreen,
              )
            : Image.asset(imageAsset, fit: BoxFit.cover),
      ),
    );
  }

  String? _homeImageAssetFor(Mountain mountain) {
    switch (mountain.name) {
      case 'Mt. Batulao':
        return 'assets/images/mt_batulao_home.png';
      case 'Mt. Apo':
        return 'assets/images/mt_apo_enhanced.png';
      case 'Mt. Pulag':
        return 'assets/images/mt_pulag_home.jpg';
      case 'Mt. Mayon':
        return 'assets/images/mayon_home.png';
      case 'Mt. Ulap':
        return 'assets/images/mt_ulap.jpg';
      case 'Mt. Daraitan':
        return 'assets/images/mt_daraitan_home.png';
      case 'Mt. Maculot':
        return 'assets/images/mt_maculot_home.png';
      case 'Mt. Pico de Loro':
        return 'assets/images/mt_pico_de_loro_home.png';
      case 'Mt. Pinatubo':
        return 'assets/images/mt_pinatubo_home.png';
      case 'Mt. Guiting-Guiting':
        return 'assets/images/mt_guiting_guiting_home.png';
      case 'Mt. Gulugod Baboy':
        return 'assets/images/mt_gulugod_baboy_home.png';
      case 'Mt. Maynoba':
        return 'assets/images/mt_manoyba_home.png';
      case 'Mt. Arayat':
        return 'assets/images/mt_arayat_home.png';
      case 'Mt. Makiling':
        return 'assets/images/mt_makiling_home.png';
      case 'Mt. Tugew':
        return 'assets/images/mt_tugew_home.png';
      case 'Mt. Mariglem':
        return 'assets/images/mt_mariglem_home.png';
      default:
        return mountain.imageAsset;
    }
  }

  Widget _buildMountainDetails() {
    final mountain = widget.mountain;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

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
              label: mountain.elevationLabel,
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View Trail',
                    style: TextStyle(
                      color: onPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_outward_rounded, color: onPrimary, size: 17),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MountainImagePlaceholder extends StatelessWidget {
  const _MountainImagePlaceholder({
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: Center(
        child: Icon(Icons.terrain_rounded, color: foregroundColor, size: 42),
      ),
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
