import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/activity.dart';
import '../models/activity_history.dart';

abstract class HistoryRepository {
  Future<List<ActivityHistory>> getHistories(String userId);
  Future<void> addHistory(String userId, Activity activity, int rating, String? note);
}

class FirestoreHistoryRepository implements HistoryRepository {
  final List<ActivityHistory> _histories = [];

  @override
  Future<List<ActivityHistory>> getHistories(String userId) async {
    final effectiveUserId = userId.isEmpty ? 'user_demo_123' : userId;
    return _histories.where((h) => h.userId == effectiveUserId || h.userId == 'user_demo_123').toList()
      ..sort((a, b) => b.playedAt.compareTo(a.playedAt));
  }

  @override
  Future<void> addHistory(String userId, Activity activity, int rating, String? note) async {
    final effectiveUserId = userId.isEmpty ? 'user_demo_123' : userId;
    _histories.add(
      ActivityHistory(
        id: 'hist_${DateTime.now().millisecondsSinceEpoch}',
        userId: effectiveUserId,
        activityId: activity.id,
        activity: activity,
        playedAt: DateTime.now(),
        rating: rating,
        note: note,
      ),
    );
  }
}

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return FirestoreHistoryRepository();
});

final historyStateProvider = StateNotifierProvider<HistoryNotifier, List<ActivityHistory>>((ref) {
  return HistoryNotifier(ref.watch(historyRepositoryProvider));
});

class HistoryNotifier extends StateNotifier<List<ActivityHistory>> {
  final HistoryRepository _repository;

  HistoryNotifier(this._repository) : super([]);

  Future<void> loadHistories([String userId = 'user_demo_123']) async {
    final effectiveUserId = userId.isEmpty ? 'user_demo_123' : userId;
    final list = await _repository.getHistories(effectiveUserId);
    state = List.from(list);
  }

  Future<void> recordPlay(String userId, Activity activity, {int rating = 5, String? note}) async {
    final effectiveUserId = userId.isEmpty ? 'user_demo_123' : userId;
    await _repository.addHistory(effectiveUserId, activity, rating, note);
    await loadHistories(effectiveUserId);
  }
}
