import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../core/theme/app_theme.dart';
import '../../models/app_feedback.dart';
import '../../repositories/feedback_repository.dart';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/tag_chip.dart';

/// フィードバック管理ダッシュボード画面
class FeedbackDashboardScreen extends ConsumerStatefulWidget {
  const FeedbackDashboardScreen({super.key});

  @override
  ConsumerState<FeedbackDashboardScreen> createState() => _FeedbackDashboardScreenState();
}

class _FeedbackDashboardScreenState extends ConsumerState<FeedbackDashboardScreen> {
  String _selectedFilter = 'すべて';

  @override
  Widget build(BuildContext context) {
    final feedbacksAsync = ref.watch(feedbackListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('フィードバック管理ダッシュボード'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: '更新',
            onPressed: () => ref.read(feedbackListProvider.notifier).refresh(),
          ),
        ],
      ),
      body: feedbacksAsync.when(
        data: (feedbacks) {
          if (feedbacks.isEmpty) {
            return const Center(
              child: Text('まだフィードバックがありません。'),
            );
          }

          final totalCount = feedbacks.length;
          final avgRating = (feedbacks.map((f) => f.rating).reduce((a, b) => a + b) / totalCount);
          final commentsCount = feedbacks.where((f) => f.comment.isNotEmpty).length;

          final filteredList = feedbacks.where((f) {
            if (_selectedFilter == 'コメントあり') return f.comment.isNotEmpty;
            if (_selectedFilter == 'アプリ全体') return f.type == FeedbackType.appGeneral;
            if (_selectedFilter == '遊び評価') return f.type == FeedbackType.activityRecord;
            return true;
          }).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. 概要サマリーカード
                CustomCard(
                  backgroundColor: Colors.white,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem('総投稿件数', '$totalCount件', Icons.rate_review_rounded, AppTheme.primaryColor),
                          Container(width: 1, height: 40, color: Colors.grey.shade300),
                          _buildStatItem('平均満足度', '★ ${avgRating.toStringAsFixed(1)}', Icons.star_rounded, const Color(0xFFFFB300)),
                          Container(width: 1, height: 40, color: Colors.grey.shade300),
                          _buildStatItem('詳細コメント', '$commentsCount件', Icons.chat_rounded, AppTheme.secondaryColor),
                        ],
                      ),
                    ],
                  ),
                ),
                const Gap(20),

                // 2. フィルタチップ
                Row(
                  children: [
                    const Text('絞り込み:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const Gap(8),
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: ['すべて', 'コメントあり', '遊び評価', 'アプリ全体'].map((filter) {
                            final isSelected = _selectedFilter == filter;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(filter, style: const TextStyle(fontSize: 12)),
                                selected: isSelected,
                                selectedColor: AppTheme.primaryColor,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : AppTheme.textDarkColor,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                onSelected: (val) {
                                  if (val) {
                                    setState(() {
                                      _selectedFilter = filter;
                                    });
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(16),

                // 3. フィードバック一覧
                Text(
                  'ユーザーの声一覧 (${filteredList.length}件)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Gap(12),

                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredList.length,
                  separatorBuilder: (_, __) => const Gap(12),
                  itemBuilder: (context, index) {
                    final item = filteredList[index];
                    final isGeneral = item.type == FeedbackType.appGeneral;

                    return CustomCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TagChip(
                                label: isGeneral ? 'アプリ全体のご意見' : (item.activityTitle ?? '遊び評価'),
                                icon: isGeneral ? Icons.app_shortcut_rounded : Icons.sports_kabaddi_rounded,
                                backgroundColor: isGeneral
                                    ? AppTheme.secondaryContainer.withOpacity(0.6)
                                    : AppTheme.primaryContainer.withOpacity(0.5),
                              ),
                              Text(
                                _formatDate(item.createdAt),
                                style: const TextStyle(fontSize: 11, color: AppTheme.textMutedColor),
                              ),
                            ],
                          ),
                          const Gap(8),
                          Row(
                            children: [
                              Row(
                                children: List.generate(5, (sIndex) {
                                  final starVal = sIndex + 1.0;
                                  return Icon(
                                    item.rating >= starVal ? Icons.star_rounded : Icons.star_outline_rounded,
                                    size: 18,
                                    color: item.rating >= starVal ? const Color(0xFFFFB300) : Colors.grey.shade300,
                                  );
                                }),
                              ),
                              const Gap(8),
                              Text(
                                '${item.rating.toStringAsFixed(1)} / 5.0',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              if (item.childNames.isNotEmpty) ...[
                                const Spacer(),
                                Text(
                                  '👦 ${item.childNames.join("・")}',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textMutedColor),
                                ),
                              ],
                            ],
                          ),
                          const Gap(8),
                          if (item.comment.isNotEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.backgroundColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.cardBorderColor),
                              ),
                              child: Text(
                                item.comment,
                                style: const TextStyle(fontSize: 13, height: 1.4, color: AppTheme.textDarkColor),
                              ),
                            )
                          else
                            const Text(
                              '（自由記述コメントなし）',
                              style: TextStyle(fontSize: 12, color: AppTheme.textMutedColor, fontStyle: FontStyle.italic),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('エラーが発生しました: $err')),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const Gap(4),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMutedColor)),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}/${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
