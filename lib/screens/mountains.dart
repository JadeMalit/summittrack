import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';  // To get current user
import '../services/data_service.dart';
import 'mountain_screen_resolver.dart';

class MountainsScreen extends StatelessWidget {
  const MountainsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mountains = DataService.getMountains();

    // Get current user from FirebaseAuth
    final User? user = FirebaseAuth.instance.currentUser;
    final String userName = user?.displayName ?? 'Guest';  // If not logged in, show 'Guest'

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mountains'),
        backgroundColor: Colors.green[700],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Profile Picture
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.green[700],
                    child: user?.photoURL == null
                        ? const Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.white,
                          )
                        : ClipOval(
                            child: Image.network(
                              user!.photoURL!,  // Display user's photo if available
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                  ),
                  const SizedBox(height: 10),
                  // User's Name
                  Text(
                    'Hello, $userName!',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            // Mountain List Section
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView.builder(
                shrinkWrap: true,  // Ensures that the ListView takes only the space it needs
                itemCount: mountains.length,
                itemBuilder: (context, index) {
                  final mountain = mountains[index];
                  return Card(
                    margin: const EdgeInsets.all(10),
                    elevation: 5,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(10),
                      title: Text(mountain.name),
                      subtitle: Text(
                          'Elevation: ${mountain.elevation}m, Location: ${mountain.location}'),
                      onTap: () {
                        openMountainScreen(context, mountain);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
