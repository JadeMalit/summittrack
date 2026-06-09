import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'mountains.dart';
import 'mt_apo.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? "Hiker";

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [

            /// 🔥 TOP HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 20),
              decoration: const BoxDecoration(
                color: Color(0xFF0B5D16),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
              ),
              child: Column(
                children: [

                  /// LOGO
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.terrain,
                          size: 35,
                          color: Colors.green[800],
                        ),
                      ),

                      const SizedBox(width: 12),

                      const Expanded(
                        child: Text(
                          "Pre-Hike\nExplore, Push your limit",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                        ),
                      ),

                      IconButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          Navigator.pop(context);
                        },
                        icon: const Icon(
                          Icons.logout,
                          color: Colors.white,
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            /// STATS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [

                  /// CLIMB
                  Column(
                    children: [
                      const Text(
                        "0",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        "Climb",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),

                  /// ACHIEVEMENTS
                  Column(
                    children: [
                      const Text(
                        "0",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        "Achievements",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            /// SEARCH BAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Container(
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Search",
                    prefixIcon: const Icon(Icons.search),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.only(top: 10),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// MOUNTAIN LIST
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15),
                children: [

                  /// MT APO
                  mountainCard(
                    context,
                    "Mt. Apo",
                    "assets/images/apo.jpg",
                  ),

                  const SizedBox(height: 15),

                  /// MT PULAG
                  mountainCard(
                    context,
                    "Mt. Pulag",
                    "assets/images/pulag.jpg",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      /// 🔥 BOTTOM NAVIGATION
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        selectedItemColor: Colors.green[800],
        unselectedItemColor: Colors.black54,
        type: BottomNavigationBarType.fixed,
        items: const [

          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.cloud),
            label: "",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "",
          ),
        ],
      ),
    );
  }

  /// 🔥 MOUNTAIN CARD
  Widget mountainCard(
      BuildContext context,
      String title,
      String imagePath,
      ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const MtApoScreen(),
          ),
        );
      },
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          children: [

            /// IMAGE
            Container(
              width: 160,
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                image: DecorationImage(
                  image: AssetImage(imagePath),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            /// TITLE + ARROW
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 20),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [

                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800],
                      ),
                    ),

                    const Icon(
                      Icons.arrow_forward,
                      size: 40,
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}