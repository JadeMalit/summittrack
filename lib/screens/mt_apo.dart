import 'package:flutter/material.dart';

class MtApoScreen extends StatelessWidget {
  const MtApoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      appBar: AppBar(
        backgroundColor: Colors.green[800],
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Mt. Apo",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [

            /// 🌄 HEADER IMAGE
            Stack(
              children: [
                Container(
                  height: 250,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage("assets/images/apo.jpg"),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                Container(
                  height: 250,
                  width: double.infinity,
                  color: Colors.black.withOpacity(0.3),
                ),

                Positioned(
                  bottom: 20,
                  left: 20,
                  child: Text(
                    "Mt. Apo",
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[200],
                      shadows: const [
                        Shadow(
                          blurRadius: 10,
                          color: Colors.black,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            /// 📄 CONTENT
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  /// 📍 BASIC INFO
                  infoText(
                    "Location:",
                    "Mindanao, Philippines",
                  ),

                  infoText(
                    "Elevation:",
                    "2,954 meters above sea level",
                  ),

                  infoText(
                    "Difficulty:",
                    "Hard",
                  ),

                  infoText(
                    "Slope:",
                    "Steep and Rocky",
                  ),

                  const SizedBox(height: 20),

                  /// DESCRIPTION TITLE
                  Text(
                    "Description",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                    ),
                  ),

                  const SizedBox(height: 10),

                  /// DESCRIPTION
                  const Text(
                    "Mt. Apo is the highest mountain in the Philippines "
                    "and is one of the most popular hiking destinations "
                    "in the country. It features forests, volcanic rocks, "
                    "rivers, and beautiful landscapes suitable for "
                    "experienced hikers and nature enthusiasts.",
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.7,
                    ),
                    textAlign: TextAlign.justify,
                  ),

                  const SizedBox(height: 30),

                  /// 🔥 ADD CLIMB BUTTON
                  buttonWidget(
                    title: "Add Climb",
                    icon: Icons.hiking,
                    color: Colors.orange,
                    onTap: () {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content:
                              Text("Climb Added"),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 15),

                  /// ✅ PRE HIKE BUTTON
                  buttonWidget(
                    title: "Pre-Hike",
                    icon: Icons.checklist,
                    color: Colors.blue,
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (_) {
                          return Container(
                            padding:
                                const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize:
                                  MainAxisSize.min,
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: const [

                                Text(
                                  "Pre-Hike Essentials",
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),

                                SizedBox(height: 15),

                                Text("✔ Water"),
                                Text("✔ Flashlight"),
                                Text("✔ First Aid Kit"),
                                Text("✔ Extra Clothes"),
                                Text("✔ Powerbank"),
                                Text("✔ Trail Food"),
                                Text("✔ Emergency Whistle"),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 15),

                  /// ▶ START BUTTON
                  buttonWidget(
                    title: "Start",
                    icon: Icons.play_arrow,
                    color: Colors.green,
                    onTap: () {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                              "Tracking Started"),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 📌 INFO TEXT
  Widget infoText(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
          ),
          children: [
            TextSpan(
              text: "$title ",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  /// 🔥 BUTTON WIDGET
  Widget buttonWidget({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(15),
          ),
        ),
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}