import 'dart:io';
import 'package:csv/csv.dart';

void main() {
  final file = File('assets/data/activities.csv');
  if (!file.existsSync()) {
    print('Error: activities.csv not found');
    exit(1);
  }

  final content = file.readAsStringSync();
  final cleanContent = content.startsWith('\uFEFF') ? content.substring(1) : content;
  final rows = const CsvToListConverter().convert(cleanContent);

  print('Original rows count: ${rows.length}');

  final List<List<dynamic>> cleanedRows = [];
  final Set<String> seenIds = {};

  // Header row
  if (rows.isNotEmpty) {
    final header = rows[0].map((e) => e.toString().trim().replaceAll('"', '')).toList();
    if (header.length > 22) {
      cleanedRows.add(header.sublist(0, 22));
    } else {
      cleanedRows.add(header);
    }
  }

  for (int i = 1; i < rows.length; i++) {
    final row = rows[i];
    if (row.isEmpty) continue;
    final id = row[0].toString().trim().replaceAll('"', '');
    if (!id.startsWith('act_')) continue;
    if (seenIds.contains(id)) continue;
    seenIds.add(id);

    final List<dynamic> cleanRow = [];
    for (int j = 0; j < row.length; j++) {
      String val = row[j].toString().trim().replaceAll('\r', '').replaceAll('\n', ' ');
      if (val.startsWith('"') && val.endsWith('"') && val.length >= 2) {
        val = val.substring(1, val.length - 1).trim();
      }
      cleanRow.add(val);
    }

    while (cleanRow.length < 22) {
      cleanRow.add('');
    }

    cleanRow[21] = 'assets/images/$id.webp';

    cleanedRows.add(cleanRow.sublist(0, 22));
  }

  // Sort rows 1..N by ID
  final header = cleanedRows.removeAt(0);
  cleanedRows.sort((a, b) => a[0].toString().compareTo(b[0].toString()));
  cleanedRows.insert(0, header);

  print('Deduplicated & sorted rows count: ${cleanedRows.length - 1}');

  final csvOutput = '\uFEFF' + const ListToCsvConverter().convert(cleanedRows);
  file.writeAsStringSync(csvOutput);
  print('Successfully saved clean activities.csv with exactly ${cleanedRows.length - 1} activities.');
}
