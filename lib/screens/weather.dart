import 'package:flutter/material.dart';
import '../services/weather_service.dart';
import '../ButtonFunction/navbar_button_function.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final WeatherService weatherService = WeatherService();
  int selectedIndex = 2;

  final List<String> mountains = [
    "Mount Ulap", "Mount Manabu", "Mount Gulugod Baboy", "Mount Maynoba",
    "Mount Cutuno", "Mount Lingguhob", "Mount Batulao", "Mount Daraitan",
    "Mount Arayat", "Mount Makiling", "Mount Damas", "Mount Tugew",
    "Mount Mariglem", "Mount Pinatubo", "Mount Pulag", "Mount Apo",
    "Mount Tapulao", "Mount Espadang Bato", "Mount Hibok-Hibok", "Mount Kitanglad",
  ];

  String selectedMountain = "Mount Apo";
  Map<String, dynamic>? weatherData;
  bool isError = false;
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    loadWeather();
  }

  Future<void> loadWeather() async {
    try {
      setState(() {
        weatherData = null;
        isError = false;
      });

      final data = await weatherService.getWeather(selectedMountain);

      if (mounted) {
        setState(() {
          weatherData = data;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isError = true;
          errorMessage = e.toString();
        });
      }
    }
  }

  String getHikingStatus(int rainChance) {
    if (rainChance < 40) return "✅ Safe to Hike";
    if (rainChance < 70) return "⚠️ Use Caution";
    return "❌ Not Recommended";
  }

  List<Color> getBGGradient(String condition) {
    final cond = condition.toLowerCase();
    if (cond.contains("rain") || cond.contains("drizzle") || cond.contains("thunderstorm")) {
      return [const Color(0xFF3A506B), const Color(0xFF1A2536)];
    } else if (cond.contains("cloud") || cond.contains("overcast")) {
      return [const Color(0xFF6190E8), const Color(0xFFA7BFE8)];
    }
    return [const Color(0xFF2193b0), const Color(0xFF6dd5ed)];
  }

  /// 🔥 ANIMATED BOTTOM SHEET SELECTOR
  void _showMountainPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      transitionAnimationController: AnimationController(
        vsync: Navigator.of(context),
        duration: const Duration(milliseconds: 400), // Makinis na sliding speed
      ),
      builder: (context) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 300),
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.95 + (0.05 * value), // May banayad na pop animation
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: Container(
            height: MediaQuery.of(context).size.height * 0.45, // Kalahati lang ng screen para hindi nakakaharang
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E2C),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                /// Decorative Top Handle Bar
                const SizedBox(height: 12),
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  "Select Mountain",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Divider(color: Colors.white12, height: 1),
                
                /// Scrollable List na may magandang highlight indicators
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: mountains.length,
                    itemBuilder: (context, index) {
                      final isSelected = mountains[index] == selectedMountain;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.green.withOpacity(0.2) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          title: Text(
                            mountains[index],
                            style: TextStyle(
                              color: isSelected ? Colors.green[400] : Colors.white,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          trailing: isSelected 
                              ? const Icon(Icons.check_circle, color: Colors.green) 
                              : const Icon(Icons.circle_outlined, color: Colors.white24),
                          onTap: () {
                            setState(() {
                              selectedMountain = mountains[index];
                            });
                            loadWeather();
                            Navigator.pop(context); // Isasara ang bottom sheet nang kusa
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String conditionText = weatherData?["current"]?["condition"]?["text"] ?? "Clear";
    final List<Color> bgTheme = getBGGradient(conditionText);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: bgTheme,
          ),
        ),
        child: SafeArea(
          child: isError
              ? _buildErrorScreen()
              : weatherData == null
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : _buildiOSWeatherBody(),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) {
          if (index == 1) {
            Navigator.pop(context);
          } else {
            handleNavbarButtonTap(
              context,
              index,
              onHomeSelected: () => Navigator.pop(context),
              onWeatherSelected: () {
                if (mounted) setState(() => selectedIndex = 2);
              },
            );
          }
        },
        selectedItemColor: Colors.green[800],
        unselectedItemColor: Colors.black54,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.cloud), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: ""),
        ],
      ),
    );
  }

  Widget _buildiOSWeatherBody() {
    final current = weatherData!["current"];
    final location = weatherData!["location"];
    
    final forecastDay = weatherData!["forecast"]?["forecastday"];
    int rainChance = 0;
    if (forecastDay != null && forecastDay.isNotEmpty) {
      rainChance = num.tryParse(forecastDay[0]["day"]["daily_chance_of_rain"].toString())?.toInt() ?? 0;
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          /// 🔥 BAGONG DESIGNED SELECTOR CHIP (Pinalitan ang Dropdown)
          GestureDetector(
            onTap: () => _showMountainPicker(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on, color: Colors.white70, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    selectedMountain,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.unfold_more, color: Colors.white70, size: 18),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),

          /// MAIN DISPLAY
          Text(selectedMountain, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w500)),
          Text("${current["temp_c"]}°", style: const TextStyle(color: Colors.white, fontSize: 84, fontWeight: FontWeight.w200)),
          Text(current["condition"]["text"].toString().toUpperCase(), style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
          const SizedBox(height: 5),
          Text("Region: ${location["name"]}", style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14)),

          const SizedBox(height: 25),

          /// HIKING STATUS CARD
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Text(getHikingStatus(rainChance), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
          ),

          const SizedBox(height: 20),

          /// 2x2 GRID DETAILS
          Row(
            children: [
              Expanded(child: _buildiOSInfoCard("HUMIDITY", "${current["humidity"]}%", Icons.water_drop)),
              const SizedBox(width: 15),
              Expanded(child: _buildiOSInfoCard("WIND", "${current["wind_kph"]} km/h", Icons.air)),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(child: _buildiOSInfoCard("RAIN CHANCE", "$rainChance%", Icons.umbrella)),
              const SizedBox(width: 15),
              Expanded(child: _buildiOSInfoCard("SAFETY INDEX", rainChance > 50 ? "LOW" : "HIGH", Icons.gpp_good)),
            ],
          ),

          const SizedBox(height: 25),

          /// FORECAST SECTION
          Align(
            alignment: Alignment.centerLeft,
            child: Text("FORECAST", style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          ),
          const SizedBox(height: 10),
          _buildForecastSection(),
        ],
      ),
    );
  }

  Widget _buildiOSInfoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white.withOpacity(0.6), size: 16),
              const SizedBox(width: 6),
              Text(title, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildForecastSection() {
    final forecastList = weatherData!["forecast"]?["forecastday"] as List?;
    if (forecastList == null || forecastList.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
        child: const Text("No forecast available", style: TextStyle(color: Colors.white70)),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: forecastList.length,
        separatorBuilder: (context, index) => Divider(color: Colors.white.withOpacity(0.1), height: 1),
        itemBuilder: (context, index) {
          final dayData = forecastList[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: const Icon(Icons.wb_cloudy_outlined, color: Colors.white),
            title: Text(dayData["date"] ?? "Today", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
            subtitle: Text(dayData["day"]?["condition"]?["text"] ?? "Clear", style: TextStyle(color: Colors.white.withOpacity(0.7))),
            trailing: Text("${dayData["day"]?["avgtemp_c"] ?? currentTemp}°C", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
          );
        },
      ),
    );
  }

  dynamic get currentTemp => weatherData!["current"]["temp_c"];

  Widget _buildErrorScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, color: Colors.white70, size: 64),
          const SizedBox(height: 16),
          const Text("Connection or Key Issue", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(errorMessage, style: const TextStyle(color: Colors.yellow, fontSize: 12), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: loadWeather, child: const Text("Retry")),
        ],
      ),
    );
  }
}