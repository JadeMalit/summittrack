import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'weather_condition_icon.dart';

class WeatherForecastCard extends StatelessWidget {
  const WeatherForecastCard({
    super.key,
    required this.dayLabel,
    required this.condition,
    required this.temperature,
    required this.accentColor,
  });

  final String dayLabel;
  final String condition;
  final String temperature;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = context.isDarkMode;
    final foreground = isDark ? colors.textPrimary : const Color(0xFF172033);
    final muted = isDark ? colors.textSecondary : const Color(0xFF5C6978);

    return Container(
      width: 132,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? colors.surfaceHigh.withValues(alpha: 0.78)
            : Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? colors.border : Colors.white.withValues(alpha: 0.78),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: isDark ? 0.72 : 0.42),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  weatherIconForCondition(condition),
                  size: 22,
                  color: accentColor,
                ),
              ),
              const Spacer(),
              Text(
                temperature,
                style: TextStyle(
                  color: foreground,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            dayLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: foreground,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            condition,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: muted,
              fontSize: 12,
              height: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
