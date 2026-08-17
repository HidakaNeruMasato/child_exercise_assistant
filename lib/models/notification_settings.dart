import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 未運動リマインダー通知設定モデル
class NotificationSettings {
  final bool isEnabled; // 通知機能のON/OFF
  final int inactiveDaysThreshold; // 何日間遊びの履歴がない場合に通知するか (1〜14日)
  final String notificationTime; // 通知時間 (例: "17:00")

  const NotificationSettings({
    this.isEnabled = true,
    this.inactiveDaysThreshold = 3,
    this.notificationTime = '17:00',
  });

  NotificationSettings copyWith({
    bool? isEnabled,
    int? inactiveDaysThreshold,
    String? notificationTime,
  }) {
    return NotificationSettings(
      isEnabled: isEnabled ?? this.isEnabled,
      inactiveDaysThreshold: inactiveDaysThreshold ?? this.inactiveDaysThreshold,
      notificationTime: notificationTime ?? this.notificationTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'inactiveDaysThreshold': inactiveDaysThreshold,
      'notificationTime': notificationTime,
    };
  }

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      isEnabled: json['isEnabled'] as bool? ?? true,
      inactiveDaysThreshold: (json['inactiveDaysThreshold'] as num?)?.toInt() ?? 3,
      notificationTime: json['notificationTime'] as String? ?? '17:00',
    );
  }
}

/// 通知設定の状態保持Provider
final notificationSettingsProvider =
    StateNotifierProvider<NotificationSettingsNotifier, NotificationSettings>((ref) {
  return NotificationSettingsNotifier();
});

class NotificationSettingsNotifier extends StateNotifier<NotificationSettings> {
  NotificationSettingsNotifier() : super(const NotificationSettings());

  void toggleEnabled(bool value) {
    state = state.copyWith(isEnabled: value);
  }

  void setInactiveDays(int days) {
    state = state.copyWith(inactiveDaysThreshold: days);
  }

  void setNotificationTime(String time) {
    state = state.copyWith(notificationTime: time);
  }
}
