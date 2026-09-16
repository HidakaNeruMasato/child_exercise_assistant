import 'dart:convert';
import 'dart:io';

void main(List<String> args) async {
  if (args.isEmpty) {
    _printUsage();
    return;
  }

  final command = args[0].toLowerCase();
  final subArgs = args.sublist(1);

  switch (command) {
    case 'status':
      await _showStatus(subArgs);
      break;

    case 'prompts':
      await _runScript('tools/image_pipeline/scripts/generate_prompts.dart', subArgs);
      break;

    case 'inspect':
      await _runScript('tools/image_pipeline/scripts/inspect_images.dart', subArgs);
      break;

    case 'approve':
      if (subArgs.isEmpty) {
        print('Error: approve コマンドには activity_id を指定してください。');
        print('例: dart run tools/image_pipeline/scripts/image_pipeline.dart approve act_002');
        exit(1);
      }
      await _runScript('tools/image_pipeline/scripts/approve_image.dart', subArgs);
      break;

    case 'sync':
      await _runScript('tools/image_pipeline/scripts/sync_approved_images.dart', subArgs);
      break;

    case 'publish':
    case 'export-review':
      await _runScript('tools/image_pipeline/scripts/publish_review_data.dart', subArgs);
      break;

    case 'review':
      print('ℹ️  GitHub Pages 上のレビュー UI: https://hidakanerumasato.github.io/child_exercise_assistant/review/');
      print('ℹ️  ローカルレビューサーバーを起動中...');
      await _runScript('tools/image_pipeline/scripts/review_server.dart', subArgs);
      break;

    default:
      print('エラー: 未知のコマンド "$command"');
      _printUsage();
      exit(1);
  }
}

void _printUsage() {
  print('====================================================');
  print('🎨 「こどもと、なにしよう。」画像制作パイプライン CLI');
  print('====================================================');
  print('使い方:');
  print('  dart run tools/image_pipeline/scripts/image_pipeline.dart <command> [options]\n');
  print('利用可能なコマンド:');
  print('  status   : 全アクティビティの画像制作・検査・承認・登録状況を表示');
  print('  prompts  : activities.csv から固定画風ルール適用プロンプトを一括生成');
  print('  inspect  : 生成画像のAI品質検査 (17項目チェック) を実行');
  print('  publish  : GitHub Pages 静的レビュー画面用データ (web/review/) を出力');
  print('  review   : 人間による最終確認ローカルサーバー (http://localhost:8080) を起動');
  print('  approve  : 指定したアクティビティの画像を承認 (APPROVED)');
  print('  sync     : 承認済み画像を assets/images/{activity_id}.webp へ安全同期');
  print('====================================================');
}

Future<void> _runScript(String scriptPath, List<String> args) async {
  final result = await Process.run('dart', ['run', scriptPath, ...args]);
  stdout.write(result.stdout);
  stderr.write(result.stderr);
  if (result.exitCode != 0) {
    exit(result.exitCode);
  }
}

Future<void> _showStatus(List<String> args) async {
  final String? filterStatus = args.isNotEmpty ? args[0].toUpperCase() : null;

  final metadataDir = Directory('tools/image_pipeline/metadata');
  if (!metadataDir.existsSync()) {
    print('ℹ️ まだメタデータが存在しません。最初に "prompts" コマンドを実行してください。');
    return;
  }

  final files = metadataDir.listSync().whereType<File>().where((f) => f.path.endsWith('.json')).toList();
  files.sort((a, b) => a.path.compareTo(b.path));

  print('====================================================');
  print('      「こどもと、なにしよう。」画像制作ステータス一覧');
  print('====================================================');

  final counts = <String, int>{
    'NOT_STARTED': 0,
    'PROMPT_GENERATED': 0,
    'GENERATED': 0,
    'INSPECTING': 0,
    'REPAIR_REQUIRED': 0,
    'REGENERATE_REQUIRED': 0,
    'HUMAN_REVIEW': 0,
    'APPROVED': 0,
    'REGISTERED': 0,
    'REJECTED': 0,
    'MISSING_DATA': 0,
  };

  for (final f in files) {
    try {
      final Map<String, dynamic> data = jsonDecode(f.readAsStringSync());
      final String activityId = data['activity_id'] ?? '';
      final String title = data['title'] ?? '無題';
      final String status = data['status'] ?? 'NOT_STARTED';

      counts[status] = (counts[status] ?? 0) + 1;

      if (filterStatus != null && filterStatus != 'ALL' && filterStatus != status) {
        continue;
      }

      String icon = '❓';
      if (status == 'REGISTERED') icon = '🎉';
      if (status == 'APPROVED') icon = '✅';
      if (status == 'HUMAN_REVIEW') icon = '🔍';
      if (status == 'REPAIR_REQUIRED') icon = '⚠️';
      if (status == 'REGENERATE_REQUIRED') icon = '❌';
      if (status == 'PROMPT_GENERATED') icon = '📝';
      if (status == 'MISSING_DATA') icon = '🚨';

      print('$icon $activityId | ${title.padRight(16)} -> [$status]');
    } catch (_) {}
  }

  print('\n----------------------------------------------------');
  print('ステータス別集計:');
  counts.forEach((st, count) {
    if (count > 0) print('  - ${st.padRight(20)}: $count 件');
  });
  print('全管理対象: ${files.length} 件');
  print('----------------------------------------------------');
}
