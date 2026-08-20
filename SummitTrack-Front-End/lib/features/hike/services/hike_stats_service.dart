import 'package:flutter/foundation.dart';
import '../models/scheduled_hike.dart';
import 'hike_schedule_store.dart';

class HikerAchievement {
  final String id;
  final String title;
  final String description;
  final bool isUnlocked;

  const HikerAchievement({
    required this.id,
    required this.title,
    required this.description,
    required this.isUnlocked,
  });
}

class HikeStatsService extends ChangeNotifier {
  HikeStatsService._() {
    HikeScheduleStore.instance.addListener(_onStoreUpdated);
  }
  static final HikeStatsService instance = HikeStatsService._();

  final HikeScheduleStore _store = HikeScheduleStore.instance;

  void _onStoreUpdated() {
    notifyListeners();
  }

  /// Bilang ng mga natapos/lumipas nang hikes (batay sa hikeDate kumpara ngayon)
  int get totalCompletedClimbs {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return _store.scheduledHikes.where((hike) {
      final hikeDateOnly = DateTime(
        hike.hikeDate.year,
        hike.hikeDate.month,
        hike.hikeDate.day,
      );
      // Kinukuwenta ang mga hiks na tapos na o nakaraan na ang petsa
      return hikeDateOnly.isBefore(today) || hikeDateOnly.isAtSameMomentAs(today);
    }).length;
  }

  /// Listahan ng milestone achievements
  List<HikerAchievement> get achievements {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final completedHikes = _store.scheduledHikes.where((hike) {
      final hikeDateOnly = DateTime(
        hike.hikeDate.year,
        hike.hikeDate.month,
        hike.hikeDate.day,
      );
      return hikeDateOnly.isBefore(today) || hikeDateOnly.isAtSameMomentAs(today);
    }).toList();

    final completedMountainNames =
        completedHikes.map((hike) => hike.mountainName).toSet();

    return [
      HikerAchievement(
        id: 'first_summit',
        title: 'First Summit',
        description: 'Successfully completed your first mountain climb.',
        isUnlocked: completedHikes.isNotEmpty,
      ),
      HikerAchievement(
        id: 'high_altitude',
        title: 'High Altitude Conqueror',
        description:
            'Completed a hike on a high-elevation mountain (e.g. Mt. Pulag, Mt. Apo, Mt. Tapulao).',
        isUnlocked: completedHikes.any((hike) =>
            hike.mountainName.contains('Apo') ||
            hike.mountainName.contains('Pulag') ||
            hike.mountainName.contains('Tapulao')),
      ),
      HikerAchievement(
        id: 'trail_explorer',
        title: 'Trail Explorer',
        description: 'Explored and completed 3 different mountains.',
        isUnlocked: completedMountainNames.length >= 3,
      ),
      HikerAchievement(
        id: 'master_mountaineer',
        title: 'Master Mountaineer',
        description: 'Conquered 5 mountain summits.',
        isUnlocked: completedHikes.length >= 5,
      ),
    ];
  }

  /// Bilang ng unlocked achievements
  int get unlockedAchievementsCount {
    return achievements.where((achievement) => achievement.isUnlocked).length;
  }
}