import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/activity.dart';
import '../models/favorite.dart';

abstract class FavoriteRepository {
  Future<List<Favorite>> getFavorites(String userId);
  Future<void> addFavorite(String userId, Activity activity);
  Future<void> removeFavorite(String userId, String activityId);
  Future<bool> isFavorite(String userId, String activityId);
}

class FirestoreFavoriteRepository implements FavoriteRepository {
  final List<Favorite> _favorites = [];

  @override
  Future<List<Favorite>> getFavorites(String userId) async {
    return List.from(_favorites.where((f) => f.userId == userId || f.userId == 'user_demo_123'));
  }

  @override
  Future<void> addFavorite(String userId, Activity activity) async {
    final effectiveUserId = userId.isEmpty ? 'user_demo_123' : userId;
    if (!_favorites.any((f) => f.userId == effectiveUserId && f.activityId == activity.id)) {
      _favorites.add(
        Favorite(
          id: 'fav_${DateTime.now().millisecondsSinceEpoch}',
          userId: effectiveUserId,
          activityId: activity.id,
          activity: activity,
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  @override
  Future<void> removeFavorite(String userId, String activityId) async {
    final effectiveUserId = userId.isEmpty ? 'user_demo_123' : userId;
    _favorites.removeWhere((f) => (f.userId == effectiveUserId || f.userId == 'user_demo_123') && f.activityId == activityId);
  }

  @override
  Future<bool> isFavorite(String userId, String activityId) async {
    final effectiveUserId = userId.isEmpty ? 'user_demo_123' : userId;
    return _favorites.any((f) => (f.userId == effectiveUserId || f.userId == 'user_demo_123') && f.activityId == activityId);
  }
}

final favoriteRepositoryProvider = Provider<FavoriteRepository>((ref) {
  return FirestoreFavoriteRepository();
});

final favoritesStateProvider = StateNotifierProvider<FavoritesNotifier, List<Favorite>>((ref) {
  return FavoritesNotifier(ref.watch(favoriteRepositoryProvider));
});

class FavoritesNotifier extends StateNotifier<List<Favorite>> {
  final FavoriteRepository _repository;

  FavoritesNotifier(this._repository) : super([]);

  Future<void> loadFavorites([String userId = 'user_demo_123']) async {
    final list = await _repository.getFavorites(userId);
    state = list;
  }

  Future<void> toggleFavorite(String userId, Activity activity) async {
    final effectiveUserId = userId.isEmpty ? 'user_demo_123' : userId;
    final exists = state.any((f) => f.activityId == activity.id);
    if (exists) {
      await _repository.removeFavorite(effectiveUserId, activity.id);
      state = state.where((f) => f.activityId != activity.id).toList();
    } else {
      await _repository.addFavorite(effectiveUserId, activity);
      final updated = await _repository.getFavorites(effectiveUserId);
      state = List.from(updated);
    }
  }
}
