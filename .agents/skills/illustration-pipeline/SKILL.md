---
name: illustration-pipeline
description: >-
  「こどもと、なにしよう。」アプリ向けイラスト制作・修正・アセット反映・Webデプロイの一連のパイプライン手順書。
  基準画像スタイル維持、activities.csv更新、Flutter Webビルド、gh-pagesデプロイまでをカバーします。
---

# イラスト制作＆アプリ反映パイプライン（制作ライン）

本ドキュメントは、「こどもと、なにしよう。」アプリの遊び詳細ページ用イラストを継続的に制作し、アプリへ即座に反映・デプロイするための一連のワークフロー規定です。

---

## 1. イラスト生成ガイドライン

### 【参照・統一性】
- 必ず基準画像（`media_1788361169150.jpg` または `assets/images/activity_newspaper_catch.jpg` 等の基準画像）を `generate_image` の `ImagePaths` に含める。
- 「同じイラストレーターが描いた同一シリーズ」に見えることを最優先する。

### 【キャラクター設計】
- 基本構成: **男の子1人（茶髪くるくるショート）＋ 女の子1人（茶髪ロング）**
- 表情: 健康的で明るく楽しそうな笑顔
- 体型: 自然な子どもの体型（過度に幼かったり大人っぽくしない）

### 【スタイル＆構図】
- **線画**: 柔らかく太めの黒い輪郭線（手描き絵本・教育教材風）
- **塗り**: パステルカラー中心の明るくフラットな塗り（グラデーションや3D質感は絶対不可）
- **構図**: アスペクト比 `16:9`。子どもの全身と遊びの動き・道具が一番分かりやすい構図。
- **背景**: 白地メインの極めてシンプルな背景（簡単な床線や最低限の目印コーンなど）
- **【絶対不可（禁止事項）】**: 文字、数字、タイトル、吹き出し、説明文、ロゴ、ウォーターマークの描画

### 【動作の描写】
- `activities.csv` の「遊ぶ手順」および「主な動作」を熟読し、**「子どもが実際にその遊びを行っている最高の瞬間」**を描く。

---

## 2. アプリ反映＆デプロイ標準手順

イラストの制作・ユーザーレビューが完了した後は、以下のステップでアプリに反映します。

### ステップ1: 画像ファイルの配置
生成した画像を `d:\myproject\child_exercise_assistant\assets\images\` ディレクトリへコピー配置する。
- 命名規則: `activity_<遊びのスラグ名>.jpg` （例: `activity_balloon_relay.jpg`）

### ステップ2: activities.csv の更新
`d:\myproject\child_exercise_assistant\assets\data\activities.csv` の対象アクティビティ行の `画像URL` 列を更新する。
- 例: `assets/images/activity_balloon_relay.jpg`

### ステップ3: ソースコードのコミット & main プッシュ
```powershell
git add assets/data/activities.csv assets/images/
git commit -m "Apply custom generated 2D illustration for <遊び名> (<ID>)"
git push origin main
```

### ステップ4: Flutter Web ビルド
```powershell
flutter build web --base-href "/child_exercise_assistant/"
```

### ステップ5: gh-pages ブランチへのデプロイ
```powershell
git worktree add d:\myproject\gh-pages-temp origin/gh-pages
Get-ChildItem -Path d:\myproject\gh-pages-temp -Exclude .git | Remove-Item -Recurse -Force
Copy-Item -Recurse -Force build\web\* d:\myproject\gh-pages-temp\
Set-Location d:\myproject\gh-pages-temp
git add -A
git commit -m "Deploy custom generated 2D illustrations"
git push origin HEAD:gh-pages
Set-Location d:\myproject\child_exercise_assistant
git worktree remove d:\myproject\gh-pages-temp --force
```

---

## 3. 次回以降の自動適用
次回以降のイラスト制作・更新依頼を受けた際は、自動的に上記のガイドラインとデプロイ手順に沿って一貫した作業を実施すること。
