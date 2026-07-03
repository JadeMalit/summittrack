import 'package:flutter/material.dart';
import 'home.dart'; // HomeScreen
import 'mountains.dart'; // Mountain screen for the list
import 'profile.dart'; // Profile screen
import 'hike.dart';
import 'reflections.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../shared/widgets/shared_bottom_navbar.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'SummitTrack - ${getUserName()}',
        ), // Display user name in the AppBar
        backgroundColor: Colors.green[700],
      ),
      body: _screens[_currentIndex], // Display the screen based on selected tab
      bottomNavigationBar: SharedBottomNavbar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        showOfflineHomeOnly: false,
        items: const [
          SharedBottomNavbarItem(
            index: 0,
            icon: Icons.home_rounded,
            tooltip: 'Home',
          ),
          SharedBottomNavbarItem(
            index: 1,
            icon: Icons.terrain_rounded,
            tooltip: 'Mountains',
          ),
          SharedBottomNavbarItem(
            index: 2,
            icon: Icons.person_rounded,
            liftOnActive: true,
            tooltip: 'Profile',
          ),
          SharedBottomNavbarItem(
            index: 3,
            icon: Icons.hiking_rounded,
            tooltip: 'Hike',
          ),
          SharedBottomNavbarItem(
            index: 4,
            icon: Icons.book_rounded,
            tooltip: 'Reflections',
          ),
        ],
      ),
    );
  }
}
