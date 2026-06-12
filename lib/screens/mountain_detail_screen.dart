import 'package:flutter/material.dart';
import '../TrailData/mountain.dart';
import '../app_routes.dart';
import 'mt_apo.dart';

class MountainDetailScreen extends StatelessWidget {
  final Mountain mountain;

  const MountainDetailScreen({super.key, required this.mountain});

  @override
  Widget build(BuildContext context) {
    if (mountain.name == 'Mt. Apo') {
      return const MtApoScreen();
    }

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
            SizedBox(
              height: 220,
              width: double.infinity,
              child: mountain.imageAsset == null
                  ? Container(
                      color: Colors.green[200],
                      child: const Icon(
                        Icons.terrain,
                        size: 100,
                        color: Colors.white,
                      ),
                    )
                  : Image.asset(
                      mountain.imageAsset!,
                      fit: BoxFit.cover,
                    ),
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
                  Text("Slope: ${mountain.slope}"),

                  const SizedBox(height: 20),

                  /// DESCRIPTION
                  const Text("Description",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(mountain.description),

                  const SizedBox(height: 30),

                  /// TRAILS
                  const Text("Trails",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  if (mountain.trails.isEmpty)
                    const Text("Trail details will be added soon.")
                  else
                    for (final trail in mountain.trails) ...[
                      ElevatedButton.icon(
                        icon: const Icon(Icons.hiking),
                        label: Text(trail),
                        onPressed: () => _openTrail(context, mountain, trail),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            minimumSize: const Size(double.infinity, 48)),
                      ),
                      const SizedBox(height: 10),
                    ],

                  const SizedBox(height: 20),

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

  void _openTrail(BuildContext context, Mountain mountain, String trail) {
    if (mountain.name == 'Mt. Apo' && trail == 'Sta. Cruz / Sibulan Trail') {
      Navigator.of(context).pushNamed(
        AppRoutes.trail(
          AppRoutes.mtApoMountainId,
          AppRoutes.staCruzTrailId,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$trail details will be added soon.')),
    );
  }
}
