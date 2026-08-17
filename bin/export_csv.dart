import 'dart:io';
import 'package:child_exercise_assistant/repositories/activity_repository.dart';

void main() async {
  final repo = FirestoreActivityRepository();
  final activities = await repo.getAllActivities();

  final sb = StringBuffer();
  // UTF-8 BOM Header for Excel / Spreadsheet compatibility
  sb.write('\uFEFF');
  sb.writeln('ID,タイトル,説明文,最小対象年齢,最大対象年齢,最小参加人数,最大参加人数,想定時間(分),実施場所,準備する道具,運動強度,難易度,伸ばせる能力,雨天OK,屋内OK,安全レベル,安全Tips,遊ぶ手順,親の参加度,親の声掛け例,推し季節,画像URL');

  for (final a in activities) {
    final locations = a.locationTypes.map((e) => e.label).join(';');
    final tools = a.toolsRequired.join(';');
    final abilities = a.trainableAbilities.map((e) => e.label).join(';');
    final safetyTips = a.safetyTips.join(';');
    final steps = a.steps.join(';');
    final praiseTips = a.parentPraiseTips.join(';');
    final seasons = a.seasons.map((e) => e.label).join(';');

    final row = [
      a.id,
      _escapeCsv(a.title),
      _escapeCsv(a.description),
      a.minAge,
      a.maxAge,
      a.minParticipants,
      a.maxParticipants,
      a.durationMinutes,
      _escapeCsv(locations),
      _escapeCsv(tools),
      a.intensityLevel.label,
      a.difficultyLevel.label,
      _escapeCsv(abilities),
      a.isRainOk ? 'はい' : 'いいえ',
      a.isIndoorOk ? 'はい' : 'いいえ',
      a.safetyLevel,
      _escapeCsv(safetyTips),
      _escapeCsv(steps),
      a.parentInvolvement.label,
      _escapeCsv(praiseTips),
      _escapeCsv(seasons),
      a.imageUrl ?? '',
    ];

    sb.writeln(row.join(','));
  }

  final dir = Directory('assets/data');
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }

  final file = File('assets/data/activities.csv');
  file.writeAsStringSync(sb.toString());
  print('Successfully exported ${activities.length} activities to assets/data/activities.csv');
}

String _escapeCsv(String val) {
  if (val.contains(',') || val.contains('"') || val.contains('\n') || val.contains(';')) {
    return '"${val.replaceAll('"', '""')}"';
  }
  return val;
}
