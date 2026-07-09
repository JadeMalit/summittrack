import 'package:flutter/material.dart';

import '../../core/state/app_mode_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../features/navigation/button_functions/navbar_button_function.dart';
import '../../features/navigation/widgets/animated_nav_icon.dart';

class SharedBottomNavbarItem {
  const SharedBottomNavbarItem({
    required this.index,
    required this.icon,
    this.liftOnActive = false,
    this.tooltip,
  });

  final int index;
  final IconData icon;
  final bool liftOnActive;
  final String? tooltip;
}

const List<SharedBottomNavbarItem> defaultSharedBottomNavbarItems = [
  SharedBottomNavbarItem(
    index: profileNavbarIndex,
    icon: Icons.person_rounded,
    liftOnActive: true,
    tooltip: 'Profile',
  ),
  SharedBottomNavbarItem(
    index: homeNavbarIndex,
    icon: Icons.home_rounded,
    tooltip: 'Home',
  ),
  SharedBottomNavbarItem(
    index: weatherNavbarIndex,
    icon: Icons.cloud_rounded,
    tooltip: 'Weather',
  ),
  SharedBottomNavbarItem(
    index: settingsNavbarIndex,
    icon: Icons.settings_rounded,
    tooltip: 'Settings',
  ),
];

class SharedBottomNavbar extends StatelessWidget {
  const SharedBottomNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.items = defaultSharedBottomNavbarItems,
    this.showOfflineHomeOnly = true,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<SharedBottomNavbarItem> items;
  final bool showOfflineHomeOnly;

  static const double _height = 56;
  static const double _horizontalMargin = 20;
  static const double _bottomMargin = 10;
  static const double _maxWidth = 360;
  static const BorderRadius _borderRadius = BorderRadius.all(
    Radius.circular(28),
  );

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AnimatedBuilder(
      animation: AppModeProvider.instance,
      builder: (context, _) {
        if (showOfflineHomeOnly && AppModeProvider.instance.isOfflineMode) {
          return _OfflineHomeNavbar(colors: colors, onTap: onTap);
        }

        final selectedPosition = items.indexWhere(
          (item) => item.index == currentIndex,
        );
        final resolvedCurrentIndex = selectedPosition < 0
            ? items.first.index
            : currentIndex;

        return _FloatingNavFrame(
          colors: colors,
          child: Row(
            children: [
              for (final item in items)
                _NavButton(
                  item: item,
                  isActive: resolvedCurrentIndex == item.index,
                  activeColor: colors.accent,
                  inactiveColor: colors.textSecondary,
                  onTap: () => onTap(item.index),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _OfflineHomeNavbar extends StatelessWidget {
  const _OfflineHomeNavbar({required this.colors, required this.onTap});

  final AppColors colors;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return _FloatingNavFrame(
      colors: colors,
      maxWidth: 76,
      child: Tooltip(
        message: 'Home',
        child: Semantics(
          button: true,
          selected: true,
          label: 'Home',
          child: InkWell(
            onTap: () => onTap(homeNavbarIndex),
            borderRadius: SharedBottomNavbar._borderRadius,
            child: SizedBox(
              height: SharedBottomNavbar._height,
              child: Center(
                child: AnimatedNavIcon(
                  icon: Icons.home_rounded,
                  isActive: true,
                  activeColor: colors.accent,
                  inactiveColor: colors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingNavFrame extends StatelessWidget {
  const _FloatingNavFrame({
    required this.colors,
    required this.child,
    this.maxWidth = SharedBottomNavbar._maxWidth,
  });

  final AppColors colors;
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final backgroundColor = isDark
        ? colors.surfaceHigh.withValues(alpha: 0.96)
        : colors.navBackground.withValues(alpha: 0.98);
    final borderSide = BorderSide(
      color: isDark
          ? colors.border.withValues(alpha: 0.82)
          : colors.textSecondary.withValues(alpha: 0.24),
      width: 1,
    );

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          SharedBottomNavbar._horizontalMargin,
          0,
          SharedBottomNavbar._horizontalMargin,
          SharedBottomNavbar._bottomMargin,
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: SharedBottomNavbar._borderRadius,
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow,
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: backgroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: SharedBottomNavbar._borderRadius,
                  side: borderSide,
                ),
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  height: SharedBottomNavbar._height,
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  final SharedBottomNavbarItem item;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tooltip = item.tooltip ?? '';

    return Expanded(
      child: Tooltip(
        message: tooltip,
        child: Semantics(
          button: true,
          selected: isActive,
          label: tooltip,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              height: SharedBottomNavbar._height,
              child: Center(
                child: AnimatedNavIcon(
                  icon: item.icon,
                  isActive: isActive,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                  isLifted: item.liftOnActive,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
