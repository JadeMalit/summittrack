import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/weather_service.dart';
import '../models/scheduled_hike.dart';
import '../services/hike_schedule_store.dart';
import '../utils/mountain_schedule_identity.dart';
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
  static const double _floatingNavHeight = 56;
  static const double _floatingNavBottomMargin = 10;
  static const double _floatingNavTopGap = 18;

  final WeatherService weatherService = WeatherService();
  final HikeScheduleStore _scheduleStore = HikeScheduleStore.instance;

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

  final Map<String, List<double>> mountainCoordinates = {
    "Mount Apo": [6.9872, 125.3708],
    "Mount Pulag": [16.5983, 120.8986],
    "Mount Ulap": [16.2917, 120.6358],
    "Mount Manabu": [13.9782, 121.2215],
    "Mount Gulugod Baboy": [13.7119, 120.8988],
    "Mount Maynoba": [14.6333, 121.3167],
    "Mount Batulao": [14.0411, 120.8014],
    "Mount Daraitan": [14.6139, 121.4331],
    "Mount Arayat": [15.2011, 120.7422],
    "Mount Makiling": [14.1308, 121.1925],
    "Mount Pinatubo": [15.1428, 120.3506],
  };

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
    _scheduleStore.addListener(_handleScheduleChanged);
    _logWeatherSchedule('Refresh started');
    unawaited(
      _scheduleStore.load().whenComplete(() {
        _logWeatherSchedule(
          'Loaded schedules count: ${_scheduleStore.scheduledHikes.length}',
        );
      }),
    );
  }

  @override
  void dispose() {
    _scheduleStore.removeListener(_handleScheduleChanged);
    _entranceController.dispose();
    super.dispose();
  }

  void _handleScheduleChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});
    _logWeatherSchedule(
      'Loaded schedules count: ${_scheduleStore.scheduledHikes.length}',
    );
  }

  Future<void> loadWeather() async {
    try {
      setState(() {
        weatherData = null;
        isError = false;
      });

      final coords = mountainCoordinates[selectedMountain] ?? [6.9872, 125.3708];
      final data = await weatherService.fetch15DayWeather(coords[0], coords[1]);

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
    final expandedMountainIds = <String>{};

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final scheduledHikesByMountain = _scheduleStore.upcomingByMountain();

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
                            final mountainId =
                                MountainScheduleIdentity.idForWeatherName(
                              mountain,
                            );
                            final scheduledHikes =
                                scheduledHikesByMountain[mountainId] ??
                                const <ScheduledHike>[];
                            final isSelected = mountain == selectedMountain;
                            final isExpanded = expandedMountainIds.contains(
                              mountainId,
                            );

                            return _MountainPickerRow(
                              mountain: mountain,
                              isSelected: isSelected,
                              isExpanded: isExpanded,
                              scheduledHikes: scheduledHikes,
                              onSelect: () {
                                setState(() {
                                  selectedMountain = mountain;
                                });
                                Navigator.pop(context);
                                loadWeather();
                              },
                              onToggleSchedule: scheduledHikes.isEmpty
                                  ? null
                                  : () {
                                      setSheetState(() {
                                        if (isExpanded) {
                                          expandedMountainIds.remove(
                                            mountainId,
                                          );
                                        } else {
                                          expandedMountainIds.add(mountainId);
                                        }
                                      });
                                    },
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
      extendBody: true,
      backgroundColor: Colors.transparent,
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
          bottom: false,
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
    );
  }

  Widget _buildWeatherBody() {
    final current = weatherData!["current"];
    final condition = _conditionText(current) ?? "Clear";
    final rainChance = _rainChanceFromForecast();
    final safety = _safetyPresentation(rainChance);
    final accentColor = _conditionAccent(condition);
    
    final locationName = "Region: ${current["location_name"] ?? "Unknown"}";
    final nextHike = _nextScheduledHikeForSelectedMountain();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WeatherHeader(
            mountainName: selectedMountain,
            locationName: locationName,
            condition: _titleCase(condition),
            temperature: _temperatureText(current["temp"]),
            accentColor: accentColor,
            onSelectMountain: () => _showMountainPicker(context),
          ),
          if (nextHike != null) ...[
            const SizedBox(height: 14),
            _SlideUpSection(
              delay: const Duration(milliseconds: 40),
              child: _UpcomingHikeReminderCard(hike: nextHike),
            ),
          ],
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
                  value: "${current["wind_speed"] ?? "--"} km/h",
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
            child: _buildForecastSection(condition, current["temp"]),
          ),
        ],
      ),
    );
  }

  ScheduledHike? _nextScheduledHikeForSelectedMountain() {
    final mountainId = MountainScheduleIdentity.idForWeatherName(
      selectedMountain,
    );

    final nextHike = _scheduleStore.nextUpcomingForMountain(mountainId);
    if (nextHike != null) {
      _logWeatherSchedule('Matched mountain: $mountainId');
      _logWeatherSchedule(
        'Matched date: ${ScheduledHike.dateKey(nextHike.hikeDate)}',
      );
    }

    return nextHike;
  }

  static void _logWeatherSchedule(String message) {
    if (kDebugMode) {
      debugPrint('[WeatherSchedule] $message');
    }
  }

  Widget _buildForecastSection(String fallbackCondition, dynamic fallbackTemp) {
    final forecastList = weatherData!["forecast"] as List?;

    if (forecastList == null || forecastList.isEmpty) {
      return _EmptyForecastCard(color: _sectionTitleColor(context));
    }

    int globalMin = 100;
    int globalMax = -100;
    for (var day in forecastList) {
      final int minT = (day['temp_min'] as num?)?.round() ?? 20;
      final int maxT = (day['temp_max'] as num?)?.round() ?? 35;
      if (minT < globalMin) globalMin = minT;
      if (maxT > globalMax) globalMax = maxT;
    }
    if (globalMax == globalMin) globalMax += 1;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08), 
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month_rounded, size: 14, color: Colors.white.withValues(alpha: 0.5)),
              const SizedBox(width: 8),
              Text(
                "15-DAY FORECAST",
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.5),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: forecastList.length,
            separatorBuilder: (context, index) => Divider(
              color: Colors.white.withValues(alpha: 0.08),
              height: 1,
            ),
            itemBuilder: (context, index) {
              final dayData = forecastList[index];
              final int wmoCode = dayData["weather_code"] ?? 0;
              final condition = _interpretWmoCode(wmoCode);
              
              final int minTemp = (dayData["temp_min"] as num?)?.round() ?? 24;
              final int maxTemp = (dayData["temp_max"] as num?)?.round() ?? 32;
              final int rainChance = (dayData["rain_chance"] as num?)?.round() ?? 0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 65,
                      child: Text(
                        _forecastDayLabel(dayData, index),
                        style: GoogleFonts.poppins(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 55,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _iconForPreviewCondition(condition),
                            color: Colors.white,
                            size: 22,
                          ),
                          if (rainChance >= 20) ...[
                            const SizedBox(height: 2),
                            Text(
                              "$rainChance%",
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF3CD1FF),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 32,
                      child: Text(
                        "$minTemp°",
                        style: GoogleFonts.poppins(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final double totalWidth = constraints.maxWidth;
                            final double startPct = (minTemp - globalMin) / (globalMax - globalMin);
                            final double endPct = (maxTemp - globalMin) / (globalMax - globalMin);
                            
                            final double leftPadding = startPct * totalWidth;
                            final double barWidth = (endPct - startPct) * totalWidth;

                            return Stack(
                              alignment: Alignment.centerLeft,
                              children: [
                                Container(
                                  height: 4,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                Positioned(
                                  left: leftPadding,
                                  width: barWidth.clamp(6.0, totalWidth),
                                  child: Container(
                                    height: 4,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(2),
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFFF9500),
                                          Color(0xFFFFB300),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 32,
                      child: Text(
                        "$maxTemp°",
                        textAlign: TextAlign.right,
                        style: GoogleFonts.poppins(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  IconData _iconForPreviewCondition(String condition) {
    final lower = condition.toLowerCase();
    if (lower.contains('thunderstorm')) return Icons.thunderstorm_rounded;
    if (lower.contains('rain') || lower.contains('drizzle') || lower.contains('showers')) {
      return Icons.umbrella_rounded;
    }
    if (lower.contains('clear') || lower.contains('sun')) return Icons.wb_sunny_rounded;
    if (lower.contains('cloud') || lower.contains('overcast')) return Icons.wb_cloudy_rounded;
    return Icons.cloud_rounded;
  }

  int _rainChanceFromForecast() {
    final forecast = weatherData!["forecast"];
    if (forecast is List && forecast.isNotEmpty) {
      final firstDay = forecast.first;
      return (firstDay["rain_chance"] as num?)?.toInt() ?? 0;
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

  String _forecastDayLabel(dynamic dayData, int index) {
    if (index == 0) return "Today";
    
    final dateValue = dayData is Map ? dayData["date"] : null;
    final parsedDate = DateTime.tryParse(dateValue?.toString() ?? "");
    if (parsedDate == null) {
      return "Day ${index + 1}";
    }

    const days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    return days[parsedDate.weekday - 1];
  }

  String? _conditionText(dynamic current) {
    if (current is! Map) return null;
    return current["condition"]?.toString();
  }

  String _temperatureText(dynamic value, {bool includeCelsius = false}) {
    final temp = num.tryParse(value.toString());
    if (temp == null) return includeCelsius ? "--\u00B0C" : "--\u00B0";

    final suffix = includeCelsius ? "\u00B0C" : "\u00B0";
    return "${temp.round()}$suffix";
  }

  String _interpretWmoCode(int code) {
    if (code == 0) return "Clear";
    if (code >= 1 && code <= 3) return "Partly Cloudy";
    if (code == 45 || code == 48) return "Foggy";
    if (code >= 51 && code <= 55) return "Drizzle";
    if (code >= 61 && code <= 65) return "Rainy";
    if (code >= 80 && code <= 82) return "Showers";
    if (code >= 95 && code <= 99) return "Thunderstorm";
    return "Cloudy";
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
        condition.contains("showers") ||
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

class _UpcomingHikeReminderCard extends StatelessWidget {
  const _UpcomingHikeReminderCard({required this.hike});

  final ScheduledHike hike;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isToday = _isSameDate(hike.hikeDate, DateTime.now());
    final accent = isToday ? colors.warning : colors.accent;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? colors.surfaceHigh.withValues(alpha: 0.86)
            : Colors.white.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: accent.withValues(alpha: isToday ? 0.45 : 0.24),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.42),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: context.isDarkMode ? 0.22 : 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isToday ? Icons.hiking_rounded : Icons.event_available_rounded,
              color: accent,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isToday ? 'Hike Today' : 'Upcoming Hike',
                  style: TextStyle(
                    color: accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isToday ? hike.trailName : _formatFullHikeDate(hike.hikeDate),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isToday ? hike.mountainName : hike.trailName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MountainPickerRow extends StatelessWidget {
  const _MountainPickerRow({
    required this.mountain,
    required this.isSelected,
    required this.isExpanded,
    required this.scheduledHikes,
    required this.onSelect,
    required this.onToggleSchedule,
  });

  final String mountain;
  final bool isSelected;
  final bool isExpanded;
  final List<ScheduledHike> scheduledHikes;
  final VoidCallback onSelect;
  final VoidCallback? onToggleSchedule;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final hasSchedule = scheduledHikes.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: isSelected
            ? colors.accent.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            InkWell(
              onTap: onSelect,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  hasSchedule ? 11 : 12,
                  hasSchedule ? 8 : 14,
                  hasSchedule ? 11 : 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.hiking_rounded,
                      color: isSelected ? colors.accent : colors.textSecondary,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        mountain,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isSelected
                              ? colors.textPrimary
                              : colors.textSecondary,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                    if (hasSchedule) ...[
                      const SizedBox(width: 8),
                      _ScheduleDateBadge(date: scheduledHikes.first.hikeDate),
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: onToggleSchedule,
                        tooltip: isExpanded
                            ? 'Hide scheduled hikes'
                            : 'Show scheduled hikes',
                        constraints: const BoxConstraints.tightFor(
                          width: 34,
                          height: 34,
                        ),
                        padding: EdgeInsets.zero,
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            key: ValueKey(isExpanded),
                            color: colors.accent,
                          ),
                        ),
                      ),
                    ] else
                      SizedBox(
                        width: 34,
                        height: 34,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: Icon(
                            isSelected
                                ? Icons.check_circle_rounded
                                : Icons.circle_outlined,
                            key: ValueKey(isSelected),
                            color: isSelected ? colors.accent : colors.divider,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: hasSchedule && isExpanded
                  ? _MountainScheduleDetails(scheduledHikes: scheduledHikes)
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleDateBadge extends StatelessWidget {
  const _ScheduleDateBadge({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: colors.accent.withValues(
          alpha: context.isDarkMode ? 0.18 : 0.12,
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _formatShortHikeDate(date),
        style: TextStyle(
          color: colors.accent,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MountainScheduleDetails extends StatelessWidget {
  const _MountainScheduleDetails({required this.scheduledHikes});

  final List<ScheduledHike> scheduledHikes;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(56, 0, 14, 12),
      child: Column(
        children: [
          for (var index = 0; index < scheduledHikes.length; index++)
            _MountainScheduleItem(
              hike: scheduledHikes[index],
              showTopPadding: index > 0,
            ),
        ],
      ),
    );
  }
}

class _MountainScheduleItem extends StatelessWidget {
  const _MountainScheduleItem({
    required this.hike,
    required this.showTopPadding,
  });

  final ScheduledHike hike;
  final bool showTopPadding;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: EdgeInsets.only(top: showTopPadding ? 9 : 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: colors.accent.withValues(alpha: 0.85),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatFullHikeDate(hike.hikeDate),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hike.trailName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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

bool _isSameDate(DateTime d1, DateTime d2) {
  return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
}

String _formatFullHikeDate(DateTime date) {
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  return "${months[date.month - 1]} ${date.day}, ${date.year}";
}

String _formatShortHikeDate(DateTime date) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return "${months[date.month - 1]} ${date.day}";
}