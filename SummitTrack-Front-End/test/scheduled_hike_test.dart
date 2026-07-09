import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:summittrack/features/hike/models/scheduled_hike.dart';
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

      final data = hike.toFirestore(
        ownerUid: 'user-123',
        ownerEmail: ' hiker@example.com ',
      );

      expect(data['ownerUid'], 'user-123');
      expect(data['userId'], 'user-123');
      expect(data['ownerEmail'], 'hiker@example.com');
      expect(data['id'], hike.id);
      expect(data['hikeDateKey'], '2026-07-07');
      expect(data['hikeDate'], isA<Timestamp>());
      expect(data['createdAt'], isA<Timestamp>());
      expect(data['updatedAt'], isA<Timestamp>());
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
