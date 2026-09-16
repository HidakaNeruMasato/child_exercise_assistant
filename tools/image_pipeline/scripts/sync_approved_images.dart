import 'dart:convert';
import 'dart:io';

void main(List<String> args) async {
  final bool allowOverwrite = args.contains('--overwrite') || args.contains('--force');

  final approvedDir = Directory('tools/image_pipeline/approved');
  final targetAssetDir = Directory('assets/images');
  final metadataDir = Directory('tools/image_pipeline/metadata');

  if (!approvedDir.existsSync()) {
    print('Error: tools/image_pipeline/approved/ ディレクトリが存在しません。');
    exit(1);
  }
  if (!targetAssetDir.existsSync()) {
    targetAssetDir.createSync(recursive: true);
  }

  final approvedFiles = approvedDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.webp') || f.path.endsWith('.jpg') || f.path.endsWith('.png'))
      .toList();

  if (approvedFiles.isEmpty) {
    print('ℹ️ 同期対象の承認済み画像 (approved/ 内) がありません。');
    print('  先に approve コマンドで画像を承認してください。');
    exit(0);
  }

  print('====================================================');
  print('      承認済み画像アセット同期 (Sync to assets/images/)   ');
  print('====================================================');

  int syncedCount = 0;
  int skippedCount = 0;

  for (final file in approvedFiles) {
    final fileName = file.uri.pathSegments.last;
    final activityId = fileName.substring(0, fileName.lastIndexOf('.'));
    final targetFile = File('${targetAssetDir.path}/$activityId.webp');

    if (targetFile.existsSync() && !allowOverwrite) {
      print('⚠️ $activityId.webp は既に assets/images/ に存在するためスキップしました。');
      print('   (上書き同期するには --overwrite オプションを付与してください)');
      skippedCount++;
      continue;
    }

    file.copySync(targetFile.path);
    syncedCount++;
    print('✅ 同期完了: ${file.path} -> ${targetFile.path}');

    // メタデータステータスを REGISTERED に更新
    final metaFile = File('${metadataDir.path}/$activityId.json');
    if (metaFile.existsSync()) {
      try {
        final metadata = jsonDecode(metaFile.readAsStringSync());
        metadata['status'] = 'REGISTERED';
        metadata['registered_at'] = DateTime.now().toIso8601String();
        metadata['updated_at'] = DateTime.now().toIso8601String();
        metaFile.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(metadata));
      } catch (_) {}
    }
  }

  print('\n----------------------------------------------------');
  print('同期サマリー:');
  print('同期登録完了: $syncedCount 件');
  print('上書き保護スキップ: $skippedCount 件');
  print('----------------------------------------------------');
}
