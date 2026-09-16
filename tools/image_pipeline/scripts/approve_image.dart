import 'dart:convert';
import 'dart:io';

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart run tools/image_pipeline/scripts/approve_image.dart <activity_id>');
    print('Example: dart run tools/image_pipeline/scripts/approve_image.dart act_002');
    exit(1);
  }

  final String activityId = args[0].trim();

  final generatedDir = Directory('tools/image_pipeline/generated');
  final approvedDir = Directory('tools/image_pipeline/approved');
  final metadataDir = Directory('tools/image_pipeline/metadata');

  if (!approvedDir.existsSync()) approvedDir.createSync(recursive: true);

  final metaFile = File('${metadataDir.path}/$activityId.json');
  if (!metaFile.existsSync()) {
    print('Error: メタデータファイル ${metaFile.path} が存在しません。');
    exit(1);
  }

  Map<String, dynamic> metadata = jsonDecode(metaFile.readAsStringSync());

  // 生成画像を探す
  File? sourceImg;
  final possibleExts = ['.webp', '.jpg', '.jpeg', '.png'];
  for (final ext in possibleExts) {
    final candidate = File('${generatedDir.path}/$activityId$ext');
    if (candidate.existsSync()) {
      sourceImg = candidate;
      break;
    }
  }

  // 既存承認画像、または現在地からの検索
  if (sourceImg == null) {
    final candidateApproved = File('${approvedDir.path}/$activityId.webp');
    if (candidateApproved.existsSync()) {
      sourceImg = candidateApproved;
    }
  }

  if (sourceImg == null) {
    print('Error: $activityId の承認元画像ファイルが tools/image_pipeline/generated/ 内に見つかりません。');
    exit(1);
  }

  // approved/ 配下にコピー (.webpとして保存)
  final destFile = File('${approvedDir.path}/$activityId.webp');
  sourceImg.copySync(destFile.path);

  metadata['status'] = 'APPROVED';
  metadata['approved_at'] = DateTime.now().toIso8601String();
  metadata['approved_image_path'] = destFile.path;
  metadata['updated_at'] = DateTime.now().toIso8601String();

  metaFile.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(metadata));

  print('====================================================');
  print('🎉 $activityId を正常に「承認 (APPROVED)」しました！');
  print('  ・承認画像: ${destFile.path}');
  print('  ・ステータス: APPROVED');
  print('  ・次のステップ: sync コマンドで assets/images/ へ登録してください');
  print('====================================================');
}
