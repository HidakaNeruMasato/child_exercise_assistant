import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../models/activity.dart';
import '../models/activity_history.dart';

/// ファミリー合言葉（家族間で共有する合言葉）の保持Provider
final familyIdProvider = StateProvider<String>((ref) {
  return 'たなか家'; // デフォルトの合言葉例
});

abstract class HistoryRepository {
  Future<List<ActivityHistory>> getHistories(String familyOrUserId);
  Future<void> addHistory(
    String familyOrUserId,
    Activity activity,
    int rating,
    String? note, {
    String recorderName = '家族',
    List<String> childNames = const ['たろう'],
  });
}

class FirestoreHistoryRepository implements HistoryRepository {
  final List<ActivityHistory> _histories = [];

  FirestoreHistoryRepository() {
    // 家族共有の初期デモサンプル履歴
    _histories.addAll([
      ActivityHistory(
        id: 'hist_demo_1',
        userId: 'たなか家',
        activityId: 'act_001',
        activity: const Activity(
          id: 'act_001',
          title: '影踏みオニごっこ',
          description: '相手の影を踏み合う鬼ごっこ',
          minAge: 4,
          maxAge: 10,
          minParticipants: 2,
          maxParticipants: 6,
          durationMinutes: 15,
          locationTypes: [LocationType.park],
          toolsRequired: ['なし（道具不要）'],
          intensityLevel: IntensityLevel.high,
          difficultyLevel: DifficultyLevel.easy,
          trainableAbilities: [AbilityType.agility, AbilityType.stamina],
          isRainOk: false,
          isIndoorOk: false,
          safetyLevel: 5,
          safetyTips: ['転倒に注意'],
          steps: ['影を踏む'],
          parentInvolvement: ParentInvolvementLevel.active,
          parentPraiseTips: ['ナイスダッシュ！'],
        ),
        playedAt: DateTime.now().subtract(const Duration(hours: 3)),
        rating: 5,
        note: '「パパ」が記録：夕方の公園で15分思い切り走りました！',
        childNames: const ['たろう', 'はなこ'],
      ),
      ActivityHistory(
        id: 'hist_demo_2',
        userId: 'たなか家',
        activityId: 'act_002',
        activity: const Activity(
          id: 'act_002',
          title: '風船パタパタバレー',
          description: '風船を床に落とさないラリー',
          minAge: 3,
          maxAge: 8,
          minParticipants: 2,
          maxParticipants: 4,
          durationMinutes: 15,
          locationTypes: [LocationType.indoor],
          toolsRequired: ['風船'],
          intensityLevel: IntensityLevel.medium,
          difficultyLevel: DifficultyLevel.easy,
          trainableAbilities: [AbilityType.balance],
          isRainOk: true,
          isIndoorOk: true,
          safetyLevel: 5,
          safetyTips: ['周りの家具に注意'],
          steps: ['風船を叩く'],
          parentInvolvement: ParentInvolvementLevel.moderate,
          parentPraiseTips: ['集中できたね！'],
        ),
        playedAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
        rating: 5,
        note: '「ママ」が記録：雨だったのでお部屋で20分ポカポカバレー',
        childNames: const ['はなこ', 'じろう'],
      ),
    ]);
  }

  @override
  Future<List<ActivityHistory>> getHistories(String familyOrUserId) async {
    final key = familyOrUserId.trim().isEmpty ? 'user_demo_123' : familyOrUserId.trim();
    return _histories.where((h) => h.userId == key || h.userId == 'user_demo_123' || key == 'たなか家').toList()
      ..sort((a, b) => b.playedAt.compareTo(a.playedAt));
  }

  @override
  Future<void> addHistory(
    String familyOrUserId,
    Activity activity,
    int rating,
    String? note, {
    String recorderName = '家族',
    List<String> childNames = const ['たろう'],
  }) async {
    final key = familyOrUserId.trim().isEmpty ? 'user_demo_123' : familyOrUserId.trim();
    _histories.add(
      ActivityHistory(
        id: 'hist_${DateTime.now().millisecondsSinceEpoch}',
        userId: key,
        activityId: activity.id,
        activity: activity,
        playedAt: DateTime.now(),
        rating: rating,
        note: note != null && note.isNotEmpty ? note : '「$recorderName」が記録',
        childNames: childNames.isNotEmpty ? childNames : const ['たろう'],
      ),
    );
  }
}

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return FirestoreHistoryRepository();
});

final historyStateProvider = StateNotifierProvider<HistoryNotifier, List<ActivityHistory>>((ref) {
  return HistoryNotifier(ref);
});

class HistoryNotifier extends StateNotifier<List<ActivityHistory>> {
  final Ref _ref;

  HistoryNotifier(this._ref) : super([]);

  Future<void> loadHistories([String? familyOrUserId]) async {
    final familyId = (familyOrUserId != null && familyOrUserId.isNotEmpty)
        ? familyOrUserId
        : _ref.read(familyIdProvider);
    final repo = _ref.read(historyRepositoryProvider);
    final list = await repo.getHistories(familyId);
    state = List.from(list);
  }

  Future<void> recordPlay(
    Activity activity, {
    int rating = 5,
    String? note,
    String recorderName = 'パパ・ママ',
    List<String> childNames = const ['たろう'],
  }) async {
    final familyId = _ref.read(familyIdProvider);
    final repo = _ref.read(historyRepositoryProvider);
    await repo.addHistory(
      familyId,
      activity,
      rating,
      note,
      recorderName: recorderName,
      childNames: childNames,
    );
    await loadHistories(familyId);
  }
}
