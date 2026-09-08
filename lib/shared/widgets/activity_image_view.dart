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

  ActivityImageView({
    super.key,
    required Activity activity,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.fallbackWidget,
  }) : activityId = activity.id;

  ActivityImageView.withId({
    super.key,
    required this.activityId,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.fallbackWidget,
  });

  /// activity_id から決定されるアセット画像パスの統一取得関数
  static String getImagePath(String id) {
    return 'assets/images/$id.webp';
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

    return Image.asset(
      imagePath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return defaultFallback;
      },
    );
  }
}
