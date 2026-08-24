import 'package:uuid/uuid.dart';

/// フィードバック種別
enum FeedbackType {
  activityRecord, // 個別遊び完了時の評価
  appGeneral,     // アプリ全体のフィードバック
}

/// フィードバックデータモデル
class AppFeedback {
  final String id;
  final FeedbackType type;
  final String? activityId;
  final String? activityTitle;
  final List<String> childNames;
  final double rating; // 1.0 〜 5.0
  final String comment; // 「詳しくおしえる」自由記述
  final DateTime createdAt;

  AppFeedback({
    String? id,
    required this.type,
    this.activityId,
    this.activityTitle,
    this.childNames = const [],
    required this.rating,
    this.comment = '',
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'activityId': activityId,
      'activityTitle': activityTitle,
      'childNames': childNames,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AppFeedback.fromJson(Map<String, dynamic> json) {
    return AppFeedback(
      id: json['id'] as String?,
      type: FeedbackType.values.byName(json['type'] as String? ?? 'appGeneral'),
      activityId: json['activityId'] as String?,
      activityTitle: json['activityTitle'] as String?,
      childNames: (json['childNames'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      comment: json['comment'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
