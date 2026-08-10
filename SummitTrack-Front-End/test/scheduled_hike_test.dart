import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:summittrack/features/hike/models/scheduled_hike.dart';
import 'package:summittrack/features/hike/services/hike_schedule_store.dart';
import 'package:summittrack/features/hike/utils/mountain_schedule_identity.dart';

void main() {
  group('ScheduledHike', () {
    test('creates a stable user-owned hike identity for a selected date', () {
      final hike = ScheduledHike.create(
        mountainId: MountainScheduleIdentity.idFromRoute('/mountain/mt-apo'),
        mountainName: 'Mt. Apo',
        trailId: 'sta_cruz_sibulan',
        trailName: 'Sta. Cruz / Sibulan Trail',
        hikeDate: DateTime(2026, 7, 7, 15, 30),
        ownerUid: 'user-123',
      );

      expect(hike.id, 'mt_apo_sta_cruz_sibulan_2026-07-07');
      expect(hike.mountainId, 'mt-apo');
      expect(hike.trailId, 'sta_cruz_sibulan');
      expect(hike.hikeDate, DateTime(2026, 7, 7));
      expect(hike.ownerUid, 'user-123');
    });

    test('serializes Firestore ownership fields required by rules', () {
      final hike = ScheduledHike.create(
        mountainId: 'mt-apo',
        mountainName: 'Mt. Apo',
        trailId: 'sta_cruz_sibulan',
        trailName: 'Sta. Cruz / Sibulan Trail',
        hikeDate: DateTime(2026, 7, 7),
      ).copyWith(ownerUid: 'user-123', updatedAt: DateTime(2026, 7, 6, 9));

      final data = hike.toFirestore(ownerUid: 'user-123');

      expect(data['ownerUid'], 'user-123');
      expect(data['userId'], 'user-123');
      expect(data['id'], hike.id);
      expect(data['hikeDateKey'], '2026-07-07');
      expect(data['hikeDate'], isA<Timestamp>());
      expect(
        (data['hikeDate'] as Timestamp).toDate().toUtc(),
        DateTime.utc(2026, 7, 6, 16),
      );
      expect(data['status'], 'scheduled');
      expect(data['notificationEnabled'], isTrue);
      expect(data['createdAt'], isA<FieldValue>());
      expect(data['updatedAt'], isA<FieldValue>());
    });

    test('omits createdAt when updating an existing scheduled hike', () {
      final hike = ScheduledHike.create(
        mountainId: 'mt-apo',
        mountainName: 'Mt. Apo',
        trailId: 'sta_cruz_sibulan',
        trailName: 'Sta. Cruz / Sibulan Trail',
        hikeDate: DateTime(2026, 8, 6),
      ).copyWith(ownerUid: 'user-123', updatedAt: DateTime(2026, 8, 6, 9));

      final data = hike.toFirestore(
        ownerUid: 'user-123',
        includeCreatedAt: false,
      );

      expect(data.containsKey('createdAt'), isFalse);
      expect(data['updatedAt'], isA<FieldValue>());
      expect(data['hikeDateKey'], '2026-08-06');
    });

    test('uses Asia Manila calendar date for same-day checks', () {
      final instant = DateTime.utc(2026, 8, 5, 16, 15);

      expect(
        ScheduledHike.dateKey(ScheduledHike.manilaDateForInstant(instant)),
        '2026-08-06',
      );
    });

    test('builds the current-user scheduled hike document path', () {
      expect(
        HikeScheduleStore.scheduleDocumentPathForTesting(
          userId: 'user-123',
          hikeId: 'mt_apo_sta_cruz_sibulan_2026-08-06',
        ),
        'users/user-123/scheduled_hikes/'
        'mt_apo_sta_cruz_sibulan_2026-08-06',
      );
    });

    test('round-trips account-scoped cache data without changing owner', () {
      final original = ScheduledHike.create(
        mountainId: 'mt-apo',
        mountainName: 'Mt. Apo',
        trailId: 'sta_cruz_sibulan',
        trailName: 'Sta. Cruz / Sibulan Trail',
        hikeDate: DateTime(2026, 7, 7),
        ownerUid: 'user-123',
      );

      final restored = ScheduledHike.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.ownerUid, 'user-123');
      expect(restored.hikeDate, DateTime(2026, 7, 7));
      expect(restored.status, ScheduledHike.activeStatus);
    });
  });

  group('Start Navigation eligibility', () {
    final today = DateTime(2026, 8, 8, 23, 30);

    ScheduledHike scheduledHike({
      String mountainId = 'mt-apo',
      String mountainName = 'Mt. Apo',
      String trailId = 'sta_cruz_sibulan',
      String trailName = 'Sta. Cruz / Sibulan Trail',
      DateTime? hikeDate,
      String ownerUid = 'user-123',
      String status = ScheduledHike.activeStatus,
    }) {
      return ScheduledHike.create(
        mountainId: mountainId,
        mountainName: mountainName,
        trailId: trailId,
        trailName: trailName,
        hikeDate: hikeDate ?? today,
      ).copyWith(ownerUid: ownerUid, status: status);
    }

    ScheduledHike? activeMatch(
      Iterable<ScheduledHike> hikes, {
      String? activeUserId = 'user-123',
      String currentMountainId = 'mt-apo',
      String currentTrailId = 'sta_cruz_sibulan',
      String currentTrailName = 'Sta. Cruz / Sibulan Trail',
      DateTime? currentDate,
    }) {
      return HikeScheduleStore.activeHikeForTrailTodayForTesting(
        scheduledHikes: hikes,
        activeUserId: activeUserId,
        mountainId: currentMountainId,
        trailId: currentTrailId,
        trailName: currentTrailName,
        today: currentDate ?? today,
      );
    }

    test('does not allow Start Navigation without a schedule', () {
      expect(activeMatch(const <ScheduledHike>[]), isNull);
    });

    test('allows Mt. Apo Sibulan, the known-good reference', () {
      final hike = scheduledHike();

      expect(activeMatch([hike]), hike);
    });

    test('allows another Mt. Apo trail only on that scheduled trail', () {
      final hike = scheduledHike(
        trailId: 'kapatagan',
        trailName: 'Kapatagan Trail',
      );

      expect(
        activeMatch(
          [hike],
          currentTrailId: 'kapatagan',
          currentTrailName: 'Kapatagan Trail',
        ),
        hike,
      );
      expect(activeMatch([hike]), isNull);
    });

    test('allows Mt. Pulag Ambangeg when scheduled today', () {
      final hike = scheduledHike(
        mountainId: 'mt-pulag',
        mountainName: 'Mt. Pulag',
        trailId: 'ambangeg_trail',
        trailName: 'Ambangeg Trail',
      );

      expect(
        activeMatch(
          [hike],
          currentMountainId: 'mt-pulag',
          currentTrailId: 'ambangeg_trail',
          currentTrailName: 'Ambangeg Trail',
        ),
        hike,
      );
    });

    test(
      'allows another supported mountain and trail when scheduled today',
      () {
        final hike = scheduledHike(
          mountainId: 'ulap',
          mountainName: 'Mt. Ulap',
          trailId: 'ambanao_trail',
          trailName: 'Ambanao Trail',
        );

        expect(
          activeMatch(
            [hike],
            currentMountainId: 'ulap',
            currentTrailId: 'ambanao_trail',
            currentTrailName: 'Ambanao Trail',
          ),
          hike,
        );
      },
    );

    test('does not allow Start Navigation for tomorrow or yesterday', () {
      expect(
        activeMatch([scheduledHike(hikeDate: DateTime(2026, 8, 9))]),
        isNull,
      );
      expect(
        activeMatch([scheduledHike(hikeDate: DateTime(2026, 8, 7))]),
        isNull,
      );
    });

    test('does not allow Start Navigation for a different mountain today', () {
      expect(
        activeMatch([
          scheduledHike(mountainId: 'mt-pulag', mountainName: 'Mt. Pulag'),
        ]),
        isNull,
      );
    });

    test('does not allow Start Navigation for a different trail today', () {
      expect(
        activeMatch([
          scheduledHike(trailId: 'kapatagan', trailName: 'Kapatagan Trail'),
        ]),
        isNull,
      );
    });

    test('does not allow Start Navigation for a cancelled schedule', () {
      expect(activeMatch([scheduledHike(status: 'cancelled')]), isNull);
    });

    test('does not allow Start Navigation for another user schedule', () {
      expect(activeMatch([scheduledHike(ownerUid: 'other-user')]), isNull);
    });

    test('does not allow Start Navigation without a logged-in user', () {
      expect(activeMatch([scheduledHike()], activeUserId: null), isNull);
    });

    test('matches safe legacy trail names and separator variants', () {
      final legacy = ScheduledHike.fromJson({
        'id': 'legacy-ambangeg',
        'ownerUid': 'user-123',
        'mountainId': 'Mt. Pulag',
        'mountainName': 'Mt. Pulag',
        'trailId': 'Ambangeg Trail',
        'trailName': 'Ambangeg Trail',
        'hikeDateKey': ScheduledHike.dateKey(today),
        'status': ScheduledHike.activeStatus,
        'createdAt': '2026-08-08T00:00:00.000',
      });

      final match = activeMatch(
        [legacy],
        currentMountainId: 'mt-pulag',
        currentTrailId: 'ambangeg_trail',
        currentTrailName: 'Ambangeg Trail',
      );

      expect(match?.id, legacy.id);
      expect(
        activeMatch(
          [legacy],
          currentMountainId: 'mt-pulag',
          currentTrailId: 'akiki_trail',
          currentTrailName: 'Akiki Trail',
        ),
        isNull,
      );
    });

    test('keeps eligibility after cached schedule round-trip', () {
      final hike = scheduledHike(
        mountainId: 'mt-pulag',
        mountainName: 'Mt. Pulag',
        trailId: 'ambangeg_trail',
        trailName: 'Ambangeg Trail',
      );
      final restored = ScheduledHike.fromJson(hike.toJson());

      final match = activeMatch(
        [restored],
        currentMountainId: 'mt-pulag',
        currentTrailId: 'ambangeg_trail',
        currentTrailName: 'Ambangeg Trail',
      );

      expect(match?.id, hike.id);
    });
  });
}
