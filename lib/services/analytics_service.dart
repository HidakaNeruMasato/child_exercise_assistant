import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/recommendation_condition.dart';

/// Firebase Analytics 一元管理サービス
class AnalyticsService {
  final FirebaseAnalytics _analytics;

  AnalyticsService({FirebaseAnalytics? analytics})
      : _analytics = analytics ?? FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver getObserver() {
    return FirebaseAnalyticsObserver(analytics: _analytics);
  }

  // --- イベント名定義 ---
  static const String eventViewHome = 'view_home';
  static const String eventOpenCondition = 'open_condition';
  static const String eventChangeCondition = 'change_condition';
  static const String eventSearchRecommendations = 'search_recommendations';
  static const String eventViewRecommendations = 'view_recommendations';
  static const String eventViewActivity = 'view_activity';
  static const String eventFavoriteActivity = 'favorite_activity';
  static const String eventCompleteActivity = 'complete_activity';
  static const String eventSubmitFeedback = 'submit_feedback';

  // --- パラメータ名定義 ---
  static const String paramAge = 'age';
  static const String paramParticipants = 'participants';
  static const String paramLocation = 'location';
  static const String paramDuration = 'duration';
  static const String paramMood = 'mood';
  static const String paramSeason = 'season';
  static const String paramWeather = 'weather';
  static const String paramRecommendationCount = 'recommendation_count';
  static const String paramActivityId = 'activity_id';
  static const String paramActivityCategory = 'activity_category';
  static const String paramAction = 'action';
  static const String paramFeedbackType = 'feedback_type';

  /// 1. ホーム画面表示時
  Future<void> logViewHome() async {
    await _logEvent(eventViewHome);
  }

  /// 2. 条件変更ダイアログ/モーダル開下時
  Future<void> logOpenCondition() async {
    await _logEvent(eventOpenCondition);
  }

  /// 3. 条件変更時
  Future<void> logChangeCondition(RecommendationCondition condition) async {
    await _logEvent(
      eventChangeCondition,
      parameters: _extractConditionParams(condition),
    );
  }

  /// 4. おすすめ検索ボタンタップ時 ★【重要イベント】
  Future<void> logSearchRecommendations(RecommendationCondition condition) async {
    await _logEvent(
      eventSearchRecommendations,
      parameters: _extractConditionParams(condition),
    );
  }

  /// 5. おすすめ一覧画面表示時
  Future<void> logViewRecommendations({required int recommendationCount}) async {
    await _logEvent(
      eventViewRecommendations,
      parameters: {
        paramRecommendationCount: recommendationCount,
      },
    );
  }

  /// 6. 遊び詳細画面表示時 ★【重要イベント】
  Future<void> logViewActivity({
    required String activityId,
    String? category,
  }) async {
    await _logEvent(
      eventViewActivity,
      parameters: {
        paramActivityId: activityId,
        if (category != null) paramActivityCategory: category,
      },
    );
  }

  /// 7. お気に入り追加/解除時
  Future<void> logFavoriteActivity({
    required String activityId,
    required bool isAdded,
  }) async {
    await _logEvent(
      eventFavoriteActivity,
      parameters: {
        paramActivityId: activityId,
        paramAction: isAdded ? 'add' : 'remove',
      },
    );
  }

  /// 8. 「今日あそんだ！」記録完了時 ★【重要イベント】
  /// ※個人情報保護のため、子ども氏名ではなく参加人数 (int) のみ記録
  Future<void> logCompleteActivity({
    required String activityId,
    required int participantsCount,
  }) async {
    await _logEvent(
      eventCompleteActivity,
      parameters: {
        paramActivityId: activityId,
        paramParticipants: participantsCount,
      },
    );
  }

  /// 9. フィードバック送信時
  /// ※個人情報保護のため、自由記述コメント本文は送信せず事実および種別のみ送信
  Future<void> logSubmitFeedback({
    required String feedbackType,
    String? activityId,
  }) async {
    await _logEvent(
      eventSubmitFeedback,
      parameters: {
        paramFeedbackType: feedbackType,
        if (activityId != null) paramActivityId: activityId,
      },
    );
  }

  /// 汎用イベント送信内部メソッド
  Future<void> _logEvent(
    String eventName, {
    Map<String, Object>? parameters,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('[Analytics Log] Event: $eventName, Params: $parameters');
      }
      await _analytics.logEvent(
        name: eventName,
        parameters: parameters,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Analytics Warning] Failed to log event $eventName: $e');
      }
    }
  }

  /// 条件オブジェクトから安全な分析用パラメータマップを作成
  Map<String, Object> _extractConditionParams(RecommendationCondition condition) {
    return {
      paramAge: condition.childAge,
      paramParticipants: condition.participantCount,
      paramLocation: condition.locationType.name,
      paramDuration: condition.availableTimeMinutes,
      paramMood: condition.childMoodState.name,
      paramSeason: condition.season.name,
      paramWeather: condition.isRaining ? 'rainy' : 'sunny',
    };
  }
}

/// AnalyticsService Riverpod Provider
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});
