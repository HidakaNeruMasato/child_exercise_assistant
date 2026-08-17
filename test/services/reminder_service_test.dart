import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:child_exercise_assistant/models/notification_settings.dart';
import 'package:child_exercise_assistant/services/notification_service.dart';

void main() {
  test('ReminderService check when notification is OFF', () async {
    final container = ProviderContainer(
      overrides: [
        notificationSettingsProvider.overrideWith(
          (ref) => NotificationSettingsNotifier()..toggleEnabled(false),
        ),
      ],
    );

    final result = await container.read(reminderServiceProvider).checkReminder();
    expect(result.shouldNotify, false);
  });
}
