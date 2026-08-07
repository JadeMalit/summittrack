import 'package:flutter_test/flutter_test.dart';
import 'package:summittrack/features/notifications/services/hike_notification_service.dart';

void main() {
  group('hike notification event contract', () {
    const uid = 'user-123';
    const hikeId = 'mt-apo_sta-cruz_2026-07-27';
    const hikeDateKey = '2026-07-27';
    const deviceId = 'installation-456';

    test('event key and document ID are stable', () {
      final eventKey = buildHikeReminderEventKey(
        uid: uid,
        hikeId: hikeId,
        hikeDateKey: hikeDateKey,
        deviceId: deviceId,
      );

      expect(
        eventKey,
        'user-123|mt-apo_sta-cruz_2026-07-27|'
        '2026-07-27|installation-456',
      );
      expect(hikeReminderEventDocumentId(eventKey), hasLength(64));
      expect(
        hikeReminderEventDocumentId(eventKey),
        hikeReminderEventDocumentId(eventKey),
      );
    });

    test('valid data-only payload round-trips', () {
      final eventKey = buildHikeReminderEventKey(
        uid: uid,
        hikeId: hikeId,
        hikeDateKey: hikeDateKey,
        deviceId: deviceId,
      );
      final payload = HikeNotificationPayload(
        type: HikeNotificationService.notificationType,
        uid: uid,
        hikeId: hikeId,
        hikeDateKey: hikeDateKey,
        mountainId: 'mt-apo',
        mountainName: 'Mt. Apo',
        deviceId: deviceId,
        eventKey: eventKey,
      );

      final decoded = HikeNotificationPayload.tryParse(payload.toJsonString());

      expect(decoded, isNotNull);
      expect(decoded!.eventKey, eventKey);
      expect(decoded.deviceId, deviceId);
      expect(decoded.toMap()['dateKey'], hikeDateKey);
      expect(decoded.toMap()['screen'], 'scheduled_hike_details');
    });

    test('tampered event key is rejected', () {
      final payload = HikeNotificationPayload.fromMap({
        'type': HikeNotificationService.notificationType,
        'uid': uid,
        'hikeId': hikeId,
        'hikeDateKey': hikeDateKey,
        'mountainId': 'mt-apo',
        'mountainName': 'Mt. Apo',
        'deviceId': deviceId,
        'eventKey': 'wrong-event-key',
      });

      expect(payload.isValid, isFalse);
    });
  });
}
