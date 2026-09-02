import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/activity.dart';
import '../../models/recommendation_condition.dart';
import '../../models/notification_settings.dart';
import '../../services/notification_service.dart';
import '../../services/analytics_service.dart';
import '../../repositories/activity_repository.dart';
import '../../repositories/auth_repository.dart';
import '../../routing/routes.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/tag_chip.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsServiceProvider).logViewHome();
    });
  }

  void _showConditionEditModal(BuildContext context, WidgetRef ref) {
    ref.read(analyticsServiceProvider).logOpenCondition();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        bool showDetails = false;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Consumer(
              builder: (context, ref, child) {
                final currentCond = ref.watch(recommendationConditionProvider);

                return Padding(
                  padding: EdgeInsets.only(
                    top: 20,
                    left: 20,
                    right: 20,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '遊ぶ条件の変更',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textDarkColor,
                                  ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                        const Divider(),
                        const Gap(8),

                        // 1. 年齢（数字直接タップUI）
                        Row(
                          children: [
                            const Icon(Icons.child_care_rounded, size: 20, color: AppTheme.primaryColor),
                            const Gap(6),
                            Text(
                              '年齢: ${currentCond.childAge}歳',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const Gap(8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: List.generate(11, (index) {
                            final age = index + 2;
                            final isSelected = currentCond.childAge == age;
                            return ChoiceChip(
                              label: Text('$age歳'),
                              selected: isSelected,
                              selectedColor: AppTheme.primaryColor,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : AppTheme.textDarkColor,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              onSelected: (val) {
                                if (val) {
                                  ref.read(recommendationConditionProvider.notifier).state =
                                      currentCond.copyWith(childAge: age);
                                }
                              },
                            );
                          }),
                        ),
                        const Gap(16),

                        // 2. 実施場所
                        Row(
                          children: [
                            const Icon(Icons.place_rounded, size: 20, color: AppTheme.primaryColor),
                            const Gap(6),
                            Text('実施場所:', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Gap(8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: LocationType.values.map((loc) {
                            final isSelected = currentCond.locationType == loc;
                            return ChoiceChip(
                              label: Text(loc.label),
                              selected: isSelected,
                              selectedColor: AppTheme.primaryColor,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : AppTheme.textDarkColor,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              onSelected: (selected) {
                                if (selected) {
                                  ref.read(recommendationConditionProvider.notifier).state =
                                      currentCond.copyWith(locationType: loc);
                                }
                              },
                            );
                          }).toList(),
                        ),
                        const Gap(16),

                        // 3. 想定時間（数字直接タップUI）
                        Row(
                          children: [
                            const Icon(Icons.timer_rounded, size: 20, color: AppTheme.primaryColor),
                            const Gap(6),
                            Text(
                              '想定時間: ${currentCond.availableTimeMinutes}分',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const Gap(8),
                        Wrap(
                          spacing: 8,
                          children: [10, 15, 20, 30, 45, 60].map((mins) {
                            final isSelected = currentCond.availableTimeMinutes == mins;
                            return ChoiceChip(
                              label: Text('$mins分'),
                              selected: isSelected,
                              selectedColor: AppTheme.primaryColor,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : AppTheme.textDarkColor,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              onSelected: (val) {
                                if (val) {
                                  ref.read(recommendationConditionProvider.notifier).state =
                                      currentCond.copyWith(availableTimeMinutes: mins);
                                }
                              },
                            );
                          }).toList(),
                        ),
                        const Gap(16),

                        // 4. 参加人数（数字直接タップUI）
                        Row(
                          children: [
                            const Icon(Icons.groups_rounded, size: 20, color: AppTheme.primaryColor),
                            const Gap(6),
                            Text(
                              '参加人数: ${currentCond.participantCount}人',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const Gap(8),
                        Wrap(
                          spacing: 8,
                          children: [1, 2, 3, 4, 5, 6].map((count) {
                            final isSelected = currentCond.participantCount == count;
                            return ChoiceChip(
                              label: Text('$count人'),
                              selected: isSelected,
                              selectedColor: AppTheme.primaryColor,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : AppTheme.textDarkColor,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              onSelected: (val) {
                                if (val) {
                                  ref.read(recommendationConditionProvider.notifier).state =
                                      currentCond.copyWith(participantCount: count);
                                }
                              },
                            );
                          }).toList(),
                        ),
                        const Gap(16),

                        // 詳細設定 切り替えボタン
                        Center(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryColor,
                              side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.4)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            icon: Icon(
                              showDetails ? Icons.expand_less_rounded : Icons.tune_rounded,
                              size: 18,
                            ),
                            label: Text(
                              showDetails ? '詳細設定を閉じる' : '【詳細】お子さまの状態・天候・季節など',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                              setModalState(() {
                                showDetails = !showDetails;
                              });
                            },
                          ),
                        ),

                        // 詳細設定 展開エリア
                        if (showDetails) ...[
                          const Gap(16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.cardBorderColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 今日の子どもの状態
                                Text('今日の子どもの状態:', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                                const Gap(8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: ChildMoodState.values.map((m) {
                                    final isSelected = currentCond.childMoodState == m;
                                    return ChoiceChip(
                                      label: Text(m.label),
                                      selected: isSelected,
                                      selectedColor: AppTheme.secondaryColor,
                                      labelStyle: TextStyle(
                                        color: isSelected ? Colors.white : AppTheme.textDarkColor,
                                      ),
                                      onSelected: (selected) {
                                        if (selected) {
                                          ref.read(recommendationConditionProvider.notifier).state =
                                              currentCond.copyWith(childMoodState: m);
                                        }
                                      },
                                    );
                                  }).toList(),
                                ),
                                const Gap(14),

                                // 季節
                                Text('季節:', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                                const Gap(8),
                                Wrap(
                                  spacing: 8,
                                  children: Season.values.map((s) {
                                    final isSelected = currentCond.season == s;
                                    return ChoiceChip(
                                      label: Text(s.label),
                                      selected: isSelected,
                                      selectedColor: AppTheme.secondaryColor,
                                      labelStyle: TextStyle(
                                        color: isSelected ? Colors.white : AppTheme.textDarkColor,
                                      ),
                                      onSelected: (selected) {
                                        if (selected) {
                                          ref.read(recommendationConditionProvider.notifier).state =
                                              currentCond.copyWith(season: s);
                                        }
                                      },
                                    );
                                  }).toList(),
                                ),
                                const Gap(14),

                                // 雨天スイッチ
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('今日は雨が降っている', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                  subtitle: const Text('屋内・雨天OKな遊びを中心に検索', style: TextStyle(fontSize: 12)),
                                  value: currentCond.isRaining,
                                  activeColor: AppTheme.primaryColor,
                                  onChanged: (val) {
                                    ref.read(recommendationConditionProvider.notifier).state =
                                        currentCond.copyWith(isRaining: val);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                        const Gap(20),

                        CustomButton(
                          text: '設定を決定して閉じる',
                          onPressed: () {
                            ref.read(analyticsServiceProvider).logChangeCondition(currentCond);
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authRepositoryProvider).currentUser;
    final activitiesAsync = ref.watch(activityRepositoryProvider).getAllActivities();
    final currentCondition = ref.watch(recommendationConditionProvider);

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 640;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: isMobile ? 80 : 88,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppConstants.appName,
              style: TextStyle(
                fontSize: isMobile ? 19 : 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDarkColor,
              ),
            ),
            const Gap(3),
            Text(
              isMobile
                  ? '年齢や場所、時間に合わせて、\n今日の遊びをお手伝い。'
                  : '年齢や場所、時間に合わせて、今日の遊びをお手伝い。',
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: isMobile ? 11 : 13,
                color: AppTheme.textMutedColor,
                fontWeight: FontWeight.normal,
                height: 1.3,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded, size: 26),
            tooltip: '設定',
            onPressed: () => context.push(AppRoutes.settings),
          ),
          const Gap(4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 挨拶エリア
            Row(
              children: [
                const Icon(Icons.waving_hand_rounded, color: AppTheme.secondaryColor, size: 22),
                const Gap(8),
                Text(
                  'こんにちは、${user?.displayName ?? "保護者"}さま！',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20, color: AppTheme.textDarkColor, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Gap(4),
            Text(
              '今日のお子さまの気分や時間、場所に合わせたぴったりな遊びをお手伝いします。',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textMutedColor,
                  ),
            ),
            const Gap(16),

            // 未運動リマインダー通知バナー
            FutureBuilder<ReminderCheckResult>(
              future: ref.watch(reminderServiceProvider).checkReminder(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.shouldNotify) {
                  final res = snapshot.data!;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.amber.shade400, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.notifications_active_rounded, color: Colors.amber, size: 28),
                        const Gap(12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'リマインダー通知（${res.daysSinceLastActivity}日間あそびの記録がありません）',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppTheme.textDarkColor,
                                ),
                              ),
                              const Gap(2),
                              Text(
                                '今日はお子様と一緒に15分運動してリフレッシュしませんか？',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.brown.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.amber.shade400,
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: const Size(60, 30),
                          ),
                          onPressed: () {
                            context.push(AppRoutes.recommendations);
                          },
                          child: const Text('おすすめを見る', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // クイック条件設定カード (1Tap導線)
            CustomCard(
              backgroundColor: AppTheme.primaryContainer.withOpacity(0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.tune_rounded, color: AppTheme.primaryColor),
                          const Gap(8),
                          Text(
                            '今日の遊ぶ条件',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        label: const Text('変更'),
                        onPressed: () => _showConditionEditModal(context, ref),
                      ),
                    ],
                  ),
                  const Gap(10),
                  InkWell(
                    onTap: () => _showConditionEditModal(context, ref),
                    borderRadius: BorderRadius.circular(16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        TagChip(
                          label: '状態: ${currentCondition.childMoodState.label}',
                          icon: Icons.mood_rounded,
                          backgroundColor: Colors.white,
                        ),
                        TagChip(
                          label: '季節: ${currentCondition.season.label}',
                          icon: Icons.wb_sunny_outlined,
                          backgroundColor: Colors.white,
                        ),
                        TagChip(
                          label: '年齢: ${currentCondition.childAge}歳',
                          icon: Icons.child_care_rounded,
                          backgroundColor: Colors.white,
                        ),
                        TagChip(
                          label: '場所: ${currentCondition.locationType.label}',
                          icon: Icons.place_rounded,
                          backgroundColor: Colors.white,
                        ),
                        TagChip(
                          label: '人数: ${currentCondition.participantCount}人',
                          icon: Icons.groups_rounded,
                          backgroundColor: Colors.white,
                        ),
                        TagChip(
                          label: '時間: ${currentCondition.availableTimeMinutes}分',
                          icon: Icons.timer_rounded,
                          backgroundColor: Colors.white,
                        ),
                        TagChip(
                          label: currentCondition.isRaining ? '天候: 雨 ☔' : '天候: 晴れ/曇り ☀️',
                          icon: currentCondition.isRaining
                              ? Icons.umbrella_rounded
                              : Icons.wb_sunny_rounded,
                          backgroundColor: Colors.white,
                        ),
                      ],
                    ),
                  ),
                  const Gap(16),

                  // Tap 2: おすすめ検索ボタン
                  CustomButton(
                    text: 'この条件でおすすめを検索',
                    icon: Icons.search_rounded,
                    onPressed: () {
                      ref.read(analyticsServiceProvider).logSearchRecommendations(currentCondition);
                      context.push(AppRoutes.recommendations);
                    },
                  ),
                ],
              ),
            ),
            const Gap(24),

            // ピックアップ遊び
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '人気の定番遊び',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20),
                ),
                TextButton(
                  onPressed: () => context.push(AppRoutes.recommendations),
                  child: const Text('すべて見る'),
                ),
              ],
            ),
            const Gap(12),

            FutureBuilder<List<Activity>>(
              future: activitiesAsync,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = snapshot.data ?? [];
                if (list.isEmpty) {
                  return const Text('表示できる遊びがありません');
                }

                if (isMobile) {
                  // スマホ時: 横スライド表示
                  return SizedBox(
                    height: 230,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const Gap(16),
                      itemBuilder: (context, index) {
                        final item = list[index];
                        return SizedBox(
                          width: 240,
                          child: _buildPopularActivityCard(context, item),
                        );
                      },
                    ),
                  );
                } else {
                  // PC時: スライドせず画面幅にピタッと収まる4件を表示
                  final pcItems = list.take(4).toList();
                  return Row(
                    children: pcItems.map((item) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: _buildPopularActivityCard(context, item),
                        ),
                      );
                    }).toList(),
                  );
                }
              },
            ),
            const Gap(24),
            // 最下部：目立たない全件一覧への案内ボタン
            Center(
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.textMutedColor,
                  textStyle: const TextStyle(fontSize: 13, decoration: TextDecoration.underline),
                ),
                icon: const Icon(Icons.list_alt_rounded, size: 16),
                label: const Text('すべての遊び・運動一覧を見る（全50件）'),
                onPressed: () {
                  context.push(AppRoutes.allActivities);
                },
              ),
            ),
            const Gap(32),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularActivityCard(BuildContext context, Activity item) {
    return CustomCard(
      padding: const EdgeInsets.all(16),
      onTap: () {
        context.push(AppRoutes.buildActivityDetailPath(item.id));
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 90,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.secondaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: item.imageUrl != null
                  ? Image.asset(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Icon(
                          Icons.sports_kabaddi_rounded,
                          size: 40,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    )
                  : Center(
                      child: Icon(
                        Icons.sports_kabaddi_rounded,
                        size: 40,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
            ),
          ),
          const Gap(10),
          Text(
            item.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Gap(4),
          Text(
            item.description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textMutedColor,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Gap(6),
          Row(
            children: [
              TagChip(
                label: '${item.minAge}〜${item.maxAge}歳',
                backgroundColor: AppTheme.primaryContainer.withOpacity(0.4),
              ),
              const Gap(6),
              TagChip(
                label: '${item.durationMinutes}分',
                backgroundColor: AppTheme.secondaryContainer.withOpacity(0.4),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
