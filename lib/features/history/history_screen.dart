import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/history_repository.dart';
import '../../routing/routes.dart';
import '../../shared/widgets/custom_card.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final familyId = ref.read(familyIdProvider);
      ref.read(historyStateProvider.notifier).loadHistories(familyId);
    });
  }

  void _showEditFamilyIdDialog(BuildContext context, WidgetRef ref) {
    final currentFamilyId = ref.read(familyIdProvider);
    final controller = TextEditingController(text: currentFamilyId);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.family_restroom_rounded, color: AppTheme.primaryColor),
              Gap(8),
              Text('家族で履歴共有（合言葉）'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '個人情報の登録なしで、同じ合言葉を入力している家族（パパ・ママ・おじいちゃん・おばあちゃん）同士で遊びの履歴が自動共有されます！',
                style: TextStyle(fontSize: 12, color: AppTheme.textMutedColor),
              ),
              const Gap(16),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'ファミリー合言葉',
                  hintText: '例: たなか家, sato-family-7',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                final newId = controller.text.trim();
                if (newId.isNotEmpty) {
                  ref.read(familyIdProvider.notifier).state = newId;
                  ref.read(historyStateProvider.notifier).loadHistories(newId);
                }
                Navigator.pop(context);
              },
              child: const Text('設定する'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final histories = ref.watch(historyStateProvider);
    final familyId = ref.watch(familyIdProvider);

    final totalMinutes = histories.fold<int>(0, (sum, h) => sum + h.activity.durationMinutes);

    return Scaffold(
      appBar: AppBar(
        title: const Text('あそんだ履歴（家族共有）'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: '合言葉設定',
            onPressed: () => _showEditFamilyIdDialog(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          // ファミリー合言葉バナー
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppTheme.primaryContainer.withOpacity(0.4),
            child: Row(
              children: [
                const Icon(Icons.family_restroom_rounded, color: AppTheme.primaryColor, size: 26),
                const Gap(10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            '共有合言葉: ',
                            style: TextStyle(fontSize: 12, color: AppTheme.textMutedColor),
                          ),
                          Text(
                            '【 $familyId 】',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const Gap(2),
                      Text(
                        '合計 $totalMinutes 分運動（家族全員のあそび記録を同期中）',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textDarkColor),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: const Size(50, 30),
                  ),
                  onPressed: () => _showEditFamilyIdDialog(context, ref),
                  child: const Text('合言葉変更', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ),

          Expanded(
            child: histories.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_rounded,
                            size: 64, color: AppTheme.textMutedColor.withOpacity(0.5)),
                        const Gap(16),
                        Text(
                          'まだ実施履歴がありません',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppTheme.textMutedColor,
                              ),
                        ),
                        const Gap(8),
                        Text(
                          '遊び詳細画面で「今日あそんだ！」を押すと、同じ合言葉の家族全員に即時共有されます。',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textMutedColor,
                              ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: histories.length,
                    separatorBuilder: (_, __) => const Gap(16),
                    itemBuilder: (context, index) {
                      final hist = histories[index];
                      final activity = hist.activity;
                      final dateStr = DateFormat('yyyy/MM/dd HH:mm').format(hist.playedAt);

                      return CustomCard(
                        onTap: () {
                          context.push(AppRoutes.buildActivityDetailPath(activity.id));
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  dateStr,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppTheme.textMutedColor,
                                        fontSize: 13,
                                      ),
                                ),
                                Row(
                                  children: List.generate(
                                    5,
                                    (i) => Icon(
                                      i < hist.rating
                                          ? Icons.star_rounded
                                          : Icons.star_border_rounded,
                                      color: Colors.amber,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Gap(8),
                            Text(
                              activity.title,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontSize: 18,
                                  ),
                            ),
                            const Gap(4),
                            Text(
                              activity.description,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textMutedColor,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (hist.note != null && hist.note!.isNotEmpty) ...[
                              const Gap(8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryContainer.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  hist.note!,
                                  style: const TextStyle(fontSize: 12, color: AppTheme.primaryColor),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
