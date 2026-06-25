import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class WeatherStatCard extends StatelessWidget {
  const WeatherStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.caption,
    required this.icon,
    required this.accentColor,
  });

  final String title;
  final String value;
  final String caption;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = context.isDarkMode;
    final foreground = isDark ? colors.textPrimary : const Color(0xFF172033);
    final muted = isDark ? colors.textSecondary : const Color(0xFF66727C);

    return Container(
      constraints: const BoxConstraints(minHeight: 124),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? colors.surfaceHigh.withValues(alpha: 0.78)
            : Colors.white.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? colors.border : Colors.white.withValues(alpha: 0.72),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: isDark ? 0.62 : 0.3),
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
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, size: 19, color: accentColor),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                color: foreground,
                fontSize: 25,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: muted,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
