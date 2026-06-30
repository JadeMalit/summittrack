import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/weather_service.dart';
import '../../navigation/button_functions/navbar_button_function.dart';
import '../../navigation/widgets/main_bottom_navbar.dart';
import '../widgets/weather/weather_forecast_card.dart';
import '../widgets/weather/weather_header.dart';
import '../widgets/weather/weather_safety_card.dart';
import '../widgets/weather/weather_stat_card.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen>
    with SingleTickerProviderStateMixin {
  final WeatherService weatherService = WeatherService();
  int selectedIndex = weatherNavbarIndex;
  int _navTapSequence = 0;
  int _lastTappedNavIndex = weatherNavbarIndex;

  final List<String> mountains = [
    "Mount Ulap",
    "Mount Manabu",
    "Mount Gulugod Baboy",
    "Mount Maynoba",
    "Mount Cutuno",
    "Mount Lingguhob",
    "Mount Batulao",
    "Mount Daraitan",
    "Mount Arayat",
    "Mount Makiling",
    "Mount Damas",
    "Mount Tugew",
    "Mount Mariglem",
    "Mount Pinatubo",
    "Mount Pulag",
    "Mount Apo",
    "Mount Tapulao",
    "Mount Espadang Bato",
    "Mount Hibok-Hibok",
    "Mount Kitanglad",
  ];

  String selectedMountain = "Mount Apo";
  Map<String, dynamic>? weatherData;
  bool isError = false;
  String errorMessage = "";

  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Curves.easeOutCubic,
          ),
        );

    loadWeather();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
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
        _entranceController.forward(from: 0);
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

  void updateSelectedIndex(int index, {bool isUserTap = false}) {
    if (!mounted) {
      return;
    }

    setState(() {
      selectedIndex = index;
      _lastTappedNavIndex = index;

      if (isUserTap) {
        _navTapSequence++;
      }
    });
  }

  Future<void> _handleBottomNavigationTap(int index) async {
    updateSelectedIndex(index, isUserTap: true);

    if (index == homeNavbarIndex) {
      Navigator.pop(context);
      return;
    }

    await handleNavbarButtonTap(
      context,
      index,
      onHomeSelected: () {
        Navigator.pop(context);
      },
      onWeatherSelected: () {
        updateSelectedIndex(weatherNavbarIndex);
      },
    );

    if (!mounted) {
      return;
    }

    updateSelectedIndex(weatherNavbarIndex);
  }

  String getHikingStatus(int rainChance) {
    if (rainChance < 40) return "Recommended";
    if (rainChance < 70) return "Use Caution";
    return "Not Recommended";
  }

  List<Color> getBGGradient(String condition, BuildContext context) {
    final colors = context.appColors;
    final cond = condition.toLowerCase();

    if (context.isDarkMode) {
      if (_isRainy(cond)) {
        return [
          const Color(0xFF09131D),
          const Color(0xFF17293A),
          colors.background,
        ];
      }
      if (_isCloudy(cond)) {
        return [
          const Color(0xFF101820),
          const Color(0xFF24313A),
          colors.background,
        ];
      }
      return [
        const Color(0xFF081D17),
        const Color(0xFF123B2A),
        colors.background,
      ];
    }

    if (_isRainy(cond)) {
      return [
        const Color(0xFF263D55),
        const Color(0xFF607D97),
        const Color(0xFFE8F0F4),
      ];
    }
    if (_isCloudy(cond)) {
      return [
        const Color(0xFF55728C),
        const Color(0xFFA9BBC8),
        const Color(0xFFEAF2F3),
      ];
    }
    if (_isFoggy(cond)) {
      return [
        const Color(0xFF6B7D83),
        const Color(0xFFB2C2C2),
        const Color(0xFFEFF5EF),
      ];
    }
    return [
      const Color(0xFF2E91C7),
      const Color(0xFF8ED3F4),
      const Color(0xFFFFE3A1),
    ];
  }

  void _showMountainPicker(BuildContext context) {
    final colors = context.appColors;
    final isDark = context.isDarkMode;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          top: false,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 18 * (1 - value)),
                child: Opacity(opacity: value, child: child),
              );
            },
            child: Container(
              height: MediaQuery.of(context).size.height * 0.5,
              decoration: BoxDecoration(
                color: isDark ? colors.surface : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow.withValues(alpha: 0.7),
                    blurRadius: 28,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: colors.divider,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: colors.accent.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.terrain_rounded,
                            color: colors.accent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Select Mountain",
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(color: colors.divider, height: 1),
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      itemCount: mountains.length,
                      itemBuilder: (context, index) {
                        final mountain = mountains[index];
                        final isSelected = mountain == selectedMountain;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Material(
                            color: isSelected
                                ? colors.accent.withValues(alpha: 0.12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            child: ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              leading: Icon(
                                Icons.hiking_rounded,
                                color: isSelected
                                    ? colors.accent
                                    : colors.textSecondary,
                              ),
                              title: Text(
                                mountain,
                                style: TextStyle(
                                  color: isSelected
                                      ? colors.textPrimary
                                      : colors.textSecondary,
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                ),
                              ),
                              trailing: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 180),
                                child: Icon(
                                  isSelected
                                      ? Icons.check_circle_rounded
                                      : Icons.circle_outlined,
                                  key: ValueKey(isSelected),
                                  color: isSelected
                                      ? colors.accent
                                      : colors.divider,
                                ),
                              ),
                              onTap: () {
                                setState(() {
                                  selectedMountain = mountain;
                                });
                                Navigator.pop(context);
                                loadWeather();
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final String conditionText =
        _conditionText(weatherData?["current"]) ?? "Clear";
    final List<Color> bgTheme = getBGGradient(conditionText, context);

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: bgTheme,
          ),
        ),
        child: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: isError
                ? _buildErrorScreen(key: const ValueKey("weather-error"))
                : weatherData == null
                ? _buildLoadingScreen(
                    colors,
                    key: const ValueKey("weather-loading"),
                  )
                : FadeTransition(
                    key: ValueKey("weather-body-$selectedMountain"),
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: _buildWeatherBody(),
                    ),
                  ),
          ),
        ),
      ),
      bottomNavigationBar: MainBottomNavbar(
        currentIndex: selectedIndex,
        tapSequence: _navTapSequence,
        lastTappedIndex: _lastTappedNavIndex,
        onTap: _handleBottomNavigationTap,
      ),
    );
  }

  Widget _buildWeatherBody() {
    final current = weatherData!["current"];
    final location = weatherData!["location"];
    final condition = _conditionText(current) ?? "Clear";
    final rainChance = _rainChanceFromForecast();
    final safety = _safetyPresentation(rainChance);
    final accentColor = _conditionAccent(condition);
    final locationName = _locationName(location);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WeatherHeader(
            mountainName: selectedMountain,
            locationName: locationName,
            condition: _titleCase(condition),
            temperature: _temperatureText(current["temp_c"]),
            accentColor: accentColor,
            onSelectMountain: () => _showMountainPicker(context),
          ),
          const SizedBox(height: 18),
          _SlideUpSection(
            delay: const Duration(milliseconds: 60),
            child: WeatherSafetyCard(
              title: safety.title,
              message: safety.message,
              rainChance: "$rainChance%",
              icon: safety.icon,
              statusColor: safety.color,
            ),
          ),
          const SizedBox(height: 22),
          _SectionTitle(
            title: "Trail Conditions",
            color: _sectionTitleColor(context),
          ),
          const SizedBox(height: 12),
          _SlideUpSection(
            delay: const Duration(milliseconds: 120),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.15,
              children: [
                WeatherStatCard(
                  title: "Humidity",
                  value: "${current["humidity"] ?? "--"}%",
                  caption: "Air moisture",
                  icon: Icons.water_drop_rounded,
                  accentColor: const Color(0xFF2E91C7),
                ),
                WeatherStatCard(
                  title: "Wind",
                  value: "${current["wind_kph"] ?? "--"} km/h",
                  caption: "Trail exposure",
                  icon: Icons.air_rounded,
                  accentColor: const Color(0xFF6C7A89),
                ),
                WeatherStatCard(
                  title: "Rain Chance",
                  value: "$rainChance%",
                  caption: "Expected precipitation",
                  icon: Icons.umbrella_rounded,
                  accentColor: safety.color,
                ),
                WeatherStatCard(
                  title: "Safety Index",
                  value: _safetyIndexText(rainChance),
                  caption: getHikingStatus(rainChance),
                  icon: Icons.shield_rounded,
                  accentColor: safety.color,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SectionTitle(title: "Forecast", color: _sectionTitleColor(context)),
          const SizedBox(height: 12),
          _SlideUpSection(
            delay: const Duration(milliseconds: 180),
            child: _buildForecastSection(condition, current["temp_c"]),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastSection(String fallbackCondition, dynamic fallbackTemp) {
    final forecastList = weatherData!["forecast"]?["forecastday"] as List?;

    if (forecastList == null || forecastList.isEmpty) {
      return _EmptyForecastCard(color: _sectionTitleColor(context));
    }

    return SizedBox(
      height: 146,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: forecastList.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final dayData = forecastList[index];
          final condition = _forecastCondition(dayData, fallbackCondition);
          return WeatherForecastCard(
            dayLabel: _forecastDayLabel(dayData, index),
            condition: _titleCase(condition),
            temperature: _temperatureText(
              _forecastTemperature(dayData, fallbackTemp),
              includeCelsius: true,
            ),
            accentColor: _conditionAccent(condition),
          );
        },
      ),
    );
  }

  Widget _buildLoadingScreen(AppColors colors, {Key? key}) {
    final foreground = context.isDarkMode ? colors.textPrimary : Colors.white;

    return Center(
      key: key,
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
        decoration: BoxDecoration(
          color: context.isDarkMode
              ? colors.surfaceHigh.withValues(alpha: 0.82)
              : Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: foreground.withValues(alpha: 0.18)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: foreground, strokeWidth: 3),
            const SizedBox(height: 16),
            Text(
              "Checking mountain weather",
              style: TextStyle(
                color: foreground,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen({Key? key}) {
    final colors = context.appColors;
    final foreground = context.isDarkMode ? colors.textPrimary : Colors.white;
    final muted = context.isDarkMode
        ? colors.textSecondary
        : Colors.white.withValues(alpha: 0.78);

    return Center(
      key: key,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: context.isDarkMode
                ? colors.surfaceHigh.withValues(alpha: 0.88)
                : Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: foreground.withValues(alpha: 0.18)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colors.danger.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(
                  Icons.cloud_off_rounded,
                  color: colors.danger,
                  size: 34,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Weather Unavailable",
                style: TextStyle(
                  color: foreground,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage,
                style: TextStyle(
                  color: muted,
                  fontSize: 12.5,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: loadWeather,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text("Retry"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _rainChanceFromForecast() {
    final forecastDay = weatherData!["forecast"]?["forecastday"];
    if (forecastDay is List && forecastDay.isNotEmpty) {
      final firstDay = forecastDay.first;
      final day = firstDay is Map ? firstDay["day"] : null;
      final value = day is Map ? day["daily_chance_of_rain"] : null;
      final parsed = num.tryParse(value.toString());
      if (parsed == null) return 0;
      return parsed.clamp(0, 100).toInt();
    }
    return 0;
  }

  _SafetyPresentation _safetyPresentation(int rainChance) {
    final colors = context.appColors;

    if (rainChance < 40) {
      return _SafetyPresentation(
        title: "Recommended",
        message: "Conditions look favorable for hiking today.",
        color: colors.accent,
        icon: Icons.verified_rounded,
      );
    }

    if (rainChance < 70) {
      return _SafetyPresentation(
        title: "Use Caution",
        message: "Pack rain protection and monitor trail conditions.",
        color: colors.warning,
        icon: Icons.warning_amber_rounded,
      );
    }

    return _SafetyPresentation(
      title: "Not Recommended",
      message: "Weather conditions may not be safe for hiking today.",
      color: colors.danger,
      icon: Icons.report_problem_rounded,
    );
  }

  String _safetyIndexText(int rainChance) {
    if (rainChance < 40) return "High";
    if (rainChance < 70) return "Fair";
    return "Low";
  }

  Color _conditionAccent(String condition) {
    final cond = condition.toLowerCase();
    if (_isRainy(cond)) return const Color(0xFF4F7FA2);
    if (_isCloudy(cond)) return const Color(0xFF6E8290);
    if (_isFoggy(cond)) return const Color(0xFF7C8C8A);
    return const Color(0xFFFFB84D);
  }

  Color _sectionTitleColor(BuildContext context) {
    final colors = context.appColors;
    return context.isDarkMode ? colors.textSecondary : const Color(0xFF273B45);
  }

  dynamic _forecastTemperature(dynamic dayData, dynamic fallbackTemp) {
    final day = dayData is Map ? dayData["day"] : null;
    if (day is Map) {
      return day["avgtemp_c"] ??
          day["maxtemp_c"] ??
          day["temp_c"] ??
          fallbackTemp;
    }
    return fallbackTemp;
  }

  String _forecastCondition(dynamic dayData, String fallbackCondition) {
    final day = dayData is Map ? dayData["day"] : null;
    final condition = day is Map ? day["condition"] : null;
    if (condition is Map && condition["text"] != null) {
      return condition["text"].toString();
    }
    return fallbackCondition;
  }

  String _forecastDayLabel(dynamic dayData, int index) {
    final dateValue = dayData is Map ? dayData["date"] : null;
    final parsedDate = DateTime.tryParse(dateValue?.toString() ?? "");
    if (parsedDate == null) {
      return index == 0 ? "Today" : "Day ${index + 1}";
    }

    if (index == 0) return "Today";

    const days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    return days[parsedDate.weekday - 1];
  }

  String _locationName(dynamic location) {
    if (location is Map && location["name"] != null) {
      return "Region: ${location["name"]}";
    }
    return "Region unavailable";
  }

  String? _conditionText(dynamic current) {
    if (current is! Map) return null;
    final condition = current["condition"];
    if (condition is Map && condition["text"] != null) {
      return condition["text"].toString();
    }
    return null;
  }

  String _temperatureText(dynamic value, {bool includeCelsius = false}) {
    final temp = num.tryParse(value.toString());
    if (temp == null) return includeCelsius ? "--\u00B0C" : "--\u00B0";

    final suffix = includeCelsius ? "\u00B0C" : "\u00B0";
    return "${temp.round()}$suffix";
  }

  String _titleCase(String value) {
    return value
        .split(" ")
        .where((word) => word.isNotEmpty)
        .map((word) {
          final lower = word.toLowerCase();
          return "${lower[0].toUpperCase()}${lower.substring(1)}";
        })
        .join(" ");
  }

  bool _isRainy(String condition) {
    return condition.contains("rain") ||
        condition.contains("drizzle") ||
        condition.contains("thunder") ||
        condition.contains("storm");
  }

  bool _isCloudy(String condition) {
    return condition.contains("cloud") || condition.contains("overcast");
  }

  bool _isFoggy(String condition) {
    return condition.contains("mist") ||
        condition.contains("fog") ||
        condition.contains("haze") ||
        condition.contains("smoke");
  }
}

class _SafetyPresentation {
  const _SafetyPresentation({
    required this.title,
    required this.message,
    required this.color,
    required this.icon,
  });

  final String title;
  final String message;
  final Color color;
  final IconData icon;
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.color});

  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w900),
    );
  }
}

class _SlideUpSection extends StatelessWidget {
  const _SlideUpSection({required this.child, required this.delay});

  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    const animationMs = 420;
    final totalMs = animationMs + delay.inMilliseconds;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: totalMs),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final delayedProgress =
            ((value * totalMs) - delay.inMilliseconds) / animationMs;
        final progress = delayedProgress.clamp(0.0, 1.0).toDouble();

        return Transform.translate(
          offset: Offset(0, 18 * (1 - progress)),
          child: Opacity(opacity: progress, child: child),
        );
      },
      child: child,
    );
  }
}

class _EmptyForecastCard extends StatelessWidget {
  const _EmptyForecastCard({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = context.isDarkMode;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? colors.surfaceHigh.withValues(alpha: 0.78)
            : Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? colors.border : Colors.white.withValues(alpha: 0.7),
        ),
      ),
      child: Text(
        "No forecast available",
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
