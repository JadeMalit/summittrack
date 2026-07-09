import 'package:flutter/material.dart';

import '../../../core/state/app_mode_provider.dart';
import '../../../features/dashboard/screens/home.dart';
import '../../../features/hike/screens/weather.dart';
import '../../../features/profile/screens/profile.dart';
import '../../../features/settings/screens/settings.dart';
import '../../../shared/widgets/shared_bottom_navbar.dart';
import '../../../widgets/page_transition_wrapper.dart';
import '../button_functions/navbar_button_function.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key, this.initialIndex = homeNavbarIndex});

  final int initialIndex;

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  final Map<int, Widget> _pages = <int, Widget>{};
  LocalHistoryEntry? _tabHistoryEntry;
  bool _isRemovingTabHistory = false;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = _normalizeIndex(widget.initialIndex);
    _pages[_currentIndex] = _createPage(_currentIndex);
  }

  @override
  void didUpdateWidget(covariant MainNavigationShell oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.initialIndex != oldWidget.initialIndex) {
      _selectTab(widget.initialIndex);
    }
  }

  Future<void> _handleBottomNavigationTap(int index) async {
    final nextIndex = _normalizeIndex(index);

    if (AppModeProvider.instance.isOfflineMode &&
        nextIndex != homeNavbarIndex) {
      _selectTab(homeNavbarIndex, isUserTap: true);
      await showOfflineFeatureUnavailableDialog(context);
      return;
    }

    _selectTab(nextIndex, isUserTap: true);
  }

  void _selectTab(int index, {bool isUserTap = false}) {
    final nextIndex = _normalizeIndex(index);
    final didChangeTab = nextIndex != _currentIndex;

    if (!mounted) {
      return;
    }

    setState(() {
      _currentIndex = nextIndex;

      _pages.putIfAbsent(nextIndex, () => _createPage(nextIndex));
    });

    if (!isUserTap) {
      return;
    }

    if (nextIndex == homeNavbarIndex) {
      _removeTabHistoryEntry();
      return;
    }

    if (didChangeTab || _tabHistoryEntry == null) {
      _replaceTabHistoryEntry();
    }
  }

  int _normalizeIndex(int index) {
    switch (index) {
      case profileNavbarIndex:
      case homeNavbarIndex:
      case weatherNavbarIndex:
      case settingsNavbarIndex:
        return index;
      default:
        return homeNavbarIndex;
    }
  }

  Widget _createPage(int index) {
    switch (index) {
      case profileNavbarIndex:
        return const ProfileScreen();
      case weatherNavbarIndex:
        return const WeatherScreen();
      case settingsNavbarIndex:
        return const SettingsScreen();
      case homeNavbarIndex:
      default:
        return const HomeScreen();
    }
  }

  void _replaceTabHistoryEntry() {
    _removeTabHistoryEntry();

    final route = ModalRoute.of(context);
    if (route == null) {
      return;
    }

    final entry = LocalHistoryEntry(
      onRemove: () {
        _tabHistoryEntry = null;

        if (_isRemovingTabHistory || !mounted) {
          return;
        }

        if (ModalRoute.of(context)?.isCurrent != true) {
          return;
        }

        _selectTab(homeNavbarIndex);
      },
    );

    _tabHistoryEntry = entry;
    route.addLocalHistoryEntry(entry);
  }

  void _removeTabHistoryEntry() {
    final entry = _tabHistoryEntry;
    if (entry == null) {
      return;
    }

    _isRemovingTabHistory = true;
    entry.remove();
    _isRemovingTabHistory = false;
    _tabHistoryEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: PageTransitionWrapper(currentIndex: _currentIndex, pages: _pages),
      bottomNavigationBar: SharedBottomNavbar(
        currentIndex: _currentIndex,
        onTap: _handleBottomNavigationTap,
      ),
    );
  }
}
