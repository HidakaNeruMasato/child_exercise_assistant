import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/activity.dart';

/// 全画面共通の遊び画像解決・描画コンポーネント
///
/// 画面側からは [activity] (または [activityId]) を渡すだけで、
/// 統一ルール `assets/images/{activity_id}.webp` に従って自動的に画像を取得・表示します。
/// 画像が存在しない場合でもクラッシュせず、フォールバックを表示します。
class ActivityImageView extends StatelessWidget {
  final String activityId;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? fallbackWidget;
  final bool enableZoom;

  ActivityImageView({
    super.key,
    required Activity activity,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
    this.fallbackWidget,
    this.enableZoom = false,
  }) : activityId = activity.id;

  ActivityImageView.withId({
    super.key,
    required this.activityId,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
    this.fallbackWidget,
    this.enableZoom = false,
  });

  /// activity_id から決定されるアセット画像パスの統一取得関数
  static String getImagePath(String id) {
    return 'assets/images/$id.webp';
  }

  void _showZoomDialog(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black.withOpacity(0.9),
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const Center(child: Icon(Icons.broken_image_rounded, color: Colors.white, size: 48)),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String imagePath = getImagePath(activityId);

    final defaultFallback = fallbackWidget ??
        Container(
          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.sports_kabaddi_rounded,
                  size: 36,
                  color: Theme.of(context).colorScheme.primary,
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 4),
                  Text(
                    '未登録: $activityId',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );

    final imageWidget = Image.asset(
      imagePath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return defaultFallback;
      },
    );

    if (!enableZoom) return imageWidget;

    return GestureDetector(
      onTap: () => _showZoomDialog(context, imagePath),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: imageWidget,
      ),
    );
  }
}
