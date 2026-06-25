import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'weather_condition_icon.dart';

class WeatherHeader extends StatelessWidget {
  const WeatherHeader({
    super.key,
    required this.mountainName,
    required this.locationName,
    required this.condition,
    required this.temperature,
    required this.accentColor,
    required this.onSelectMountain,
  });

  final String mountainName;
  final String locationName;
  final String condition;
  final String temperature;
  final Color accentColor;
  final VoidCallback onSelectMountain;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = context.isDarkMode;
    final foreground = isDark ? colors.textPrimary : Colors.white;
    final muted = isDark
        ? colors.textSecondary
        : Colors.white.withValues(alpha: 0.78);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
      decoration: BoxDecoration(
        color: isDark
            ? colors.surfaceHigh.withValues(alpha: 0.84)
            : Colors.white.withValues(alpha: 0.17),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isDark ? colors.border : Colors.white.withValues(alpha: 0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: isDark ? 0.72 : 0.36),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Weather',
                  style: TextStyle(
                    color: muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _MountainSelectorButton(
                label: mountainName,
                foreground: foreground,
                background: isDark
                    ? colors.surface.withValues(alpha: 0.72)
                    : Colors.white.withValues(alpha: 0.16),
                borderColor: foreground.withValues(alpha: 0.18),
                onTap: onSelectMountain,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mountainName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 26,
                        height: 1.05,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, size: 16, color: muted),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            locationName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: muted,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      temperature,
                      maxLines: 1,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 72,
                        height: 0.88,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      condition,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: muted,
                        fontSize: 15,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              WeatherConditionIcon(
                condition: condition,
                accentColor: accentColor,
                foregroundColor: foreground,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MountainSelectorButton extends StatelessWidget {
  const _MountainSelectorButton({
    required this.label,
    required this.foreground,
    required this.background,
    required this.borderColor,
    required this.onTap,
  });

  final String label;
  final Color foreground;
  final Color background;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 168),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.hiking_rounded, size: 16, color: foreground),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 3),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: foreground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
