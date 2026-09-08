import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// 遊びの画像を表示する汎用ウィジェット
/// アセットパス (assets/..., web/assets/...) や ネットワークURL (http...) を自動判別し、
/// 読み込み失敗時には互換パスおよびWeb静的直アクセスへの多重フォールバックを試みます。
class ActivityImageView extends StatelessWidget {
  final String? imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? fallbackWidget;

  const ActivityImageView({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.fallbackWidget,
  });

  @override
  Widget build(BuildContext context) {
    final defaultFallback = fallbackWidget ??
        Center(
          child: Icon(
            Icons.sports_kabaddi_rounded,
            size: 40,
            color: Theme.of(context).colorScheme.primary,
          ),
        );

    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return defaultFallback;
    }

    final rawUrl = imageUrl!.trim();

    // 絶対URL (http:// や https://)
    if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
      return Image.network(
        rawUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => defaultFallback,
      );
    }

    // アセット画像パスの解決バリエーション
    final String cleanPath = rawUrl.startsWith('web/') ? rawUrl.substring(4) : rawUrl; // e.g. assets/images/activity_tag_chase.jpg
    final String webPath = rawUrl.startsWith('web/') ? rawUrl : 'web/$rawUrl'; // e.g. web/assets/images/activity_tag_chase.jpg
    final String fileName = rawUrl.split('/').last; // e.g. activity_tag_chase.jpg

    // Web環境での静的ネットワークURLフォールバック一覧
    final webNetworkUrls = [
      rawUrl,
      webPath,
      cleanPath,
      'web/assets/images/$fileName',
      'assets/images/$fileName',
    ];

    Widget buildWebNetworkFallback(int index) {
      if (index >= webNetworkUrls.length) return defaultFallback;
      final urlCandidate = webNetworkUrls[index];
      return Image.network(
        urlCandidate,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => buildWebNetworkFallback(index + 1),
      );
    }

    // アセット試行チェーン
    return Image.asset(
      webPath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) {
        return Image.asset(
          cleanPath,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) {
            if (kIsWeb) {
              return buildWebNetworkFallback(0);
            }
            return defaultFallback;
          },
        );
      },
    );
  }
}
