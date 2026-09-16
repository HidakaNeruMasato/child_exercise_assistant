import 'dart:io';

void main(List<String> args) async {
  print('====================================================');
  print('🚀 GitHub Pages 本番デプロイ (Deploy to gh-pages)');
  print('====================================================');

  final buildWebDir = Directory('build/web');
  if (!buildWebDir.existsSync() || !File('build/web/index.html').existsSync()) {
    print('Error: build/web/ 成果物が存在しません。先に `flutter build web --base-href "/child_exercise_assistant/"` を実行してください。');
    exit(1);
  }

  // 1. リポジトリの origin URL を取得
  final originUrlResult = await Process.run('git', ['remote', 'get-url', 'origin']);
  final originUrl = originUrlResult.stdout.toString().trim();
  if (originUrl.isEmpty) {
    print('Error: git remote origin URL の取得に失敗しました。');
    exit(1);
  }

  // 2. 隔離された一時ディレクトリを作成
  final tempDir = Directory.systemTemp.createTempSync('gh_pages_deploy_');
  print('1. 隔離環境の作成: ${tempDir.path}');

  try {
    // 3. build/web の内容を全コピー
    print('2. build/web の全成果物を展開中...');
    _copyDirectory(buildWebDir, tempDir);

    // .nojekyll ファイルを作成（GitHub Pagesがアンダースコア等のファイルを隠さないようにする）
    File('${tempDir.path}/.nojekyll').writeAsStringSync('');

    // もし誤って .gitignore が含まれていれば削除
    final gitignoreInTemp = File('${tempDir.path}/.gitignore');
    if (gitignoreInTemp.existsSync()) {
      gitignoreInTemp.deleteSync();
    }

    // 4. 一時ディレクトリルートで独立した git リポジトリを初期化してコミット＆プッシュ
    print('3. クリーンな gh-pages ブランチを構築中...');
    await _runInDir(tempDir.path, 'git', ['init']);
    await _runInDir(tempDir.path, 'git', ['checkout', '-b', 'gh-pages']);
    await _runInDir(tempDir.path, 'git', ['add', '-A']);
    await _runInDir(tempDir.path, 'git', ['commit', '-m', 'deploy: update GitHub Pages build (main app + review UI)']);

    print('4. remote origin (gh-pages) へ強制プッシュ中...');
    await _runInDir(tempDir.path, 'git', ['remote', 'add', 'origin', originUrl]);
    await _runInDir(tempDir.path, 'git', ['push', 'origin', 'gh-pages', '--force']);

    print('✅ gh-pages ブランチへの反映完了！');
  } finally {
    // 一時ディレクトリの削除
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  }

  print('----------------------------------------------------');
  print('🎉 本番デプロイ成功！');
  print('  - アプリ本体: https://hidakanerumasato.github.io/child_exercise_assistant/');
  print('  - レビューUI: https://hidakanerumasato.github.io/child_exercise_assistant/review/');
}

Future<void> _runInDir(String workingDir, String executable, List<String> arguments) async {
  final result = await Process.run(executable, arguments, workingDirectory: workingDir);
  if (result.exitCode != 0) {
    print('Command failed in $workingDir: $executable ${arguments.join(' ')}');
    print('Error output:\n${result.stderr}');
    throw Exception('Process failed with exit code ${result.exitCode}');
  }
}

void _copyDirectory(Directory source, Directory destination) {
  for (final entity in source.listSync(recursive: false)) {
    final name = entity.uri.pathSegments.where((s) => s.isNotEmpty).last;
    if (entity is Directory) {
      final newDir = Directory('${destination.path}/$name');
      newDir.createSync(recursive: true);
      _copyDirectory(entity, newDir);
    } else if (entity is File) {
      entity.copySync('${destination.path}/$name');
    }
  }
}
