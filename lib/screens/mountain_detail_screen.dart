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
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// 🖼 HEADER IMAGE (placeholder for now)
            Container(
              height: 200,
              width: double.infinity,
              color: Colors.green[200],
              child: const Icon(Icons.terrain, size: 100, color: Colors.white),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// NAME
                  Text(
                    mountain.name,
                    style: const TextStyle(
                        fontSize: 26, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  /// BASIC INFO
                  Text("Region: ${mountain.region}"),
                  Text("Location: ${mountain.location}"),
                  Text("Elevation: ${mountain.elevation} meters"),

                  const SizedBox(height: 20),

                  /// DESCRIPTION
                  const Text("Description",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(mountain.description),

                  const SizedBox(height: 30),

                  /// ACTION BUTTONS
                  ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Upload Photo"),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Photo upload soon")),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: const Size(double.infinity, 50)),
                  ),

                  const SizedBox(height: 15),

                  ElevatedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text("Write Reflection"),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Reflection soon")),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        minimumSize: const Size(double.infinity, 50)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
