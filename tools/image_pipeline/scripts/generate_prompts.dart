import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';

void main(List<String> args) async {
  final csvFile = File('assets/data/activities.csv');
  if (!csvFile.existsSync()) {
    print('Error: assets/data/activities.csv が存在しません。');
    exit(1);
  }

  final templateFile = File('tools/image_pipeline/prompts/master_prompt.txt');
  if (!templateFile.existsSync()) {
    print('Error: tools/image_pipeline/prompts/master_prompt.txt が存在しません。');
    exit(1);
  }

  final masterTemplate = templateFile.readAsStringSync();
  final input = csvFile.readAsStringSync(encoding: utf8);
  final List<List<dynamic>> rows = const CsvToListConverter(eol: '\n').convert(input);

  if (rows.length <= 1) {
    print('Error: activities.csv に有効な行がありません。');
    exit(1);
  }

  final promptOutputDir = Directory('tools/image_pipeline/prompts/generated');
  final metadataDir = Directory('tools/image_pipeline/metadata');
  if (!promptOutputDir.existsSync()) promptOutputDir.createSync(recursive: true);
  if (!metadataDir.existsSync()) metadataDir.createSync(recursive: true);

  int generatedCount = 0;
  int missingDataCount = 0;

  for (int i = 1; i < rows.length; i++) {
    final row = rows[i];
    if (row.isEmpty || row[0].toString().trim().isEmpty) continue;

    final String activityId = row[0].toString().trim().replaceAll('"', '');
    final String title = row.length > 1 ? row[1].toString().trim().replaceAll('"', '') : '';
    final String description = row.length > 2 ? row[2].toString().trim().replaceAll('"', '') : '';
    final String minAge = row.length > 3 ? row[3].toString().trim() : '';
    final String maxAge = row.length > 4 ? row[4].toString().trim() : '';
    final String minPart = row.length > 5 ? row[5].toString().trim() : '';
    final String maxPart = row.length > 6 ? row[6].toString().trim() : '';
    final String location = row.length > 8 ? row[8].toString().trim().replaceAll('"', '') : '';
    final String tools = row.length > 9 ? row[9].toString().trim().replaceAll('"', '') : '';
    final String steps = row.length > 17 ? row[17].toString().trim().replaceAll('"', '') : '';
    final String mainAction = description; // description contains core motion

    final List<String> missingFields = [];
    if (title.isEmpty) missingFields.add('title');
    if (description.isEmpty) missingFields.add('description');
    if (steps.isEmpty) missingFields.add('steps');

    final bool isDataMissing = missingFields.isNotEmpty;

    final String participantText = (minPart == maxPart) ? '$minPart child' : '$minPart to $maxPart children';
    final String locationText = location.isEmpty ? 'indoor or outdoor park' : location;
    final String toolsText = (tools.isEmpty || tools == 'なし（道具不要）') ? 'None (no equipment required)' : tools;

    String promptText = masterTemplate
        .replaceAll('{activity_id}', activityId)
        .replaceAll('{title}', title)
        .replaceAll('{description}', description)
        .replaceAll('{min_age}', minAge.isEmpty ? '3' : minAge)
        .replaceAll('{max_age}', maxAge.isEmpty ? '12' : maxAge)
        .replaceAll('{participant_text}', participantText)
        .replaceAll('{location_text}', locationText)
        .replaceAll('{tools_text}', toolsText)
        .replaceAll('{main_action}', mainAction)
        .replaceAll('{steps_text}', steps.replaceAll(';', ' -> '));

    if (isDataMissing) {
      promptText += '\n\n[WARNING: INFORMATION MISSING]\nMissing fields in CSV: ${missingFields.join(', ')}';
    }

    final promptFile = File('${promptOutputDir.path}/${activityId}_prompt.txt');
    promptFile.writeAsStringSync(promptText);

    // Update metadata JSON
    final metaFile = File('${metadataDir.path}/$activityId.json');
    Map<String, dynamic> metadata = {};

    if (metaFile.existsSync()) {
      try {
        metadata = jsonDecode(metaFile.readAsStringSync());
      } catch (_) {}
    }

    final nowStr = DateTime.now().toIso8601String();
    metadata['activity_id'] = activityId;
    metadata['title'] = title;
    metadata['data_status'] = isDataMissing ? 'MISSING_DATA' : 'VALID';
    metadata['missing_fields'] = missingFields;
    if (metadata['status'] == null || metadata['status'] == 'NOT_STARTED') {
      metadata['status'] = isDataMissing ? 'MISSING_DATA' : 'PROMPT_GENERATED';
    }
    metadata['generation_count'] = metadata['generation_count'] ?? 0;
    metadata['repair_count'] = metadata['repair_count'] ?? 0;
    metadata['updated_at'] = nowStr;

    metaFile.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(metadata));

    if (isDataMissing) {
      print('⚠️ $activityId: プロンプト作成 (情報不足: ${missingFields.join(', ')})');
      missingDataCount++;
    } else {
      print('✅ $activityId: プロンプト生成完了 (${activityId}_prompt.txt)');
      generatedCount++;
    }
  }

  print('\n----------------------------------------------------');
  print('プロンプト生成完了サマリー:');
  print('正常生成: $generatedCount 件');
  print('情報不足: $missingDataCount 件');
  print('出力先: tools/image_pipeline/prompts/generated/');
  print('----------------------------------------------------');
}
