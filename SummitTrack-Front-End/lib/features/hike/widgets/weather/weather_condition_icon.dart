import 'package:flutter/material.dart';

import '../../../../core/layout/app_responsive.dart';

IconData weatherIconForCondition(String condition) {
  final value = condition.toLowerCase();

  if (value.contains('thunder') || value.contains('storm')) {
    return Icons.thunderstorm_rounded;
  }
  if (value.contains('rain') || value.contains('drizzle')) {
    return Icons.water_drop_rounded;
  }
  if (value.contains('snow') || value.contains('sleet')) {
    return Icons.ac_unit_rounded;
  }
  if (value.contains('cloud') || value.contains('overcast')) {
    return Icons.cloud_rounded;
  }
  if (value.contains('mist') ||
      value.contains('fog') ||
      value.contains('haze') ||
      value.contains('smoke')) {
    return Icons.blur_on_rounded;
  }
  return Icons.wb_sunny_rounded;
}

class WeatherConditionIcon extends StatelessWidget {
  const WeatherConditionIcon({
    super.key,
    required this.condition,
    required this.accentColor,
    required this.foregroundColor,
  });

  final String condition;
  final Color accentColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    final compact = AppResponsive.isCompactWidth(context);
    final size = compact ? 86.0 : 104.0;
    final terrainIconSize = compact ? 38.0 : 46.0;
    final weatherIconSize = compact ? 46.0 : 56.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(compact ? 26 : 32),
        border: Border.all(color: foregroundColor.withValues(alpha: 0.18)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: compact ? 12 : 14,
            child: Icon(
              Icons.terrain_rounded,
              size: terrainIconSize,
              color: foregroundColor.withValues(alpha: 0.16),
            ),
          ),
          Icon(
            weatherIconForCondition(condition),
            size: weatherIconSize,
            color: foregroundColor,
          ),
        ],
      ),
    );
  }
}
