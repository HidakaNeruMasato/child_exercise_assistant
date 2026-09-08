import 'dart:convert';
import 'dart:io';

void main() {
  final csvFile = File('assets/data/activities.csv');
  if (!csvFile.existsSync()) {
    print('Error: assets/data/activities.csv not found.');
    exit(1);
  }

  final lines = csvFile.readAsLinesSync(encoding: utf8);
  if (lines.length <= 1) {
    print('Error: activities.csv is empty or missing rows.');
    exit(1);
  }

  print('====================================================');
  print('          遊び画像登録状況チェック (Image Status Check)          ');
  print('====================================================');

  int totalCount = 0;
  int registeredCount = 0;
  int missingCount = 0;

  final List<String> missingIds = [];

  for (int i = 1; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty) continue;

    final parts = line.split(',');
    if (parts.isEmpty || parts[0].trim().isEmpty) continue;

    final String activityId = parts[0].trim().replaceAll('"', '');
    final String title = parts.length > 1 ? parts[1].trim().replaceAll('"', '') : '';

    totalCount++;

    final webpFile = File('assets/images/$activityId.webp');
    final bool exists = webpFile.existsSync();

    if (exists) {
      registeredCount++;
      print('✓  $activityId | $title -> $activityId.webp (登録済み)');
    } else {
      missingCount++;
      missingIds.add('$activityId ($title)');
      print('✗  $activityId | $title -> 画像未登録 (assets/images/$activityId.webp)');
    }
  }

  print('----------------------------------------------------');
  print('サマリー:');
  print('全遊び件数 : $totalCount 件');
  print('画像登録済み : $registeredCount 件');
  print('画像未登録   : $missingCount 件');
  print('----------------------------------------------------');

  if (missingCount > 0) {
    print('\n【未登録のactivity_id一覧】:');
    for (final missing in missingIds) {
      print(' - $missing');
    }
    print('\nCIステータス: 失敗 (終了コード 1)');
    exit(1);
  } else {
    print('\n🎉 すべての遊びの画像が正しく登録されています！');
    print('CIステータス: 成功 (終了コード 0)');
    exit(0);
  }
}
