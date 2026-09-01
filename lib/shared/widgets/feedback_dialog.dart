import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../core/theme/app_theme.dart';
import '../../models/app_feedback.dart';
import '../../repositories/feedback_repository.dart';
import '../../services/analytics_service.dart';
import 'custom_button.dart';

/// 個別遊びまたはアプリ全体のフィードバックダイアログ
class FeedbackDialog extends ConsumerStatefulWidget {
  final FeedbackType type;
  final String? activityId;
  final String? activityTitle;
  final List<String> childNames;

  const FeedbackDialog({
    super.key,
    required this.type,
    this.activityId,
    this.activityTitle,
    this.childNames = const [],
  });

  /// 個別遊び評価用ダイアログ表示ヘルパー
  static Future<void> showActivityFeedback(
    BuildContext context, {
    required String activityId,
    required String activityTitle,
    List<String> childNames = const [],
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => FeedbackDialog(
        type: FeedbackType.activityRecord,
        activityId: activityId,
        activityTitle: activityTitle,
        childNames: childNames,
      ),
    );
  }

  /// アプリ全体フィードバック用ダイアログ表示ヘルパー
  static Future<void> showAppFeedback(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const FeedbackDialog(
        type: FeedbackType.appGeneral,
      ),
    );
  }

  @override
  ConsumerState<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends ConsumerState<FeedbackDialog> {
  double _rating = 5.0;
  bool _showCommentInput = false;
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final feedback = AppFeedback(
      type: widget.type,
      activityId: widget.activityId,
      activityTitle: widget.activityTitle,
      childNames: widget.childNames,
      rating: _rating,
      comment: _commentController.text.trim(),
    );

    await ref.read(feedbackListProvider.notifier).addFeedback(feedback);

    ref.read(analyticsServiceProvider).logSubmitFeedback(
          feedbackType: widget.type.name,
          activityId: widget.activityId,
        );

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.favorite_rounded, color: Colors.white, size: 20),
              Gap(8),
              Text('フィードバックをお寄せいただきありがとうございます！'),
            ],
          ),
          backgroundColor: AppTheme.primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActivity = widget.type == FeedbackType.activityRecord;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // アイコン＆タイトル
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.rate_review_rounded,
                  size: 36,
                  color: AppTheme.primaryColor,
                ),
              ),
              const Gap(12),
              Text(
                'やってみてどうでしたか？',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDarkColor,
                      fontSize: 20,
                    ),
                textAlign: TextAlign.center,
              ),
              if (isActivity && widget.activityTitle != null) ...[
                const Gap(4),
                Text(
                  widget.activityTitle!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (widget.childNames.isNotEmpty) ...[
                const Gap(4),
                Text(
                  'あそんだ子ども: ${widget.childNames.join('・')}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMutedColor),
                ),
              ],
              const Gap(20),

              // ★5つ星評価バー
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starValue = index + 1.0;
                  final isFilled = _rating >= starValue;
                  return IconButton(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 40,
                      color: isFilled ? const Color(0xFFFFB300) : Colors.grey.shade400,
                    ),
                    onPressed: () {
                      setState(() {
                        _rating = starValue;
                      });
                    },
                  );
                }),
              ),
              const Gap(6),
              Text(
                _getRatingText(_rating),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppTheme.textDarkColor,
                ),
              ),
              const Gap(16),

              // 「詳しくおしえる」アコーディオンボタン
              if (!_showCommentInput)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _showCommentInput = true;
                    });
                  },
                  icon: const Icon(Icons.edit_note_rounded, size: 20),
                  label: const Text(
                    '詳しくおしえる（感想・改善点） 💬',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                  ),
                ),

              // 自由記述コメントテキストフォーム
              if (_showCommentInput) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.cardBorderColor),
                  ),
                  child: TextField(
                    controller: _commentController,
                    maxLines: 3,
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: '「すごく盛り上がった」「難易度が高すぎた」などの感想やアプリへのご要望を自由にお書きください♪',
                      border: InputBorder.none,
                      hintStyle: TextStyle(fontSize: 12, color: AppTheme.textMutedColor),
                    ),
                  ),
                ),
                const Gap(12),
              ],
              const Gap(12),

              // 送信 & スキップボタン
              CustomButton(
                text: 'フィードバックを送信',
                icon: Icons.send_rounded,
                onPressed: _submit,
              ),
              const Gap(8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('あとで・スキップ', style: TextStyle(color: AppTheme.textMutedColor)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRatingText(double rating) {
    if (rating >= 5.0) return '最高！大喜びで楽しめた 🌟';
    if (rating >= 4.0) return '楽しかった！おすすめ 👍';
    if (rating >= 3.0) return '普通に楽しめた 😊';
    if (rating >= 2.0) return '少し難しかった・イマイチ 😅';
    return '合わなかった・改善してほしい 😭';
  }
}
