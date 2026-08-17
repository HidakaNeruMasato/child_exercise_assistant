import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_settings.dart';
import '../repositories/history_repository.dart';

/// 未運動リマインダー判定サービス
class ReminderCheckResult {
  final bool shouldNotify;
  final int daysSinceLastActivity;
  final String message;

  const ReminderCheckResult({
    required this.shouldNotify,
    required this.daysSinceLastActivity,
    required this.message,
  });
}

final reminderServiceProvider = Provider<ReminderService>((ref) {
  return ReminderService(ref);
});

class ReminderService {
  final Ref _ref;

  ReminderService(this._ref);

  /// 運動履歴と通知設定を照合し、リマインダー通知が必要かをチェック
  Future<ReminderCheckResult> checkReminder({String userId = 'user_demo_123'}) async {
    final settings = _ref.read(notificationSettingsProvider);

    // 通知が無効(OFF)の場合は通知しない
    if (!settings.isEnabled) {
      return const ReminderCheckResult(
        shouldNotify: false,
        daysSinceLastActivity: 0,
        message: '通知はOFFに設定されています。',
      );
    }

    final histories = await _ref.read(historyRepositoryProvider).getHistories(userId);

    if (histories.isEmpty) {
      return ReminderCheckResult(
        shouldNotify: true,
        daysSinceLastActivity: settings.inactiveDaysThreshold,
        message: '【リマインダー】あそびの記録がまだありません！お子様と一緒に15分の運動・遊びを始めてみませんか？✨',
      );
    }

    // 最新の運動記録日
    histories.sort((a, b) => b.playedAt.compareTo(a.playedAt));
    final latest = histories.first.playedAt;
    final diffDays = DateTime.now().difference(latest).inDays;

    if (diffDays >= settings.inactiveDaysThreshold) {
      return ReminderCheckResult(
        shouldNotify: true,
        daysSinceLastActivity: diffDays,
        message: '【運動リマインダー】最後にあそんでから $diffDays 日が経過しました！最近のお子様の気分に合わせたおすすめの遊びはいかがですか？🌸',
      );
    }

    return ReminderCheckResult(
      shouldNotify: false,
      daysSinceLastActivity: diffDays,
      message: '順調に運動が記録されています！（前回から $diffDays 日目）',
    );
  }
}
