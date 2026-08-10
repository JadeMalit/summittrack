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

    test(
      'recovers an invalid cloud token only when local preference is on',
      () {
        expect(
          shouldRecoverInvalidCloudToken(
            storedPreference: true,
            cloudTokenStatus: 'invalid',
          ),
          isTrue,
        );
        expect(
          shouldRecoverInvalidCloudToken(
            storedPreference: false,
            cloudTokenStatus: 'invalid',
          ),
          isFalse,
        );
        expect(
          shouldRecoverInvalidCloudToken(
            storedPreference: null,
            cloudTokenStatus: 'invalid',
          ),
          isFalse,
        );
        expect(
          shouldRecoverInvalidCloudToken(
            storedPreference: true,
            cloudTokenStatus: 'active',
          ),
          isFalse,
        );
      },
    );

    test('persists token refresh for active cloud state or local on', () {
      expect(
        shouldPersistTokenRefresh(
          storedPreference: null,
          cloudDeviceExists: true,
          cloudNotificationsEnabled: true,
          cloudTokenStatus: 'active',
        ),
        isTrue,
      );
      expect(
        shouldPersistTokenRefresh(
          storedPreference: true,
          cloudDeviceExists: true,
          cloudNotificationsEnabled: false,
          cloudTokenStatus: 'invalid',
        ),
        isTrue,
      );
      expect(
        shouldPersistTokenRefresh(
          storedPreference: false,
          cloudDeviceExists: true,
          cloudNotificationsEnabled: false,
          cloudTokenStatus: 'invalid',
        ),
        isFalse,
      );
    });
  });
}
