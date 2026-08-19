/// 場所の種別
enum LocationType {
  indoor,  // 屋内
  park,    // 公園
  yard,    // 自宅庭・バルコニー
  spacious // 広場・グラウンド
}

extension LocationTypeX on LocationType {
  String get label {
    switch (this) {
      case LocationType.indoor:
        return '屋内・室内';
      case LocationType.park:
        return '公園';
      case LocationType.yard:
        return '自宅のお庭・ベランダ';
      case LocationType.spacious:
        return '広場・グラウンド';
    }
  }
}

/// 運動強度
enum IntensityLevel {
  low,    // 軽め (お散歩・ストレッチ程度)
  medium, // ふつう (鬼ごっこ・ボール遊び)
  high    // 高め (ダッシュ・全力運動)
}

extension IntensityLevelX on IntensityLevel {
  String get label {
    switch (this) {
      case IntensityLevel.low:
        return 'ゆったり（軽め）';
      case IntensityLevel.medium:
        return 'ほどほど（中程度）';
      case IntensityLevel.high:
        return 'アクティブ（高強度）';
    }
  }
}

/// 難易度
enum DifficultyLevel {
  easy,   // かんたん (幼児向け)
  normal, // ふつう
  hard    // チャレンジ (少し頭や体を使う)
}

extension DifficultyLevelX on DifficultyLevel {
  String get label {
    switch (this) {
      case DifficultyLevel.easy:
        return 'かんたん';
      case DifficultyLevel.normal:
        return 'ふつう';
      case DifficultyLevel.hard:
        return 'チャレンジ';
    }
  }
}

/// 鍛えられる能力
enum AbilityType {
  stamina,     // 持久力・スタミナ
  agility,     // 敏捷性・素早さ
  balance,     // バランス感覚・体幹
  flexibility, // 柔軟性
  rhythm,      // リズム感
  cooperation, // 協調性・社会性
  thinking     // 思考力・ルール理解
}

extension AbilityTypeX on AbilityType {
  String get label {
    switch (this) {
      case AbilityType.stamina:
        return '体力・スタミナ';
      case AbilityType.agility:
        return '敏捷性（素早さ）';
      case AbilityType.balance:
        return 'バランス感覚・体幹';
      case AbilityType.flexibility:
        return '柔軟性';
      case AbilityType.rhythm:
        return 'リズム感';
      case AbilityType.cooperation:
        return '協調性・チームワーク';
      case AbilityType.thinking:
        return '思考力・作戦';
    }
  }
}

/// 季節
enum Season {
  spring, // 春
  summer, // 夏
  autumn, // 秋
  winter, // 冬
}

extension SeasonX on Season {
  String get label {
    switch (this) {
      case Season.spring:
        return '春 🌸';
      case Season.summer:
        return '夏 ☀️';
      case Season.autumn:
        return '秋 🍁';
      case Season.winter:
        return '冬 ❄️';
    }
  }

  /// 現在の日時・月からデフォルトの季節を判定
  static Season get currentSeason {
    final month = DateTime.now().month;
    if (month >= 3 && month <= 5) return Season.spring;
    if (month >= 6 && month <= 8) return Season.summer;
    if (month >= 9 && month <= 11) return Season.autumn;
    return Season.winter;
  }
}

/// 今日の子どもの状態・気分
enum ChildMoodState {
  energetic,     // 元気いっぱい ⚡
  normal,        // 普通 😊
  slightlyTired, // 少し疲れている 🥱
  unfocused,     // 集中できなさそう 🌀
  frustrated,    // イライラしている 😤
  bored,         // 退屈している 🎈
}

extension ChildMoodStateX on ChildMoodState {
  String get label {
    switch (this) {
      case ChildMoodState.energetic:
        return '元気いっぱい ⚡';
      case ChildMoodState.normal:
        return '普通 😊';
      case ChildMoodState.slightlyTired:
        return '少し疲れている 🥱';
      case ChildMoodState.unfocused:
        return '集中できなさそう 🌀';
      case ChildMoodState.frustrated:
        return 'イライラしている 😤';
      case ChildMoodState.bored:
        return '退屈している 🎈';
    }
  }

  String get description {
    switch (this) {
      case ChildMoodState.energetic:
        return '全身を使って思い切り体力を発散できる運動がおすすめ';
      case ChildMoodState.normal:
        return 'バランスよく様々な遊びを楽しめる状態';
      case ChildMoodState.slightlyTired:
        return '負担が少なくゆったり気分転換できる遊びがおすすめ';
      case ChildMoodState.unfocused:
        return 'ルールがシンプルで直感的に没頭できる遊びがおすすめ';
      case ChildMoodState.frustrated:
        return 'ビリビリ・投げる・跳躍など気持ちをスカッと発散できる遊びがおすすめ';
      case ChildMoodState.bored:
        return '宝探しやごっこ遊びなどワクワク刺激がある遊びがおすすめ';
    }
  }
}

/// 親の参加度・参加しやすさ
enum ParentInvolvementLevel {
  watching, // 見守りメイン（大人は応援・指示役）
  moderate, // ちょこっと参加（手助け・審判役）
  active,   // 親子でガッツリ参加（対戦・一緒に動く）
}

extension ParentInvolvementLevelX on ParentInvolvementLevel {
  String get label {
    switch (this) {
      case ParentInvolvementLevel.watching:
        return '見守りメイン';
      case ParentInvolvementLevel.moderate:
        return 'ちょこっと参加';
      case ParentInvolvementLevel.active:
        return '親子でガッツリ';
    }
  }

  String get description {
    switch (this) {
      case ParentInvolvementLevel.watching:
        return '大人は見守り・声掛け中心でラクラク';
      case ParentInvolvementLevel.moderate:
        return '審判やアイテム役で楽しくサポート';
      case ParentInvolvementLevel.active:
        return '大人も一緒に動いて汗をかく！';
    }
  }
}

/// アプリ共通定数
class AppConstants {
  static const String appName = 'こどもと、なにしよう。';
  static const String appSubtitle = '年齢や場所、時間に合わせて、今日の遊びをお手伝い。';
  static const String logoBannerPath = 'assets/images/app_logo_banner.png';
  static const String appIconPath = 'assets/images/app_icon.png';
  
  /// 推薦件数の標準制限
  static const int defaultRecommendationLimit = 5;
  
  /// 定番の道具リスト
  static const List<String> commonTools = [
    'なし（道具不要）',
    'ボール',
    '縄跳び',
    'フリスビー',
    'タオル',
    '新聞紙/紙',
    'マーカー/コーン',
  ];
}
