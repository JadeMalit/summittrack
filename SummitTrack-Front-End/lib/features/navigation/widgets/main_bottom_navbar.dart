import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../button_functions/navbar_button_function.dart';
import 'animated_nav_icon.dart';

class MainBottomNavbar extends StatelessWidget {
  const MainBottomNavbar({
    super.key,
    required this.currentIndex,
    required this.tapSequence,
    required this.lastTappedIndex,
    required this.onTap,
  });

  final int currentIndex;
  final int tapSequence;
  final int lastTappedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

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
              currentIndex: currentIndex,
              onTap: onTap,
              type: BottomNavigationBarType.fixed,
              backgroundColor: colors.navBackground,
              elevation: 0,
              selectedItemColor: colors.accent,
              unselectedItemColor: colors.textSecondary,
              showSelectedLabels: false,
              showUnselectedLabels: false,
              items: [
                _buildNavItem(
                  index: profileNavbarIndex,
                  currentIndex: currentIndex,
                  tapSequence: tapSequence,
                  lastTappedIndex: lastTappedIndex,
                  icon: Icons.person_rounded,
                  activeColor: colors.accent,
                  inactiveColor: colors.textSecondary,
                  liftOnActive: true,
                ),
                _buildNavItem(
                  index: homeNavbarIndex,
                  currentIndex: currentIndex,
                  tapSequence: tapSequence,
                  lastTappedIndex: lastTappedIndex,
                  icon: Icons.home_rounded,
                  activeColor: colors.accent,
                  inactiveColor: colors.textSecondary,
                ),
                _buildNavItem(
                  index: weatherNavbarIndex,
                  currentIndex: currentIndex,
                  tapSequence: tapSequence,
                  lastTappedIndex: lastTappedIndex,
                  icon: Icons.cloud_rounded,
                  activeColor: colors.accent,
                  inactiveColor: colors.textSecondary,
                ),
                _buildNavItem(
                  index: settingsNavbarIndex,
                  currentIndex: currentIndex,
                  tapSequence: tapSequence,
                  lastTappedIndex: lastTappedIndex,
                  icon: Icons.settings_rounded,
                  activeColor: colors.accent,
                  inactiveColor: colors.textSecondary,
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
    required Color activeColor,
    required Color inactiveColor,
    bool liftOnActive = false,
  }) {
    final isActive = currentIndex == index;
    final keyId = isActive && lastTappedIndex == index
        ? 'nav-$index-$tapSequence'
        : 'nav-$index';

    return BottomNavigationBarItem(
      label: '',
      icon: KeyedSubtree(
        key: ValueKey<String>(keyId),
        child: AnimatedNavIcon(
          icon: icon,
          isActive: isActive,
          activeColor: activeColor,
          inactiveColor: inactiveColor,
          isLifted: liftOnActive,
        ),
      ),
    );
  }
}
