import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/theme/app_colors.dart';
import '../../hike/screens/hike.dart';
import '../../hike/screens/reflections.dart';
import '../../mountains/screens/mountains.dart'; // Mountain screen for the list
import '../../profile/screens/profile.dart'; // Profile screen
import '../../navigation/widgets/animated_nav_icon.dart';
import 'home.dart'; // HomeScreen

class MainNav extends StatefulWidget {
  const MainNav({super.key});

  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  int _currentIndex = 0;

  // List of screens
  final List<Widget> _screens = [
    const HomeScreen(), // Home Screen
    const MountainsScreen(), // Mountain list
    const ProfileScreen(), // Profile screen
    const HikeScreen(), // Hike Screen
    const ReflectionsScreen(), // Reflections Screen
  ];

  // Function to get the user's profile name from FirebaseAuth
  String getUserName() {
    final User? user = FirebaseAuth.instance.currentUser;
    return user?.displayName ?? 'Guest'; // If not logged in, show 'Guest'
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'SummitTrack - ${getUserName()}',
        ), // Display user name in the AppBar
      ),
      body: _screens[_currentIndex], // Display the screen based on selected tab
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: AnimatedNavIcon(
              icon: Icons.home_rounded,
              isActive: _currentIndex == 0,
              activeColor: colors.accent,
              inactiveColor: colors.textSecondary,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: AnimatedNavIcon(
              icon: Icons.terrain_rounded,
              isActive: _currentIndex == 1,
              activeColor: colors.accent,
              inactiveColor: colors.textSecondary,
            ),
            label: 'Mountains',
          ),
          BottomNavigationBarItem(
            icon: AnimatedNavIcon(
              icon: Icons.person_rounded,
              isActive: _currentIndex == 2,
              activeColor: colors.accent,
              inactiveColor: colors.textSecondary,
              isLifted: true,
            ),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: AnimatedNavIcon(
              icon: Icons.hiking_rounded,
              isActive: _currentIndex == 3,
              activeColor: colors.accent,
              inactiveColor: colors.textSecondary,
            ),
            label: 'Hike',
          ),
          BottomNavigationBarItem(
            icon: AnimatedNavIcon(
              icon: Icons.book_rounded,
              isActive: _currentIndex == 4,
              activeColor: colors.accent,
              inactiveColor: colors.textSecondary,
            ),
            label: 'Reflections',
          ),
        ],
      ),
    );
  }
}
