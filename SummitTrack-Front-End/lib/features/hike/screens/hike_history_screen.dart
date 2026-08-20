import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../services/hike_schedule_store.dart';
import '../services/hike_stats_service.dart';

class HikeHistoryScreen extends StatelessWidget {
  const HikeHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: colors.surface,
          elevation: 0,
          title: Text(
            'Hiker Journey',
            style: GoogleFonts.fredoka(
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          iconTheme: IconThemeData(color: colors.textPrimary),
          bottom: TabBar(
            labelColor: colors.accent,
            unselectedLabelColor: colors.textSecondary,
            indicatorColor: colors.accent,
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            tabs: const [
              Tab(text: 'Climb History'),
              Tab(text: 'Achievements'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _HistoryTab(),
            _AchievementsTab(),
          ],
        ),
      ),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Kinukuha ang mga hikes na lumipas na o ngayong araw ang petsa
    final hikes = HikeScheduleStore.instance.scheduledHikes.where((hike) {
      final hikeDateOnly = DateTime(
        hike.hikeDate.year,
        hike.hikeDate.month,
        hike.hikeDate.day,
      );
      return hikeDateOnly.isBefore(today) || hikeDateOnly.isAtSameMomentAs(today);
    }).toList();

    if (hikes.isEmpty) {
      return Center(
        child: Text(
          'No completed climbs yet.\nSchedule and complete a hike!',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(color: colors.textSecondary, fontSize: 14),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: hikes.length,
      itemBuilder: (context, index) {
        final hike = hikes[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.hiking_rounded, color: colors.accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hike.mountainName,
                      style: GoogleFonts.fredoka(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hike.trailName,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${hike.hikeDate.month}/${hike.hikeDate.day}/${hike.hikeDate.year}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.accent,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AchievementsTab extends StatelessWidget {
  const _AchievementsTab();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final achievements = HikeStatsService.instance.achievements;

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final ach = achievements[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: ach.isUnlocked
                  ? colors.accent.withValues(alpha: 0.4)
                  : colors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: ach.isUnlocked
                      ? colors.accent.withValues(alpha: 0.2)
                      : colors.surfaceMuted,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  ach.isUnlocked
                      ? Icons.workspace_premium_rounded
                      : Icons.lock_outline_rounded,
                  color: ach.isUnlocked ? colors.accent : colors.textSecondary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ach.title,
                      style: GoogleFonts.fredoka(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      ach.description,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: colors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}