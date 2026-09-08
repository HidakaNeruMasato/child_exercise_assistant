import 'package:flutter/material.dart';

/// 遊びの画像を表示する汎用ウィジェット
/// アセットパス (assets/..., web/assets/...) や ネットワークURL (http...) を自動判別し、
/// 読み込み失敗時には互換パスへのフォールバックを試みます。
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

    final url = imageUrl!.trim();

    // ネットワークURL
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => defaultFallback,
      );
    }

    // アセット画像
    String primaryPath = url;
    String secondaryPath = url.startsWith('web/')
        ? url.substring(4) // web/assets/... -> assets/...
        : 'web/$url'; // assets/... -> web/assets/...

    return Image.asset(
      primaryPath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) {
        return Image.asset(
          secondaryPath,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => defaultFallback,
        );
      },
    );
  }
}
