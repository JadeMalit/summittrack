import 'package:flutter_test/flutter_test.dart';
import 'package:summittrack/features/mountains/screens/trail_detail_screen.dart';
import 'package:summittrack/features/notifications/services/hike_notification_service.dart';

void main() {
  group('hike scheduled confirmation message', () {
    test('uses same-day copy for enabled notifications in Asia Manila', () {
      final message = hikeScheduledNotificationConfirmationMessage(
        hikeDate: DateTime(2026, 8, 6),
        deliveryState: HikeReminderDeliveryState.enabled,
        now: DateTime.utc(2026, 8, 5, 16, 1),
      );

      expect(
        message,
        'Notifications are turned on. You will receive a reminder for your '
        'hike today.',
      );
    });

    test('uses scheduled-date copy for enabled future notifications', () {
      final message = hikeScheduledNotificationConfirmationMessage(
        hikeDate: DateTime(2026, 8, 7),
        deliveryState: HikeReminderDeliveryState.enabled,
        now: DateTime.utc(2026, 8, 5, 16, 1),
      );

      expect(
        message,
        'Notifications are turned on. You will receive a reminder on the '
        'scheduled date.',
      );
    });

    test('uses settings copy for disabled notifications', () {
      final message = hikeScheduledNotificationConfirmationMessage(
        hikeDate: DateTime(2026, 8, 6),
        deliveryState: HikeReminderDeliveryState.disabled,
        now: DateTime.utc(2026, 8, 5, 16, 1),
      );

      expect(
        message,
        'Turn on Notifications in Settings to receive a hike reminder.',
      );
    });

    test('uses unknown copy when state cannot be confirmed', () {
      final message = hikeScheduledNotificationConfirmationMessage(
        hikeDate: DateTime(2026, 8, 6),
        deliveryState: HikeReminderDeliveryState.unknown,
        now: DateTime.utc(2026, 8, 5, 16, 1),
      );

      expect(
        message,
        'Your hike was saved, but the notification status could not be '
        'confirmed.',
      );
    });
  });
}
