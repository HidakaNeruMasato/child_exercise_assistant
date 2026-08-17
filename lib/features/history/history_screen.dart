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
      final user = ref.read(authRepositoryProvider).currentUser;
      ref.read(historyStateProvider.notifier).loadHistories(user?.uid ?? 'user_demo_123');
    });
  }

  @override
  Widget build(BuildContext context) {
    final histories = ref.watch(historyStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('あそんだ履歴'),
      ),
      body: histories.isEmpty
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
                    '遊び詳細画面で「今日あそんだ！」を押すと記録されます。',
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
                    ],
                  ),
                );
              },
            ),
    );
  }
}
