import '../core/constants/app_constants.dart';
import '../models/activity.dart';
import '../models/recommendation_condition.dart';
import '../models/scored_activity.dart';
import 'recommendation_service.dart';

/// ルールベース & スコアリングによる推薦サービス実装
class RuleBasedRecommendationService implements RecommendationService {
  @override
  Future<List<ScoredActivity>> getRecommendations({
    required List<Activity> candidates,
    required RecommendationCondition condition,
    int limit = 5,
  }) async {
    final scoredList = <ScoredActivity>[];

    for (final activity in candidates) {
      final matchReasons = <String>[];
      double score = 0.0;

      // 1. 雨天・屋内フィルタ
      if (condition.isRaining) {
        if (!activity.isRainOk && !activity.isIndoorOk) {
          continue; // 雨天かつ雨OK・屋内OKでなければ除外
        }
        matchReasons.add('雨の日でも楽しく遊べる！');
      }

      // 2. 年齢スコア (最大20点)
      if (condition.childAge >= activity.minAge &&
          condition.childAge <= activity.maxAge) {
        score += 20.0;
        matchReasons.add('対象年齢（${activity.minAge}〜${activity.maxAge}歳）にピッタリ！');
      } else {
        final ageDiff = condition.childAge < activity.minAge
            ? activity.minAge - condition.childAge
            : condition.childAge - activity.maxAge;
        if (ageDiff == 1) {
          score += 8.0;
        } else if (ageDiff == 2) {
          score += 2.0;
        }
      }

      // 3. 人数スコア (最大15点)
      if (condition.participantCount >= activity.minParticipants &&
          condition.participantCount <= activity.maxParticipants) {
        score += 15.0;
        matchReasons.add('参加人数（${condition.participantCount}人）に最適');
      } else {
        final countDiff = condition.participantCount < activity.minParticipants
            ? activity.minParticipants - condition.participantCount
            : condition.participantCount - activity.maxParticipants;
        if (countDiff == 1) {
          score += 5.0;
        }
      }

      // 4. 所要時間スコア (最大15点)
      final timeDiff = (activity.durationMinutes - condition.availableTimeMinutes).abs();
      if (timeDiff <= 5) {
        score += 15.0;
        matchReasons.add('隙間時間（約${activity.durationMinutes}分）に丁度いい');
      } else if (timeDiff <= 15) {
        score += 7.0;
      } else if (timeDiff <= 30) {
        score += 2.0;
      }

      // 5. 鍛えられる能力スコア (最大20点)
      int matchedAbilities = 0;
      for (final ability in condition.preferredAbilities) {
        if (activity.trainableAbilities.contains(ability)) {
          matchedAbilities++;
        }
      }
      if (matchedAbilities > 0) {
        final abilityScore = (matchedAbilities * 10.0).clamp(0.0, 20.0);
        score += abilityScore;
        matchReasons.add('伸ばしたい能力（${condition.preferredAbilities.map((e) => e.label).take(2).join("・")}）にアプローチ');
      }

      // 6. 道具スコア (最大10点)
      final requiresNoTools = activity.toolsRequired.isEmpty ||
          activity.toolsRequired.contains('なし（道具不要）');
      if (requiresNoTools) {
        score += 10.0;
        matchReasons.add('道具不要ですぐ遊べる');
      } else {
        bool hasAllTools = true;
        for (final tool in activity.toolsRequired) {
          if (!condition.availableTools.contains(tool)) {
            hasAllTools = false;
            break;
          }
        }
        if (hasAllTools) {
          score += 10.0;
          matchReasons.add('準備できる道具で遊べる');
        } else {
          score += 2.0; // 道具が足りない場合は加点低め
        }
      }

      // 7. 場所スコア (最大10点)
      if (activity.locationTypes.contains(condition.locationType)) {
        score += 10.0;
        matchReasons.add('ご希望の場所（${condition.locationType.label}）でプレイ可能');
      }

      // 8. 季節適合スコア (最大10点)
      final isSeasonMatch = activity.seasons.contains(condition.season);
      final isSpecificSeason = activity.seasons.length <= 2; // 特定の季節に特化したアクティビティ

      if (isSeasonMatch) {
        score += 10.0;
        if (isSpecificSeason) {
          matchReasons.add('${condition.season.label}ならではのおすすめ遊び！');
        }
      } else {
        // 特定季節限定で、現在の季節が含まれない場合は不適切なため大幅減点
        if (isSpecificSeason) {
          score -= 35.0;
        } else {
          score -= 8.0;
        }
      }

      // 9. 子どもの状態・気分適合スコア (最大15点)
      switch (condition.childMoodState) {
        case ChildMoodState.energetic:
          if (activity.intensityLevel == IntensityLevel.high ||
              activity.trainableAbilities.contains(AbilityType.stamina)) {
            score += 15.0;
            matchReasons.add('元気いっぱいな日に思い切り体力発散！');
          } else {
            score += 5.0;
          }
          break;
        case ChildMoodState.slightlyTired:
          if (activity.intensityLevel == IntensityLevel.low ||
              activity.durationMinutes <= 15) {
            score += 15.0;
            matchReasons.add('疲れている日でも負担なくゆったり楽しめる');
          } else if (activity.intensityLevel == IntensityLevel.high) {
            score -= 15.0; // 疲れている時の高強度運動は減点
          }
          break;
        case ChildMoodState.frustrated:
          final isReleaseActivity = activity.intensityLevel == IntensityLevel.high ||
              activity.toolsRequired.contains('新聞紙/紙') ||
              activity.toolsRequired.contains('ボール') ||
              activity.title.contains('スナイパー') ||
              activity.title.contains('ジャンプ');
          if (isReleaseActivity) {
            score += 15.0;
            matchReasons.add('モヤモヤ・ストレス発散にぴったり！');
          } else {
            score += 5.0;
          }
          break;
        case ChildMoodState.unfocused:
          if (activity.difficultyLevel == DifficultyLevel.easy ||
              activity.durationMinutes <= 15) {
            score += 15.0;
            matchReasons.add('ルールが簡単で直感的にすぐ夢中になれる！');
          }
          break;
        case ChildMoodState.bored:
          if (activity.trainableAbilities.contains(AbilityType.thinking) ||
              activity.toolsRequired.isNotEmpty) {
            score += 15.0;
            matchReasons.add('退屈な時間にワクワクの刺激！');
          }
          break;
        case ChildMoodState.normal:
          score += 10.0;
          break;
      }

      // スコアの上限を100点満点に正規化（クランプ）
      final clampedScore = score.clamp(0.0, 100.0);

      scoredList.add(
        ScoredActivity(
          activity: activity,
          score: clampedScore,
          matchReasons: matchReasons,
        ),
      );
    }

    // スコア降順ソート
    scoredList.sort((a, b) => b.score.compareTo(a.score));

    // 指定件数まで絞り込んで返却
    return scoredList.take(limit).toList();
  }

  @override
  Future<List<ScoredActivity>> getComplementaryRecommendations({
    required List<Activity> candidates,
    required Activity playedActivity,
    int targetTotalMinutes = 30,
  }) async {
    final remainingMinutes = targetTotalMinutes - playedActivity.durationMinutes;
    if (remainingMinutes <= 0) return [];

    final scoredList = <ScoredActivity>[];

    for (final activity in candidates) {
      // プレイした遊び自体は除外
      if (activity.id == playedActivity.id) continue;

      final matchReasons = <String>[];
      double score = 0.0;

      // 1. 運動能力の補完 (最大40点)
      final missingAbilities = activity.trainableAbilities
          .where((ability) => !playedActivity.trainableAbilities.contains(ability))
          .toList();

      if (missingAbilities.isNotEmpty) {
        score += (missingAbilities.length * 15.0).clamp(0.0, 40.0);
        matchReasons.add(
            '先ほどの遊びに【${missingAbilities.take(2).map((e) => e.label).join("・")}】をプラス！');
      }

      // 2. 運動強度の補完バランス (最大30点)
      if (playedActivity.intensityLevel == IntensityLevel.high) {
        if (activity.intensityLevel == IntensityLevel.medium ||
            activity.intensityLevel == IntensityLevel.low) {
          score += 30.0;
          matchReasons.add('ハードな運動のあとの心地よい整理運動に最適');
        }
      } else if (playedActivity.intensityLevel == IntensityLevel.low) {
        if (activity.intensityLevel == IntensityLevel.medium ||
            activity.intensityLevel == IntensityLevel.high) {
          score += 30.0;
          matchReasons.add('あわせて体をしっかり動かすバランス運動');
        }
      } else {
        score += 20.0;
      }

      // 3. 残り時間の適合度 (最大20点)
      final timeDiff = (activity.durationMinutes - remainingMinutes).abs();
      if (timeDiff <= 5) {
        score += 20.0;
        matchReasons.add('合わせてぴったり合計約30分！');
      } else if (timeDiff <= 10) {
        score += 12.0;
      } else {
        score += 5.0;
      }

      // 4. 実施場所の互換性 (最大10点)
      final sharesLocation = activity.locationTypes
          .any((loc) => playedActivity.locationTypes.contains(loc));
      if (sharesLocation) {
        score += 10.0;
      }

      scoredList.add(
        ScoredActivity(
          activity: activity,
          score: score.clamp(0.0, 100.0),
          matchReasons: matchReasons,
        ),
      );
    }

    scoredList.sort((a, b) => b.score.compareTo(a.score));
    return scoredList.take(2).toList(); // 補完候補上位2件
  }
}
