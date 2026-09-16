import 'dart:convert';
import 'dart:io';

void main(List<String> args) async {
  final int port = 8080;
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  print('====================================================');
  print('🎨 「こどもと、なにしよう。」画像確認レビューダッシュボード');
  print('====================================================');
  print('Server running on: http://localhost:$port');
  print('ブラウザで上記URLを開き、画像の個別検査・承認・修正操作を行ってください。');
  print('終了するには Ctrl+C を押してください。\n');

  await for (final HttpRequest request in server) {
    try {
      final path = request.uri.path;

      if (path == '/' || path == '/index.html') {
        _handleIndexHtml(request);
      } else if (path == '/api/items') {
        _handleGetItems(request);
      } else if (path == '/api/action') {
        await _handlePostAction(request);
      } else if (path.startsWith('/image/')) {
        _handleServeImage(request, path.replaceFirst('/image/', ''));
      } else {
        request.response
          ..statusCode = HttpStatus.notFound
          ..write('Not Found')
          ..close();
      }
    } catch (e) {
      request.response
        ..statusCode = HttpStatus.internalServerError
        ..write('Error: $e')
        ..close();
    }
  }
}

void _handleGetItems(HttpRequest request) {
  final metadataDir = Directory('tools/image_pipeline/metadata');
  final List<Map<String, dynamic>> items = [];

  if (metadataDir.existsSync()) {
    final files = metadataDir.listSync().whereType<File>().where((f) => f.path.endsWith('.json'));
    for (final f in files) {
      try {
        final Map<String, dynamic> data = jsonDecode(f.readAsStringSync());
        items.add(data);
      } catch (_) {}
    }
  }

  items.sort((a, b) => (a['activity_id'] ?? '').compareTo(b['activity_id'] ?? ''));

  request.response
    ..headers.contentType = ContentType.json
    ..write(jsonEncode(items))
    ..close();
}

Future<void> _handlePostAction(HttpRequest request) async {
  if (request.method != 'POST') {
    request.response.statusCode = HttpStatus.methodNotAllowed;
    request.response.close();
    return;
  }

  final body = await utf8.decoder.bind(request).join();
  final data = jsonDecode(body) as Map<String, dynamic>;

  final String activityId = data['activity_id'] ?? '';
  final String action = data['action'] ?? ''; // APPROVE, REPAIR, REGENERATE, REJECT

  if (activityId.isEmpty || action.isEmpty) {
    request.response.statusCode = HttpStatus.badRequest;
    request.response.write('Invalid parameters');
    request.response.close();
    return;
  }

  final metaFile = File('tools/image_pipeline/metadata/$activityId.json');
  if (!metaFile.existsSync()) {
    request.response.statusCode = HttpStatus.notFound;
    request.response.write('Metadata not found');
    request.response.close();
    return;
  }

  final Map<String, dynamic> metadata = jsonDecode(metaFile.readAsStringSync());
  final nowStr = DateTime.now().toIso8601String();

  if (action == 'APPROVE') {
    metadata['status'] = 'APPROVED';
    metadata['approved_at'] = nowStr;

    // 画像を approved/ ディレクトリにコピー
    final generatedDir = Directory('tools/image_pipeline/generated');
    final approvedDir = Directory('tools/image_pipeline/approved');
    if (!approvedDir.existsSync()) approvedDir.createSync(recursive: true);

    File? src;
    for (final ext in ['.webp', '.jpg', '.jpeg', '.png']) {
      final f = File('${generatedDir.path}/$activityId$ext');
      if (f.existsSync()) {
        src = f;
        break;
      }
    }

    if (src != null) {
      src.copySync('${approvedDir.path}/$activityId.webp');
    }
  } else if (action == 'REPAIR') {
    metadata['status'] = 'REPAIR_REQUIRED';
    metadata['repair_count'] = (metadata['repair_count'] ?? 0) + 1;
  } else if (action == 'REGENERATE') {
    metadata['status'] = 'REGENERATE_REQUIRED';
    metadata['generation_count'] = (metadata['generation_count'] ?? 0) + 1;
  } else if (action == 'REJECT') {
    metadata['status'] = 'REJECTED';
  }

  metadata['updated_at'] = nowStr;
  metaFile.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(metadata));

  request.response
    ..headers.contentType = ContentType.json
    ..write(jsonEncode({'success': true, 'activity_id': activityId, 'status': metadata['status']}))
    ..close();
}

void _handleServeImage(HttpRequest request, String filename) {
  final activityId = filename.substring(0, filename.lastIndexOf('.'));
  File? imgFile;

  // 最新生成画像 (generated) -> 承認済み画像 (approved) -> アプリ既存アセット (assets/images) の順で優先検索
  final dirs = [
    'tools/image_pipeline/generated',
    'tools/image_pipeline/approved',
    'assets/images',
  ];

  for (final d in dirs) {
    for (final ext in ['.jpg', '.jpeg', '.png', '.webp']) {
      final candidate = File('$d/$activityId$ext');
      if (candidate.existsSync()) {
        imgFile = candidate;
        break;
      }
    }
    if (imgFile != null) break;
  }

  if (imgFile == null) {
    request.response.statusCode = HttpStatus.notFound;
    request.response.close();
    return;
  }

  final bytes = imgFile.readAsBytesSync();
  final pathLower = imgFile.path.toLowerCase();
  String mime = 'image/webp';
  if (pathLower.endsWith('.jpg') || pathLower.endsWith('.jpeg')) mime = 'image/jpeg';
  if (pathLower.endsWith('.png')) mime = 'image/png';

  request.response
    ..headers.contentType = ContentType.parse(mime)
    ..headers.set('Cache-Control', 'no-cache, no-store, must-revalidate')
    ..headers.set('Pragma', 'no-cache')
    ..headers.set('Expires', '0')
    ..add(bytes)
    ..close();
}

void _handleIndexHtml(HttpRequest request) {
  const html = '''
<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8">
  <title>「こどもと、なにしよう。」画像制作レビューダッシュボード</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #f4f6f8; margin: 0; padding: 20px; color: #333; }
    h1 { font-size: 24px; color: #1a252c; margin-bottom: 20px; display: flex; align-items: center; gap: 10px; }
    .filters { display: flex; gap: 10px; margin-bottom: 20px; flex-wrap: wrap; background: #fff; padding: 15px; border-radius: 8px; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }
    .filter-btn { padding: 8px 16px; border: 1px solid #ddd; background: #fff; border-radius: 20px; cursor: pointer; font-size: 13px; font-weight: 600; transition: all 0.2s; }
    .filter-btn.active { background: #007bff; color: #fff; border-color: #007bff; }
    .grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(320px, 1fr)); gap: 20px; }
    .card { background: #fff; border-radius: 12px; overflow: hidden; box-shadow: 0 2px 8px rgba(0,0,0,0.08); display: flex; flex-direction: column; }
    .card-img-container { width: 100%; height: 180px; background: #eee; position: relative; display: flex; align-items: center; justify-content: center; cursor: pointer; }
    .card-img-container:hover::after { content: "🔍 クリックで拡大表示"; position: absolute; bottom: 0; left: 0; right: 0; background: rgba(0,0,0,0.7); color: #fff; text-align: center; padding: 4px; font-size: 11px; }
    .card-img-container img { width: 100%; height: 100%; object-fit: cover; }
    .badge { position: absolute; top: 10px; right: 10px; padding: 4px 10px; border-radius: 12px; font-size: 11px; font-weight: bold; color: #fff; text-transform: uppercase; z-index: 2; }
    .badge-APPROVED, .badge-REGISTERED { background: #28a745; }
    .badge-HUMAN_REVIEW { background: #17a2b8; }
    .badge-REPAIR_REQUIRED { background: #ffc107; color: #000; }
    .badge-REGENERATE_REQUIRED, .badge-REJECTED { background: #dc3545; }
    .badge-PROMPT_GENERATED, .badge-NOT_STARTED { background: #6c757d; }
    .card-body { padding: 15px; flex: 1; display: flex; flex-direction: column; }
    .card-title { font-size: 16px; font-weight: bold; margin: 0 0 5px 0; color: #222; }
    .card-sub { font-size: 12px; color: #666; margin-bottom: 10px; }
    .inspection-box { background: #f8f9fa; border-left: 4px solid #17a2b8; padding: 10px; font-size: 12px; margin-bottom: 12px; border-radius: 4px; }
    .inspection-box.FAIL { border-left-color: #dc3545; }
    .inspection-box.WARNING { border-left-color: #ffc107; }
    .actions { display: flex; gap: 8px; margin-top: auto; }
    .btn { flex: 1; padding: 8px; border: none; border-radius: 6px; font-size: 12px; font-weight: bold; cursor: pointer; transition: opacity 0.2s; }
    .btn:hover { opacity: 0.85; }
    .btn-approve { background: #28a745; color: #fff; }
    .btn-repair { background: #ffc107; color: #000; }
    .btn-regenerate { background: #dc3545; color: #fff; }

    /* Modal / Lightbox Styles */
    .modal-overlay { position: fixed; top: 0; left: 0; width: 100vw; height: 100vh; background: rgba(0,0,0,0.85); display: none; align-items: center; justify-content: center; z-index: 1000; padding: 20px; box-sizing: border-box; }
    .modal-overlay.open { display: flex; }
    .modal-content { background: #fff; border-radius: 12px; max-width: 90vw; max-height: 90vh; overflow: hidden; display: flex; flex-direction: column; box-shadow: 0 10px 30px rgba(0,0,0,0.5); position: relative; }
    .modal-header { padding: 12px 20px; background: #1a252c; color: #fff; display: flex; justify-content: space-between; align-items: center; }
    .modal-header h2 { margin: 0; font-size: 18px; }
    .modal-close { font-size: 24px; cursor: pointer; color: #aaa; border: none; background: none; }
    .modal-close:hover { color: #fff; }
    .modal-body { overflow: auto; text-align: center; background: #222; padding: 10px; flex: 1; display: flex; align-items: center; justify-content: center; }
    .modal-body img { max-width: 85vw; max-height: 70vh; object-fit: contain; border-radius: 4px; box-shadow: 0 4px 12px rgba(0,0,0,0.3); }
    .modal-footer { padding: 15px; background: #f8f9fa; display: flex; gap: 10px; justify-content: flex-end; }
  </style>
</head>
<body>
  <h1>🎨 「こどもと、なにしよう。」画像制作品質レビュー</h1>
  <div class="filters">
    <button class="filter-btn active" onclick="filterStatus('ALL')">すべて (<span id="cnt-ALL">0</span>)</button>
    <button class="filter-btn" onclick="filterStatus('HUMAN_REVIEW')">人間確認待ち (<span id="cnt-HUMAN_REVIEW">0</span>)</button>
    <button class="filter-btn" onclick="filterStatus('REPAIR_REQUIRED')">修正要 (<span id="cnt-REPAIR_REQUIRED">0</span>)</button>
    <button class="filter-btn" onclick="filterStatus('REGENERATE_REQUIRED')">再生成要 (<span id="cnt-REGENERATE_REQUIRED">0</span>)</button>
    <button class="filter-btn" onclick="filterStatus('APPROVED')">承認済み (<span id="cnt-APPROVED">0</span>)</button>
    <button class="filter-btn" onclick="filterStatus('REGISTERED')">アプリ登録済み (<span id="cnt-REGISTERED">0</span>)</button>
  </div>
  <div class="grid" id="card-grid"></div>

  <!-- Zoom Lightbox Modal -->
  <div class="modal-overlay" id="image-modal" onclick="closeModalOnOverlay(event)">
    <div class="modal-content">
      <div class="modal-header">
        <h2 id="modal-title">画像拡大表示</h2>
        <button class="modal-close" onclick="closeModal()">&times;</button>
      </div>
      <div class="modal-body">
        <img id="modal-img" src="" alt="拡大画像">
      </div>
      <div class="modal-footer" id="modal-actions"></div>
    </div>
  </div>

  <script>
    let allItems = [];
    let currentFilter = 'ALL';

    async function loadItems() {
      const res = await fetch('/api/items');
      allItems = await res.json();
      updateCounts();
      renderGrid();
    }

    function updateCounts() {
      const counts = { ALL: allItems.length, HUMAN_REVIEW: 0, REPAIR_REQUIRED: 0, REGENERATE_REQUIRED: 0, APPROVED: 0, REGISTERED: 0 };
      allItems.forEach(item => {
        const st = item.status || 'NOT_STARTED';
        if (counts[st] !== undefined) counts[st]++;
      });
      for (const k in counts) {
        const el = document.getElementById('cnt-' + k);
        if (el) el.innerText = counts[k];
      }
    }

    function filterStatus(st) {
      currentFilter = st;
      document.querySelectorAll('.filter-btn').forEach(b => b.classList.remove('active'));
      event.target.classList.add('active');
      renderGrid();
    }

    function renderGrid() {
      const grid = document.getElementById('card-grid');
      grid.innerHTML = '';

      const filtered = allItems.filter(item => {
        if (currentFilter === 'ALL') return true;
        return (item.status || 'NOT_STARTED') === currentFilter;
      });

      filtered.forEach(item => {
        const id = item.activity_id;
        const title = item.title || '無題';
        const status = item.status || 'NOT_STARTED';
        const insp = item.inspection || {};
        const actionRec = insp.recommended_action || 'なし';
        const probs = (insp.problems || []).join('; ') || '特記事項なし';

        const card = document.createElement('div');
        card.className = 'card';
        const ts = Date.now();
        card.innerHTML = `
          <div class="card-img-container" onclick="openModal('\${id}', '\${title}')">
            <img src="/image/\${id}.jpg?t=\${ts}" onerror="this.src='/image/\${id}.webp?t=\${ts}'; this.onerror=function(){this.style.display='none';}" alt="\${title}">
            <div class="badge badge-\${status}">\${status}</div>
          </div>
          <div class="card-body">
            <div class="card-title">\${id} \${title}</div>
            <div class="card-sub">修正回数: \${item.repair_count || 0} / 生成回数: \${item.generation_count || 0}</div>
            <div class="inspection-box \${insp.status || 'PASS'}">
              <strong>AI判定: \${insp.status || '未検査'} (推奨: \${actionRec})</strong><br>
              指摘: \${probs}
            </div>
            <div class="actions">
              <button class="btn btn-approve" onclick="doAction('\${id}', 'APPROVE')">承認 (APPROVE)</button>
              <button class="btn btn-repair" onclick="doAction('\${id}', 'REPAIR')">修正 (REPAIR)</button>
              <button class="btn btn-regenerate" onclick="doAction('\${id}', 'REGENERATE')">再生成 (REGENERATE)</button>
            </div>
          </div>
        `;
        grid.appendChild(card);
      });
    }

    function openModal(id, title) {
      const ts = Date.now();
      document.getElementById('modal-title').innerText = id + ' ' + title + ' (拡大表示)';
      const modalImg = document.getElementById('modal-img');
      modalImg.src = '/image/' + id + '.jpg?t=' + ts;
      modalImg.onerror = function() { modalImg.src = '/image/' + id + '.webp?t=' + ts; };

      const footer = document.getElementById('modal-actions');
      footer.innerHTML = `
        <button class="btn btn-approve" onclick="doAction('\${id}', 'APPROVE'); closeModal();">承認 (APPROVE)</button>
        <button class="btn btn-repair" onclick="doAction('\${id}', 'REPAIR'); closeModal();">修正 (REPAIR)</button>
        <button class="btn btn-regenerate" onclick="doAction('\${id}', 'REGENERATE'); closeModal();">再生成 (REGENERATE)</button>
      `;

      document.getElementById('image-modal').classList.add('open');
    }

    function closeModal() {
      document.getElementById('image-modal').classList.remove('open');
    }

    function closeModalOnOverlay(e) {
      if (e.target.id === 'image-modal') {
        closeModal();
      }
    }

    document.addEventListener('keydown', function(e) {
      if (e.key === 'Escape') closeModal();
    });

    async function doAction(activityId, action) {
      const res = await fetch('/api/action', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ activity_id: activityId, action: action })
      });
      if (res.ok) {
        await loadItems();
      }
    }

    loadItems();
  </script>
</body>
</html>
''';

  request.response
    ..headers.contentType = ContentType.html
    ..write(html)
    ..close();
}
