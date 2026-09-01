# Firebase Analytics & Firebase Crashlytics 実装ドキュメント

本ドキュメントは、「こどもと、なにしよう。」における **Firebase Analytics** および **Firebase Crashlytics** の実装仕様、個人情報保護ガイドライン、デバッグ・動作確認手順を記録したものです。

---

## 🎯 1. 概要とアーキテクチャ

Analytics と Crashlytics のイベント発火およびエラー収集は、コンポーネント内に文字列で直接記述せず、以下のラッパーサービス層を通じて一元管理しています。

- **`lib/services/analytics_service.dart` (`AnalyticsService`)**
  - アナリティクスイベント名およびパラメータ名のカプセル化
  - イベントログ送信 (`logViewHome`, `logSearchRecommendations`, `logViewActivity`, `logCompleteActivity`, `logSubmitFeedback` 等)
- **`lib/services/crashlytics_service.dart` (`CrashlyticsService`)**
  - 未処理例外 (`FlutterError.onError`, `PlatformDispatcher.instance.onError`) のキャッチと Crashlytics 送信
  - Flutter Web 環境 (`kIsWeb == true`) 時の動作安全ガード (No-op)
  - Breadcrumb (操作ログ) の記録および非致命的エラー (`recordError`) のトラッキング

---

## 📊 2. Analytics イベント & パラメータ定義一覧

| イベント名 | 送信タイミング | 送信パラメータ | 重要イベント |
| :--- | :--- | :--- | :---: |
| `view_home` | ホーム画面表示時 | なし | |
| `open_condition` | 条件変更モーダル表示時 | なし | |
| `change_condition` | 条件を変更し決定した時 | `age`, `participants`, `location`, `duration`, `mood`, `season`, `weather` | |
| `search_recommendations` | 「この条件でおすすめを検索」タップ時 | `age`, `participants`, `location`, `duration`, `mood`, `season`, `weather` | ★ |
| `view_recommendations` | おすすめ一覧画面表示時 | `recommendation_count` | |
| `view_activity` | 遊び詳細画面表示時 | `activity_id`, `activity_category` | ★ |
| `favorite_activity` | お気に入り追加/解除時 | `activity_id`, `action` (`add` / `remove`) | |
| `complete_activity` | 「今日あそんだ！」記録完了時 | `activity_id`, `participants` (※人数数値) | ★ |
| `submit_feedback` | フィードバック送信時 | `feedback_type`, `activity_id` (任意) | |

*※ `app_open` イベントは Firebase Analytics の自動計測に任せているため、手動の二重計測は行いません。*

---

## 🔒 3. 個人情報保護方針 (Privacy Rules)

Analytics および Crashlytics には、プライバシー保護および各種ガイドライン遵守のため、以下の個人情報は**一切記録されません**。

- ❌ 子どもの氏名・保護者の氏名
- ❌ メールアドレス・電話番号・住所
- ❌ GPSの正確な位置情報
- ❌ 生年月日・健康情報・学校名
- ❌ **フィードバック自由記述本文** (※`submit_feedback` では投稿事実と `feedback_type`, `activity_id` のみ送信)

---

## 🛠 4. 動作確認手順

### A. Analytics DebugView での確認方法 (Debugビルド)

1. **Android の場合**:
   ```bash
   adb shell setprop debug.firebase.analytics.app package.name.child_exercise_assistant
   ```
2. **iOS の場合**:
   Xcode の Scheme 編集にて `Arguments Passed On Launch` に以下を追加:
   ```text
   -FIRDebugEnabled
   ```
3. **Firebase Console での確認**:
   - [Firebase Console](https://console.firebase.google.com/) ➔ **Analytics** ➔ **DebugView** にアクセス。
   - アプリ上で「検索」「遊び閲覧」「完了」等の操作を行い、イベントおよびパラメータがリアルタイムに表示されることを確認。

### B. Crashlytics の動作・テストクラッシュ確認方法

1. **テストクラッシュの実行**:
   `CrashlyticsService().testCrash()` を実行（デバッグ用）。
2. **Firebase Console での確認**:
   - [Firebase Console](https://console.firebase.google.com/) ➔ **Release & Monitor** ➔ **Crashlytics** にアクセス。
   - 数分以内にスタックトレースおよびクラッシュ直前の Breadcrumb ログがレポートされていることを確認。
