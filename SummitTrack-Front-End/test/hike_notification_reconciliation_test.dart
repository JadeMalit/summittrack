import 'package:flutter_test/flutter_test.dart';
import 'package:summittrack/features/notifications/services/hike_notification_service.dart';

void main() {
  group('notification preference reconciliation', () {
    test('adopts an enabled cloud device when local preference is missing', () {
      expect(
        resolveNotificationEnabledPreference(
          storedPreference: null,
          cloudNotificationsEnabled: true,
        ),
        isTrue,
      );
    });

    test('does not treat a missing preference as an explicit disable', () {
      expect(notificationPreferenceRequiresCloudDisable(null), isFalse);
    });

    test('preserves an explicit local off choice', () {
      expect(
        resolveNotificationEnabledPreference(
          storedPreference: false,
          cloudNotificationsEnabled: true,
        ),
        isFalse,
      );
      expect(notificationPreferenceRequiresCloudDisable(false), isTrue);
    });

    test('preserves an explicit local on choice', () {
      expect(
        resolveNotificationEnabledPreference(
          storedPreference: true,
          cloudNotificationsEnabled: false,
        ),
        isTrue,
      );
      expect(notificationPreferenceRequiresCloudDisable(true), isFalse);
    });
  });
}
