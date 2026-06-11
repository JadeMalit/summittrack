import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/data_service.dart';
import 'mountain_detail_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final String userName = user?.displayName ?? 'Hiker';

    final mountains = DataService.getMountains()
        .where((mountain) =>
            mountain.name == 'Mt. Pulag' ||
            mountain.name == 'Mt. Batulao' ||
            mountain.name == 'Mt. Pinatubo')
        .toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        title: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              child: Icon(Icons.person),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Welcome 👋', style: TextStyle(fontSize: 13)),
                Text(
                  userName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: mountains.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final m = mountains[index];
          return ListTile(
            leading: const Icon(Icons.terrain),
            title: Text(m.name),
            subtitle: Text('${m.location} • ${m.elevation} m'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MountainDetailScreen(mountain: m),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
