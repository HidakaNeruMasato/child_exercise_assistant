import 'dart:convert';
import 'dart:io';

void main(List<String> args) async {
  print('====================================================');
  print('📦 画像レビューダッシュボードデータ出力 (Publish Data)');
  print('====================================================');

  final metadataDir = Directory('tools/image_pipeline/metadata');
  final buildWebReviewDir = Directory('build/web/review');
  final webDataDir = Directory('build/web/review/data');
  final webImagesDir = Directory('build/web/review/images');

  if (!webDataDir.existsSync()) webDataDir.createSync(recursive: true);
  if (!webImagesDir.existsSync()) webImagesDir.createSync(recursive: true);

  // web/review/index.html を build/web/review/index.html へコピー
  final sourceHtml = File('web/review/index.html');
  if (sourceHtml.existsSync()) {
    sourceHtml.copySync('${buildWebReviewDir.path}/index.html');
    print('✅ HTMLコピー完了: web/review/index.html -> build/web/review/index.html');
  } else {
    print('Warning: web/review/index.html が見つかりません。');
  }

  if (!metadataDir.existsSync()) {
    print('Error: tools/image_pipeline/metadata ディレクトリが存在しません。');
    exit(1);
  }

  final files = metadataDir.listSync().whereType<File>().where((f) => f.path.endsWith('.json')).toList();
  files.sort((a, b) => a.path.compareTo(b.path));

  final List<Map<String, dynamic>> items = [];
  int imageCopiedCount = 0;

  final searchDirs = [
    'tools/image_pipeline/generated',
    'tools/image_pipeline/approved',
    'assets/images',
  ];

  for (final f in files) {
    try {
      final Map<String, dynamic> data = jsonDecode(f.readAsStringSync());
      final String activityId = data['activity_id'] ?? '';
      if (activityId.isEmpty) continue;

      items.add(data);

      // 画像のコピー処理
      File? sourceImg;
      String matchedExt = '.jpg';

      for (final dirPath in searchDirs) {
        for (final ext in ['.jpg', '.jpeg', '.webp', '.png']) {
          final candidate = File('$dirPath/$activityId$ext');
          if (candidate.existsSync()) {
            sourceImg = candidate;
            matchedExt = ext;
            break;
          }
        }
        if (sourceImg != null) break;
      }

      if (sourceImg != null) {
        final targetPath = '${webImagesDir.path}/$activityId$matchedExt';
        sourceImg.copySync(targetPath);
        imageCopiedCount++;

        // `.webp` の場合は `.jpg` コピーも保持（互換用）
        if (matchedExt == '.webp') {
          sourceImg.copySync('${webImagesDir.path}/$activityId.webp');
        } else if (matchedExt == '.jpg' || matchedExt == '.jpeg') {
          sourceImg.copySync('${webImagesDir.path}/$activityId.jpg');
        }
      }
    } catch (e) {
      print('Warning: ファイル解析スキップ (${f.path}): $e');
    }
  }

  // items.json の保存
  final itemsJsonFile = File('${webDataDir.path}/items.json');
  itemsJsonFile.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(items));

  print('✅ メタデータ出力完了: ${itemsJsonFile.path} (${items.length} 件)');
  print('✅ レビュー用画像同期完了: ${webImagesDir.path} ($imageCopiedCount 件)');
  print('----------------------------------------------------');
  print('これで `build/web/review/` 配下に静的レビューサイト用のアセットが準備されました。');
}
