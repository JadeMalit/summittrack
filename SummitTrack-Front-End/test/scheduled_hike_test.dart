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
    });
  });
}
