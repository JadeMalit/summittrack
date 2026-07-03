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

        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Container(
              decoration: BoxDecoration(
                color: colors.navBackground,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow,
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: BottomNavigationBar(
                  currentIndex: selectedPosition < 0 ? 0 : selectedPosition,
                  onTap: (position) => onTap(items[position].index),
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: colors.navBackground,
                  elevation: 0,
                  selectedItemColor: colors.accent,
                  unselectedItemColor: colors.textSecondary,
                  showSelectedLabels: false,
                  showUnselectedLabels: false,
                  items: [
                    for (final item in items)
                      _buildNavItem(
                        item: item,
                        currentIndex: resolvedCurrentIndex,
                        activeColor: colors.accent,
                        inactiveColor: colors.textSecondary,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  BottomNavigationBarItem _buildNavItem({
    required SharedBottomNavbarItem item,
    required int currentIndex,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    final isActive = currentIndex == item.index;

    return BottomNavigationBarItem(
      label: item.tooltip ?? '',
      icon: AnimatedNavIcon(
        icon: item.icon,
        isActive: isActive,
        activeColor: activeColor,
        inactiveColor: inactiveColor,
        isLifted: item.liftOnActive,
      ),
    );
  }
}

class _OfflineHomeNavbar extends StatelessWidget {
  const _OfflineHomeNavbar({required this.colors, required this.onTap});

  final AppColors colors;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: Align(
          alignment: Alignment.center,
          heightFactor: 1,
          child: Container(
            decoration: BoxDecoration(
              color: colors.navBackground,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow,
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Tooltip(
              message: 'Home',
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(26),
                child: InkWell(
                  onTap: () => onTap(homeNavbarIndex),
                  borderRadius: BorderRadius.circular(26),
                  child: SizedBox(
                    width: 74,
                    height: 62,
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
          ),
        ),
      ),
    );
  }
}
