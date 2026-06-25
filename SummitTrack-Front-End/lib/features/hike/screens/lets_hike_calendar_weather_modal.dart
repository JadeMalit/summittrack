import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/weather_service.dart';

Future<DateTime?> showLetsHikeCalendarWeatherModal({
  required BuildContext context,
  required String trailName,
}) {
  return showDialog<DateTime>(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return LetsHikeCalendarWeatherModal(trailName: trailName);
    },
  );
}

class LetsHikeCalendarWeatherModal extends StatefulWidget {
  const LetsHikeCalendarWeatherModal({super.key, required this.trailName});

  final String trailName;

  @override
  State<LetsHikeCalendarWeatherModal> createState() =>
      _LetsHikeCalendarWeatherModalState();
}

class _LetsHikeCalendarWeatherModalState
    extends State<LetsHikeCalendarWeatherModal> {
  static const Color _panelColor = Color(0xFF0B120D);
  static const Color _cardColor = Color(0xFF121C14);
  static const Color _accentColor = Color(0xFF3FA65B);
  static const Color _mutedTextColor = Color(0xFFB8C7B7);

  final WeatherService _weatherService = WeatherService();
  late DateTime _selectedDate;
  late DateTime _visibleMonth;
  _WeatherPreviewData? _currentWeatherData;
  bool _isLoadingWeather = true;

  @override
  void initState() {
    super.initState();
    final today = _dateOnly(DateTime.now());
    _selectedDate = today;
    _visibleMonth = DateTime(today.year, today.month);
    _loadCurrentWeather();
  }

  Future<void> _loadCurrentWeather() async {
    try {
      final weatherData = await _weatherService.getWeather(
        _weatherLookupName(widget.trailName),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _currentWeatherData = _WeatherPreviewData.fromService(weatherData);
        _isLoadingWeather = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _currentWeatherData = null;
        _isLoadingWeather = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final maxDialogHeight = screenSize.height * 0.88;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 430, maxHeight: maxDialogHeight),
        child: Container(
          decoration: BoxDecoration(
            color: _panelColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 28,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 18),
                  _buildCalendar(),
                  const SizedBox(height: 16),
                  _WeatherPreviewCard(
                    selectedDate: _selectedDate,
                    isLoading: _isLoadingWeather && _isToday(_selectedDate),
                    weather: _weatherForDate(_selectedDate),
                  ),
                  const SizedBox(height: 18),
                  _buildActions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Plan your hike',
                style: GoogleFonts.fredoka(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.trailName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  color: _mutedTextColor,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded, color: Colors.white70),
          tooltip: 'Close',
        ),
      ],
    );
  }

  Widget _buildCalendar() {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      child: Column(
        children: [
          Row(
            children: [
              _MonthNavButton(
                icon: Icons.chevron_left_rounded,
                onPressed: _goToPreviousMonth,
              ),
              Expanded(
                child: Text(
                  '${_monthNames[_visibleMonth.month - 1]} ${_visibleMonth.year}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _MonthNavButton(
                icon: Icons.chevron_right_rounded,
                onPressed: _goToNextMonth,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final weekday in _weekdayLabels)
                Expanded(
                  child: Text(
                    weekday,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: _mutedTextColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            mainAxisSpacing: 7,
            crossAxisSpacing: 7,
            physics: const NeverScrollableScrollPhysics(),
            children: _calendarCells()
                .map(
                  (date) => _CalendarDateCell(
                    date: date,
                    isSelected:
                        date != null && _isSameDate(date, _selectedDate),
                    isToday: date != null && _isToday(date),
                    isPast:
                        date != null &&
                        date.isBefore(_dateOnly(DateTime.now())),
                    onTap: date == null ? null : () => _selectDate(date),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(_selectedDate),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }

  List<DateTime?> _calendarCells() {
    final firstDay = DateTime(_visibleMonth.year, _visibleMonth.month);
    final totalDays = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + 1,
      0,
    ).day;
    final leadingBlankCells = firstDay.weekday % 7;
    final cells = <DateTime?>[
      for (var i = 0; i < leadingBlankCells; i++) null,
      for (var day = 1; day <= totalDays; day++)
        DateTime(_visibleMonth.year, _visibleMonth.month, day),
    ];

    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    return cells;
  }

  _WeatherPreviewData _weatherForDate(DateTime date) {
    if (_isToday(date) && _currentWeatherData != null) {
      return _currentWeatherData!;
    }

    return _WeatherPreviewData.mockFor(date);
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = _dateOnly(date);
    });
  }

  void _goToPreviousMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1);
    });
  }

  void _goToNextMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1);
    });
  }

  bool _isToday(DateTime date) {
    return _isSameDate(date, DateTime.now());
  }

  static bool _isSameDate(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static String _weatherLookupName(String trailName) {
    final normalizedTrailName = trailName.toLowerCase();
    if (normalizedTrailName.contains('apo') ||
        normalizedTrailName.contains('sta. cruz') ||
        normalizedTrailName.contains('sibulan')) {
      return 'Mount Apo';
    }

    if (trailName.startsWith('Mt. ')) {
      return trailName.replaceFirst('Mt. ', 'Mount ');
    }

    return trailName;
  }
}

class _WeatherPreviewCard extends StatelessWidget {
  const _WeatherPreviewCard({
    required this.selectedDate,
    required this.weather,
    required this.isLoading,
  });

  final DateTime selectedDate;
  final _WeatherPreviewData weather;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            weather.themeColor.withValues(alpha: 0.34),
            const Color(0xFF242233),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      padding: const EdgeInsets.all(16),
      child: isLoading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          : Row(
              children: [
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Icon(weather.icon, color: Colors.white, size: 36),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formattedDayDate(selectedDate),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        weather.condition,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFDEE0EA),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        'High ${weather.highTempC}\u00B0C / Low ${weather.lowTempC}\u00B0C',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.84),
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Chance of rain ${weather.rainChancePercent}%',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  static String _formattedDayDate(DateTime date) {
    final weekday = _fullWeekdayNames[date.weekday % 7];
    final month = _monthNames[date.month - 1];
    return '$weekday, $month ${date.day}';
  }
}

class _CalendarDateCell extends StatelessWidget {
  const _CalendarDateCell({
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.isPast,
    required this.onTap,
  });

  final DateTime? date;
  final bool isSelected;
  final bool isToday;
  final bool isPast;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (date == null) {
      return const SizedBox.shrink();
    }

    final textColor = isSelected
        ? Colors.white
        : isPast
        ? Colors.white.withValues(alpha: 0.28)
        : Colors.white.withValues(alpha: 0.88);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected
                ? _LetsHikeCalendarWeatherModalState._accentColor
                : Colors.transparent,
            border: isToday && !isSelected
                ? Border.all(
                    color: _LetsHikeCalendarWeatherModalState._accentColor,
                    width: 1.4,
                  )
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            '${date!.day}',
            style: GoogleFonts.poppins(
              color: textColor,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthNavButton extends StatelessWidget {
  const _MonthNavButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.08),
        minimumSize: const Size(38, 38),
      ),
    );
  }
}

class _WeatherPreviewData {
  const _WeatherPreviewData({
    required this.icon,
    required this.condition,
    required this.highTempC,
    required this.lowTempC,
    required this.rainChancePercent,
    required this.themeColor,
  });

  final IconData icon;
  final String condition;
  final int highTempC;
  final int lowTempC;
  final int rainChancePercent;
  final Color themeColor;

  factory _WeatherPreviewData.fromService(Map<String, dynamic> data) {
    final current = data['current'] as Map<String, dynamic>?;
    final forecast = data['forecast'] as Map<String, dynamic>?;
    final forecastDays = forecast?['forecastday'] as List<dynamic>?;
    final firstDay = forecastDays?.isNotEmpty == true
        ? forecastDays!.first as Map<String, dynamic>?
        : null;
    final day = firstDay?['day'] as Map<String, dynamic>?;
    final temp = _readInt(current?['temp_c'], fallback: 24);
    final condition = _titleCase(
      current?['condition'] is Map<String, dynamic>
          ? (current?['condition'] as Map<String, dynamic>)['text']?.toString()
          : null,
    );
    final rainChance = _readInt(
      day?['daily_chance_of_rain'],
      fallback: 28,
    ).clamp(0, 100).toInt();

    return _WeatherPreviewData(
      icon: _iconForCondition(condition),
      condition: condition,
      highTempC: temp + 3,
      lowTempC: temp - 4,
      rainChancePercent: rainChance,
      themeColor: _themeForCondition(condition),
    );
  }

  factory _WeatherPreviewData.mockFor(DateTime date) {
    final seed = date.year + date.month * 31 + date.day * 17;
    final options = <_WeatherPreviewData>[
      const _WeatherPreviewData(
        icon: Icons.wb_cloudy_rounded,
        condition: 'Partly Cloudy',
        highTempC: 24,
        lowTempC: 15,
        rainChancePercent: 25,
        themeColor: Color(0xFF6182F2),
      ),
      const _WeatherPreviewData(
        icon: Icons.wb_sunny_rounded,
        condition: 'Mostly Sunny',
        highTempC: 27,
        lowTempC: 17,
        rainChancePercent: 12,
        themeColor: Color(0xFFF0A93B),
      ),
      const _WeatherPreviewData(
        icon: Icons.water_drop_rounded,
        condition: 'Light Rain',
        highTempC: 22,
        lowTempC: 16,
        rainChancePercent: 58,
        themeColor: Color(0xFF3C83A8),
      ),
      const _WeatherPreviewData(
        icon: Icons.cloud_rounded,
        condition: 'Overcast',
        highTempC: 23,
        lowTempC: 14,
        rainChancePercent: 38,
        themeColor: Color(0xFF667085),
      ),
    ];

    return options[seed % options.length];
  }

  static int _readInt(Object? value, {required int fallback}) {
    if (value is num) {
      return value.round();
    }

    return num.tryParse(value?.toString() ?? '')?.round() ?? fallback;
  }

  static String _titleCase(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) {
      return 'Partly Cloudy';
    }

    return text
        .split(RegExp(r'\s+'))
        .map((word) {
          if (word.isEmpty) {
            return word;
          }

          return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
        })
        .join(' ');
  }

  static IconData _iconForCondition(String condition) {
    final lowerCondition = condition.toLowerCase();
    if (lowerCondition.contains('rain') || lowerCondition.contains('drizzle')) {
      return Icons.water_drop_rounded;
    }
    if (lowerCondition.contains('storm') ||
        lowerCondition.contains('thunder')) {
      return Icons.thunderstorm_rounded;
    }
    if (lowerCondition.contains('clear') || lowerCondition.contains('sun')) {
      return Icons.wb_sunny_rounded;
    }
    return Icons.wb_cloudy_rounded;
  }

  static Color _themeForCondition(String condition) {
    final lowerCondition = condition.toLowerCase();
    if (lowerCondition.contains('rain') || lowerCondition.contains('storm')) {
      return const Color(0xFF3C83A8);
    }
    if (lowerCondition.contains('clear') || lowerCondition.contains('sun')) {
      return const Color(0xFFF0A93B);
    }
    return const Color(0xFF6182F2);
  }
}

const List<String> _weekdayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

const List<String> _fullWeekdayNames = [
  'Sunday',
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
];

const List<String> _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];
