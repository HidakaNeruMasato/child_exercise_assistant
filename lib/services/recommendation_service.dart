import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/activity.dart';
import '../models/recommendation_condition.dart';
import '../models/scored_activity.dart';
import 'rule_based_recommendation_service.dart';

/// 推薦サービスのインターフェース（DI用）
abstract class RecommendationService {
  /// 条件と候補データを受け取り、スコアリングした推薦リストを取得する
  Future<List<ScoredActivity>> getRecommendations({
    required List<Activity> candidates,
    required RecommendationCondition condition,
    int limit = 5,
  });

  /// 実施した遊びに対する運動効果の「補完（相乗効果）」遊びを取得する
  Future<List<ScoredActivity>> getComplementaryRecommendations({
    required List<Activity> candidates,
    required Activity playedActivity,
    int targetTotalMinutes = 30,
  });
}

/// Riverpodによる推薦プロバイダ（初期実装はルールベースサービス）
final recommendationServiceProvider = Provider<RecommendationService>((ref) {
  return RuleBasedRecommendationService();
  // 将来 Geminii API 導入時は以下のようにProviderを入れ替えるだけでUI側のコード変更は不要：
  // return ref.watch(aiRecommendationServiceProvider);
});
