import 'activity.dart';

/// お気に入り遊びデータモデル
class Favorite {
  final String id;
  final String userId;
  final String activityId;
  final Activity activity;
  final DateTime createdAt;

  const Favorite({
    required this.id,
    required this.userId,
    required this.activityId,
    required this.activity,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'activityId': activityId,
      'activity': activity.toJson(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      activityId: json['activityId'] as String? ?? '',
      activity: Activity.fromJson(json['activity'] as Map<String, dynamic>? ?? {}),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}
