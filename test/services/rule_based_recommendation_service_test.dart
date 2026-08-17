import 'package:flutter_test/flutter_test.dart';
import 'package:child_exercise_assistant/core/constants/app_constants.dart';
import 'package:child_exercise_assistant/models/activity.dart';
import 'package:child_exercise_assistant/models/recommendation_condition.dart';
import 'package:child_exercise_assistant/services/rule_based_recommendation_service.dart';

void main() {
  group('RuleBasedRecommendationService Tests', () {
    late RuleBasedRecommendationService service;
    late List<Activity> mockActivities;

    setUp(() {
      service = RuleBasedRecommendationService();

      mockActivities = [
        const Activity(
          id: '1',
          title: '屋外ダッシュ鬼ごっこ',
          description: '広場でダッシュ！',
          minAge: 5,
          maxAge: 10,
          minParticipants: 2,
          maxParticipants: 5,
          durationMinutes: 20,
          locationTypes: [LocationType.park, LocationType.spacious],
          toolsRequired: ['なし（道具不要）'],
          intensityLevel: IntensityLevel.high,
          difficultyLevel: DifficultyLevel.easy,
          trainableAbilities: [AbilityType.stamina, AbilityType.agility],
          isRainOk: false,
          isIndoorOk: false,
          safetyLevel: 5,
          safetyTips: ['転倒注意'],
          steps: ['走る'],
        ),
        const Activity(
          id: '2',
          title: '室内新聞紙キャッチ',
          description: '室内で新聞紙を落としてキャッチ！',
          minAge: 3,
          maxAge: 8,
          minParticipants: 1,
          maxParticipants: 4,
          durationMinutes: 15,
          locationTypes: [LocationType.indoor],
          toolsRequired: ['新聞紙/紙'],
          intensityLevel: IntensityLevel.medium,
          difficultyLevel: DifficultyLevel.easy,
          trainableAbilities: [AbilityType.agility, AbilityType.balance],
          isRainOk: true,
          isIndoorOk: true,
          safetyLevel: 5,
          safetyTips: ['滑らないように注意'],
          steps: ['落とす', 'キャッチ'],
        ),
      ];
    });

    test('雨天時の条件検索で、屋外専用の遊びが除外され、室内対応の遊びが上位にランクインすること', () async {
      const condition = RecommendationCondition(
        childAge: 6,
        participantCount: 2,
        locationType: LocationType.indoor,
        availableTimeMinutes: 15,
        isRaining: true,
        season: Season.spring,
        availableTools: ['新聞紙/紙'],
        preferredAbilities: [AbilityType.agility],
      );

      final recommendations = await service.getRecommendations(
        candidates: mockActivities,
        condition: condition,
        limit: 5,
      );

      expect(recommendations.length, 1);
      expect(recommendations.first.activity.id, '2'); // 室内対応の遊び
      expect(recommendations.first.score, greaterThan(60.0));
      expect(recommendations.first.matchReasons.contains('雨の日でも楽しく遊べる！'), true);
    });

    test('希望条件にぴったり合致する場合、スコアが最高点近くに計算されること', () async {
      const condition = RecommendationCondition(
        childAge: 6,
        participantCount: 2,
        locationType: LocationType.park,
        availableTimeMinutes: 20,
        isRaining: false,
        season: Season.spring,
        availableTools: ['なし（道具不要）'],
        preferredAbilities: [AbilityType.stamina, AbilityType.agility],
      );

      final recommendations = await service.getRecommendations(
        candidates: mockActivities,
        condition: condition,
        limit: 5,
      );

      expect(recommendations.isNotEmpty, true);
      expect(recommendations.first.activity.id, '1'); // 屋外ダッシュ鬼ごっこ
      expect(recommendations.first.starRating, 5); // 5つ星評価
      expect(recommendations.first.starLabel, '最高にピッタリ！');
    });

    test('30分未満の遊びを完了した際に、運動効果を補完する遊びが正しく選出されること', () async {
      final playedActivity = mockActivities.firstWhere((a) => a.id == '1'); // 20分の高強度運動
      final complementary = await service.getComplementaryRecommendations(
        candidates: mockActivities,
        playedActivity: playedActivity,
        targetTotalMinutes: 30,
      );

      expect(complementary.isNotEmpty, true);
      expect(complementary.first.activity.id, '2'); // 不足している能力や強度の相乗効果を補う遊び
      expect(complementary.first.matchReasons.isNotEmpty, true);
    });

    test('「疲れている」「イライラしている」など今日の子どもの状態に合わせた推薦理由が付与されること', () async {
      const conditionTired = RecommendationCondition(
        childAge: 6,
        participantCount: 2,
        locationType: LocationType.indoor,
        availableTimeMinutes: 15,
        isRaining: true,
        season: Season.spring,
        childMoodState: ChildMoodState.slightlyTired,
      );

      final recommendations = await service.getRecommendations(
        candidates: mockActivities,
        condition: conditionTired,
        limit: 5,
      );

      expect(recommendations.isNotEmpty, true);
      expect(recommendations.first.matchReasons.contains('疲れている日でも負担なくゆったり楽しめる'), true);
    });
  });
}
