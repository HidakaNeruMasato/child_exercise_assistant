import 'activity.dart';

/// 実施履歴データモデル
class ActivityHistory {
  final String id;
  final String userId;
  final String activityId;
  final Activity activity;
  final DateTime playedAt;
  final int rating; // 1〜5 の評価
  final String? note; // 感想メモ
  final List<String> childNames; // 一緒に遊んだ子どもたちの名前リスト (例: ['たろう', 'はなこ'])

  const ActivityHistory({
    required this.id,
    required this.userId,
    required this.activityId,
    required this.activity,
    required this.playedAt,
    required this.rating,
    this.note,
    this.childNames = const ['たろう'],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'activityId': activityId,
      'activity': activity.toJson(),
      'playedAt': playedAt.toIso8601String(),
      'rating': rating,
      'note': note,
      'childNames': childNames,
    };
  }

  factory ActivityHistory.fromJson(Map<String, dynamic> json) {
    return ActivityHistory(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      activityId: json['activityId'] as String? ?? '',
      activity: Activity.fromJson(json['activity'] as Map<String, dynamic>? ?? {}),
      playedAt: DateTime.tryParse(json['playedAt'] as String? ?? '') ?? DateTime.now(),
      rating: (json['rating'] as num?)?.toInt() ?? 5,
      note: json['note'] as String?,
      childNames: (json['childNames'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['たろう'],
    );
  }
}
