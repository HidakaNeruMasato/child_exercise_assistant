import '../core/constants/app_constants.dart';

/// 遊び（アクティビティ）データモデル
class Activity {
  final String id;
  final String title;
  final String description;
  final int minAge;
  final int maxAge;
  final int minParticipants;
  final int maxParticipants;
  final int durationMinutes;
  final List<LocationType> locationTypes;
  final List<String> toolsRequired;
  final IntensityLevel intensityLevel;
  final DifficultyLevel difficultyLevel;
  final List<AbilityType> trainableAbilities;
  final bool isRainOk;
  final bool isIndoorOk;
  final int safetyLevel; // 1〜5 (高いほど安全)
  final List<String> safetyTips;
  final List<String> steps;
  final ParentInvolvementLevel parentInvolvement; // 親の参加度
  final List<String> parentPraiseTips; // 親からの声掛け例
  final List<Season> seasons; // 推奨・適正季節（オールシーズン対応含む）
  final String? imageUrl;

  const Activity({
    required this.id,
    required this.title,
    required this.description,
    required this.minAge,
    required this.maxAge,
    required this.minParticipants,
    required this.maxParticipants,
    required this.durationMinutes,
    required this.locationTypes,
    required this.toolsRequired,
    required this.intensityLevel,
    required this.difficultyLevel,
    required this.trainableAbilities,
    required this.isRainOk,
    required this.isIndoorOk,
    required this.safetyLevel,
    required this.safetyTips,
    required this.steps,
    this.parentInvolvement = ParentInvolvementLevel.moderate,
    this.parentPraiseTips = const [],
    this.seasons = Season.values,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'minAge': minAge,
      'maxAge': maxAge,
      'minParticipants': minParticipants,
      'maxParticipants': maxParticipants,
      'durationMinutes': durationMinutes,
      'locationTypes': locationTypes.map((e) => e.name).toList(),
      'toolsRequired': toolsRequired,
      'intensityLevel': intensityLevel.name,
      'difficultyLevel': difficultyLevel.name,
      'trainableAbilities': trainableAbilities.map((e) => e.name).toList(),
      'isRainOk': isRainOk,
      'isIndoorOk': isIndoorOk,
      'safetyLevel': safetyLevel,
      'safetyTips': safetyTips,
      'steps': steps,
      'parentInvolvement': parentInvolvement.name,
      'parentPraiseTips': parentPraiseTips,
      'seasons': seasons.map((e) => e.name).toList(),
      'imageUrl': imageUrl,
    };
  }

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      minAge: (json['minAge'] as num?)?.toInt() ?? 3,
      maxAge: (json['maxAge'] as num?)?.toInt() ?? 12,
      minParticipants: (json['minParticipants'] as num?)?.toInt() ?? 1,
      maxParticipants: (json['maxParticipants'] as num?)?.toInt() ?? 10,
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 15,
      locationTypes: (json['locationTypes'] as List<dynamic>?)
              ?.map((e) => LocationType.values.byName(e.toString()))
              .toList() ??
          [LocationType.park],
      toolsRequired: (json['toolsRequired'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      intensityLevel: IntensityLevel.values.byName(
          json['intensityLevel'] as String? ?? IntensityLevel.medium.name),
      difficultyLevel: DifficultyLevel.values.byName(
          json['difficultyLevel'] as String? ?? DifficultyLevel.normal.name),
      trainableAbilities: (json['trainableAbilities'] as List<dynamic>?)
              ?.map((e) => AbilityType.values.byName(e.toString()))
              .toList() ??
          [],
      isRainOk: json['isRainOk'] as bool? ?? false,
      isIndoorOk: json['isIndoorOk'] as bool? ?? false,
      safetyLevel: (json['safetyLevel'] as num?)?.toInt() ?? 5,
      safetyTips: (json['safetyTips'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      steps: (json['steps'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      parentInvolvement: ParentInvolvementLevel.values.byName(
          json['parentInvolvement'] as String? ??
              ParentInvolvementLevel.moderate.name),
      parentPraiseTips: (json['parentPraiseTips'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      seasons: (json['seasons'] as List<dynamic>?)
              ?.map((e) => Season.values.byName(e.toString()))
              .toList() ??
          Season.values,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  /// スプレッドシート / CSV行からのパース処理
  factory Activity.fromCsvRow(List<dynamic> row) {
    String str(int idx) => idx < row.length ? row[idx].toString().trim() : '';
    int numVal(int idx, int def) => int.tryParse(str(idx)) ?? def;
    bool boolVal(int idx) => str(idx) == 'はい' || str(idx).toLowerCase() == 'true';
    List<String> listVal(int idx) {
      final s = str(idx);
      if (s.isEmpty) return [];
      return s.split(';').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }

    // LocationType
    final locs = listVal(8).map((name) {
      try {
        return LocationType.values.byName(name);
      } catch (_) {
        return LocationType.park;
      }
    }).toList();

    // IntensityLevel
    IntensityLevel intensity;
    try {
      intensity = IntensityLevel.values.byName(str(10));
    } catch (_) {
      intensity = IntensityLevel.medium;
    }

    // DifficultyLevel
    DifficultyLevel difficulty;
    try {
      difficulty = DifficultyLevel.values.byName(str(11));
    } catch (_) {
      difficulty = DifficultyLevel.normal;
    }

    // AbilityType
    final abilities = listVal(12).map((name) {
      try {
        return AbilityType.values.byName(name);
      } catch (_) {
        return AbilityType.stamina;
      }
    }).toList();

    // ParentInvolvementLevel
    ParentInvolvementLevel parentInv;
    try {
      parentInv = ParentInvolvementLevel.values.byName(str(18));
    } catch (_) {
      parentInv = ParentInvolvementLevel.moderate;
    }

    // Season
    final seasons = listVal(20).map((name) {
      try {
        return Season.values.byName(name);
      } catch (_) {
        return Season.spring;
      }
    }).toList();

    return Activity(
      id: str(0),
      title: str(1),
      description: str(2),
      minAge: numVal(3, 3),
      maxAge: numVal(4, 12),
      minParticipants: numVal(5, 1),
      maxParticipants: numVal(6, 6),
      durationMinutes: numVal(7, 20),
      locationTypes: locs.isNotEmpty ? locs : [LocationType.park],
      toolsRequired: listVal(9),
      intensityLevel: intensity,
      difficultyLevel: difficulty,
      trainableAbilities: abilities,
      isRainOk: boolVal(13),
      isIndoorOk: boolVal(14),
      safetyLevel: numVal(15, 5),
      safetyTips: listVal(16),
      steps: listVal(17),
      parentInvolvement: parentInv,
      parentPraiseTips: listVal(19),
      seasons: seasons.isNotEmpty ? seasons : Season.values,
      imageUrl: str(21).isNotEmpty ? str(21) : null,
    );
  }
}
