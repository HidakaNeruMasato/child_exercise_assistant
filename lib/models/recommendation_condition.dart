import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';

/// 推薦検索条件モデル
class RecommendationCondition {
  final int childAge;
  final int participantCount;
  final LocationType locationType;
  final int availableTimeMinutes;
  final bool isRaining;
  final Season season; // 季節 (春/夏/秋/冬)
  final ChildMoodState childMoodState; // 今日の子どもの状態 (元気/疲れ/イライラ等)
  final List<String> availableTools;
  final List<AbilityType> preferredAbilities;
  final IntensityLevel? preferredIntensity;

  const RecommendationCondition({
    required this.childAge,
    required this.participantCount,
    required this.locationType,
    required this.availableTimeMinutes,
    required this.isRaining,
    required this.season,
    this.childMoodState = ChildMoodState.normal,
    this.availableTools = const [],
    this.preferredAbilities = const [],
    this.preferredIntensity,
  });

  /// デフォルト検索条件（使いやすさ重視のプリセット）
  factory RecommendationCondition.defaultCondition() {
    return RecommendationCondition(
      childAge: 6,
      participantCount: 2,
      locationType: LocationType.park,
      availableTimeMinutes: 30,
      isRaining: false,
      season: SeasonX.currentSeason,
      childMoodState: ChildMoodState.normal,
      availableTools: const ['なし（道具不要）'],
      preferredAbilities: const [AbilityType.stamina, AbilityType.agility],
      preferredIntensity: IntensityLevel.medium,
    );
  }

  RecommendationCondition copyWith({
    int? childAge,
    int? participantCount,
    LocationType? locationType,
    int? availableTimeMinutes,
    bool? isRaining,
    Season? season,
    ChildMoodState? childMoodState,
    List<String>? availableTools,
    List<AbilityType>? preferredAbilities,
    IntensityLevel? preferredIntensity,
  }) {
    return RecommendationCondition(
      childAge: childAge ?? this.childAge,
      participantCount: participantCount ?? this.participantCount,
      locationType: locationType ?? this.locationType,
      availableTimeMinutes: availableTimeMinutes ?? this.availableTimeMinutes,
      isRaining: isRaining ?? this.isRaining,
      season: season ?? this.season,
      childMoodState: childMoodState ?? this.childMoodState,
      availableTools: availableTools ?? this.availableTools,
      preferredAbilities: preferredAbilities ?? this.preferredAbilities,
      preferredIntensity: preferredIntensity ?? this.preferredIntensity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'childAge': childAge,
      'participantCount': participantCount,
      'locationType': locationType.name,
      'availableTimeMinutes': availableTimeMinutes,
      'isRaining': isRaining,
      'season': season.name,
      'childMoodState': childMoodState.name,
      'availableTools': availableTools,
      'preferredAbilities': preferredAbilities.map((e) => e.name).toList(),
      'preferredIntensity': preferredIntensity?.name,
    };
  }

  factory RecommendationCondition.fromJson(Map<String, dynamic> json) {
    return RecommendationCondition(
      childAge: (json['childAge'] as num?)?.toInt() ?? 6,
      participantCount: (json['participantCount'] as num?)?.toInt() ?? 2,
      locationType: LocationType.values.byName(
          json['locationType'] as String? ?? LocationType.park.name),
      availableTimeMinutes: (json['availableTimeMinutes'] as num?)?.toInt() ?? 30,
      isRaining: json['isRaining'] as bool? ?? false,
      season: json['season'] != null
          ? Season.values.byName(json['season'] as String)
          : SeasonX.currentSeason,
      childMoodState: json['childMoodState'] != null
          ? ChildMoodState.values.byName(json['childMoodState'] as String)
          : ChildMoodState.normal,
      availableTools: (json['availableTools'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      preferredAbilities: (json['preferredAbilities'] as List<dynamic>?)
              ?.map((e) => AbilityType.values.byName(e.toString()))
              .toList() ??
          [],
      preferredIntensity: json['preferredIntensity'] != null
          ? IntensityLevel.values.byName(json['preferredIntensity'] as String)
          : null,
    );
  }
}

/// 全体で検索条件を共有・リアルタイム変更するためのRiverpod Provider
final recommendationConditionProvider = StateProvider<RecommendationCondition>((ref) {
  return RecommendationCondition.defaultCondition();
});

