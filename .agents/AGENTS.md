# 「こどもと、なにしよう。」開発・イラスト制作エージェント規定 (AGENTS.md)

本プロジェクトにおけるイラスト制作およびアプリ反映作業では、常に以下の「イラスト制作ライン（ワークフロー）」を厳格に順守してください。

---

## 1. イラスト制作・品質規約
- **基準画像の一貫性**: `media_1788361169150.jpg` または同シリーズの基準画像を必ず参照元にして生成する。
- **画風統一ルール**:
  - キャラクター（男の子: 茶髪くるくる、女の子: 茶髪ロング）
  - 線画: 太く柔らかい黒輪郭線（手描き絵本・教育教材風）
  - 塗り: フラットで明るいパステルカラー（過度の立体感・陰影・グラデーションはNG）
  - 背景: 白基調で極めてシンプルな最低限の背景
  - アスペクト比: `16:9`
  - 禁止要素: 文字、タイトル、数字、吹き出し、説明文、ロゴ、ウォーターマーク
- **動作優先**: `activities.csv` の「遊ぶ手順」「主な動作」に厳密に従い、子どもがその遊びを実際に行っている瞬間を描く。

---

## 2. アプリ反映・デプロイライン
1. 生成画像を `assets/images/activity_<slug>.jpg` に保存
2. `assets/data/activities.csv` の「画像URL」列をアセットパスに更新
3. `git add` & `git commit` & `git push origin main`
4. `flutter build web --base-href "/child_exercise_assistant/"`
5. `build/web` を `gh-pages` ブランチにプッシュして本番反映完了

---

詳細なプロンプト設計や各ステップのコマンド仕様は、[.agents/skills/illustration-pipeline/SKILL.md](file:///d:/myproject/child_exercise_assistant/.agents/skills/illustration-pipeline/SKILL.md) を参照すること。
