import 'activity.dart';

/// スコアリング済み遊び推薦結果モデル
class ScoredActivity {
  final Activity activity;
  final double score; // 0.0 〜 100.0
  final List<String> matchReasons; // おすすめ理由（例: 「年齢ぴったり！」「希望の公園で遊べる」）

  const ScoredActivity({
    required this.activity,
    required this.score,
    required this.matchReasons,
  });

  /// 1〜5 の5つ星評価の星の数
  int get starRating {
    if (score >= 88) return 5;
    if (score >= 70) return 4;
    if (score >= 50) return 3;
    if (score >= 35) return 2;
    return 1;
  }

  /// 星評価に応じた保護者向けの柔らかい評価ラベル
  String get starLabel {
    switch (starRating) {
      case 5:
        return '最高にピッタリ！';
      case 4:
        return 'とてもおすすめ！';
      case 3:
        return 'おすすめ！';
      case 2:
        return 'ためしてみてね';
      default:
        return '気分転換に';
    }
  }
}
