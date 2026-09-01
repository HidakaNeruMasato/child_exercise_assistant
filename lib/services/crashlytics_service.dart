import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Firebase Crashlytics 一元管理サービス (Web安全ガード付き)
class CrashlyticsService {
  static Future<void> initialize() async {
    if (kIsWeb) {
      if (kDebugMode) {
        debugPrint('[Crashlytics] Skipping initial setup for Web platform');
      }
      return;
    }

    try {
      // Flutterで補獲されたエラーをCrashlyticsに自動送信
      FlutterError.onError = (errorDetails) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
      };

      // 非同期処理などで補獲されなかったプラットフォーム例外を自動送信
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };

      if (kDebugMode) {
        // デバッグビルド時にも確認できるよう無効化せず明示設定
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
        debugPrint('[Crashlytics] Initialized successfully');
      }
    } catch (e) {
      debugPrint('[Crashlytics Note] Setup exception: $e');
    }
  }

  /// 非致命的エラー・Catchブロックされた例外を手動記録
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    dynamic reason,
    bool fatal = false,
  }) async {
    if (kIsWeb) return;
    try {
      await FirebaseCrashlytics.instance.recordError(
        exception,
        stack,
        reason: reason,
        fatal: fatal,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Crashlytics Warning] Failed to record error: $e');
      }
    }
  }

  /// パンくずリスト（Breadcrumb）操作ログを記録
  Future<void> logBreadcrumb(String message) async {
    if (kIsWeb) return;
    try {
      await FirebaseCrashlytics.instance.log(message);
    } catch (_) {}
  }

  /// テスト用強制クラッシュを発生させる関数（※本番ビルドには含めないデバッグ専用）
  void testCrash() {
    if (kIsWeb) {
      throw Exception('[Test Crash] Web test crash exception');
    }
    FirebaseCrashlytics.instance.crash();
  }
}

/// CrashlyticsService Riverpod Provider
final crashlyticsServiceProvider = Provider<CrashlyticsService>((ref) {
  return CrashlyticsService();
});
