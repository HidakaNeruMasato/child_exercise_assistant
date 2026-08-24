import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_feedback.dart';

/// フィードバックリポジトリ（インメモリ ＆ リバース同期対応）
class FeedbackRepository {
  final List<AppFeedback> _feedbacks = [];

  FeedbackRepository() {
    _feedbacks.addAll(_generateInitialSamples());
  }

  /// フィードバックの全件取得
  Future<List<AppFeedback>> getFeedbacks() async {
    return List.unmodifiable(_feedbacks);
  }

  /// 新規フィードバックの追加
  Future<void> addFeedback(AppFeedback feedback) async {
    _feedbacks.insert(0, feedback); // 最新を先頭に追加
  }

  /// デモ用の初期サンプルフィードバックデータ
  List<AppFeedback> _generateInitialSamples() {
    final now = DateTime.now();
    return [
      AppFeedback(
        type: FeedbackType.activityRecord,
        activityId: 'act_021',
        activityTitle: '公園遊具周回タイムアタック',
        childNames: ['たろう'],
        rating: 5.0,
        comment: '前回のタイムより3秒速くなってとっても嬉しそうでした！公園で楽しく体を動かせました。',
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      AppFeedback(
        type: FeedbackType.activityRecord,
        activityId: 'act_002',
        activityTitle: '風船バレーボール',
        childNames: ['たろう', 'はなこ'],
        rating: 4.5,
        comment: '室内で安全に遊べました。風船がゆっくり落ちるので3歳の子でもラリーが続いて喜んでいました！',
        createdAt: now.subtract(const Duration(days: 1, hours: 2)),
      ),
      AppFeedback(
        type: FeedbackType.appGeneral,
        rating: 5.0,
        comment: '雨の日の遊びに悩んでいたのでとても助かっています。提案が具体的で親からの声掛け例が参考になります！',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      AppFeedback(
        type: FeedbackType.activityRecord,
        activityId: 'act_001',
        activityTitle: '新聞紙キャッチボール',
        childNames: ['たろう'],
        rating: 4.0,
        comment: '新聞紙を丸める工作から一緒に楽しめました。少し部屋が散らかるけど大満足です。',
        createdAt: now.subtract(const Duration(days: 3)),
      ),
    ];
  }
}

/// FeedbackRepository Provider
final feedbackRepositoryProvider = Provider<FeedbackRepository>((ref) {
  return FeedbackRepository();
});

/// フィードバックリスト StateNotifier / AsyncNotifier
final feedbackListProvider = AsyncNotifierProvider<FeedbackListNotifier, List<AppFeedback>>(() {
  return FeedbackListNotifier();
});

class FeedbackListNotifier extends AsyncNotifier<List<AppFeedback>> {
  @override
  Future<List<AppFeedback>> build() async {
    final repo = ref.watch(feedbackRepositoryProvider);
    return await repo.getFeedbacks();
  }

  /// 新規フィードバックの登録
  Future<void> addFeedback(AppFeedback feedback) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(feedbackRepositoryProvider);
      await repo.addFeedback(feedback);
      return await repo.getFeedbacks();
    });
  }

  /// リフレッシュ
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(feedbackRepositoryProvider);
      return await repo.getFeedbacks();
    });
  }
}
