# 🎨 「こどもと、なにしよう。」画像制作パイプライン (tools/image_pipeline)

子どもの運動・遊びイラストのAI大量生成における人体破綻（腕が3本、脚が3本、人物の融着等）や構図不整合を防ぎ、品質確保からFlutterアプリ（`assets/images/{activity_id}.webp`）への登録までを一元管理する仕組みです。

---

## 📁 ディレクトリ構造

```text
tools/
  image_pipeline/
    README.md                  # 本仕様書
    config/
      image_style.yaml         # 画風・パステルカラー・手描き線・人体制約の規定
      quality_rules.yaml       # 17項目の品質検査ルールと対応アクション
    prompts/
      master_prompt.txt        # 固定マスタープロンプト（人体制限・画風固定）
      repair_prompt.txt        # 局所修正用プロンプト（問題箇所のみ修正）
      regenerate_prompt.txt    # 元データからの全再生成用プロンプト
      generated/               # CSVから自動出力された act_XXX_prompt.txt
    generated/                 # 生成直後の画像保管庫 (act_001, act_002...)
    inspection/                # AI検査の構造化JSONログ
    approved/                  # 人間が承認した WebP 画像の一時保管庫
    rejected/                  # 却下された画像アーカイブ
    metadata/                  # 各アクティビティのステータス・修正履歴のJSON
    review/                    # 人間確認用のブラウザUI (review_server.dart)
    scripts/
      image_pipeline.dart      # 統合CLI (status, prompts, generate, inspect, review, approve, sync)
      generate_prompts.dart    # CSV → プロンプト一括生成
      inspect_images.dart      # 17項目の画像品質AI検査
      approve_image.dart       # 画像承認
      sync_approved_images.dart# approved/ → assets/images/*.webp 安全同期
      review_server.dart       # レビュー画面配信サーバー (localhost:8080)
```

---

## 🔄 制作ワークフロー（ステータス遷移）

1. **`NOT_STARTED` / `MISSING_DATA`**: 初期状態
2. **`PROMPT_GENERATED`**: プロンプト自動生成完了
3. **`GENERATED`**: AI画像生成完了
4. **`INSPECTING`**: AI品質検査中
5. **`REPAIR_REQUIRED` / `REGENERATE_REQUIRED`**: 検査での問題指摘（自動判定）
6. **`HUMAN_REVIEW`**: AI検査通過・人間による最終確認待ち
7. **`APPROVED`**: 人間が承認（`approved/act_XXX.webp` に保存）
8. **`REGISTERED`**: アプリへ登録完了（`assets/images/act_XXX.webp`）

---

## 🚀 CLI コマンドの使い方

### 1. 進捗状況の確認
```bash
dart run tools/image_pipeline/scripts/image_pipeline.dart status
```

### 2. CSVからのプロンプト自動生成
```bash
dart run tools/image_pipeline/scripts/image_pipeline.dart prompts
```

### 3. 生成画像のAI品質検査
```bash
dart run tools/image_pipeline/scripts/image_pipeline.dart inspect
```

### 4. GitHub Pages 用静的レビュー画面用データの出力
```bash
dart run tools/image_pipeline/scripts/image_pipeline.dart publish
```
`tools/image_pipeline/metadata/*.json` および最新画像を `web/review/` 配下に同期出力します。Flutter Web ビルド・gh-pages デプロイ時に自動的に同梱されます。

### 5. 人間確認レビュー画面
- **GitHub Pages版（常時アクセス可・サーバー不要）**:
  `https://hidakanerumasato.github.io/child_exercise_assistant/review/`
  画面右上の「⚙️ GitHub設定」から GitHub Personal Access Token (PAT) を設定することで、ブラウザ上からワンクリックで GitHub リポジトリへ承認・修正・再生成のコミットを送信できます。

- **ローカルサーバー版（任意）**:
```bash
dart run tools/image_pipeline/scripts/image_pipeline.dart review
```
ブラウザで `http://localhost:8080` を開いて動作確認も可能です。

### 6. 個別承認（コマンドライン操作）
```bash
dart run tools/image_pipeline/scripts/image_pipeline.dart approve act_002
```

### 7. 承認済み画像のアプリ登録・同期
```bash
dart run tools/image_pipeline/scripts/image_pipeline.dart sync
```
※既存アセットの上書き保護機能あり（上書きする場合は `--overwrite` を指定）。

---

## 🔍 AI品質検査の判定項目 (17項目)

### 人体チェック (8項目)
1. 腕が左右2本か
2. 脚が左右2本か
3. 手の数が不自然でないか
4. 指が大きく崩れていないか
5. 腕と肩が自然につながっているか
6. 脚と身体が自然につながっているか
7. 顔が大きく崩れていないか
8. 人物同士が融合していないか

### 構図チェック (5項目)
9. 指定人数と一致しているか
10. 人物が途中で切れていないか
11. 遊びの動作が分かるか
12. 指定した道具が正しく描かれているか
13. 危険な動作になっていないか

### デザインチェック (4項目)
14. 現在のシリーズの画風と大きく違わないか
15. 背景が適切か
16. 文字が勝手に入っていないか
17. ロゴや透かしが入っていないか

---

## 🛡️ 既存アプリへの安全性・影響
- アプリ本体コード（`lib/`）や `activities.csv`、`bin/check_image_status.dart` を一切壊しません。
- 制作途中の画像は `assets/images/` に直接配置されず、人間確認で `APPROVE` された画像のみが `sync` により `assets/images/{activity_id}.webp` へ同期されます。
