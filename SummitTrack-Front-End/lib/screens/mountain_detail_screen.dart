import 'package:flutter/material.dart';
import '../models/mountain.dart';

class MountainDetailScreen extends StatelessWidget {
  final Mountain mountain;

  const MountainDetailScreen({super.key, required this.mountain});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(mountain.name),
        backgroundColor: Colors.green[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              mountain.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text('Region: ${mountain.region}'),
            const SizedBox(height: 6),
            Text('Location: ${mountain.location}'),
            const SizedBox(height: 6),
            Text('Elevation: ${mountain.elevation} m'),
            const SizedBox(height: 12),
            Text(mountain.description),
          ],
        ),
      ),
    );
  }
}
