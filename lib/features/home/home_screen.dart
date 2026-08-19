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
import '../../repositories/activity_repository.dart';
import '../../repositories/auth_repository.dart';
import '../../routing/routes.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/tag_chip.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _showConditionEditModal(BuildContext context, WidgetRef ref) {
    final condition = ref.read(recommendationConditionProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final currentCond = ref.watch(recommendationConditionProvider);

            return Padding(
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
                          '游ぶ条件の変更',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const Divider(),
                    const Gap(12),

                    // 年齢
                    Text('子どもの年齢: ${currentCond.childAge}歳',
                        style: Theme.of(context).textTheme.titleMedium),
                    Slider(
                      value: currentCond.childAge.toDouble(),
                      min: 2,
                      max: 12,
                      divisions: 10,
                      label: '${currentCond.childAge}歳',
                      onChanged: (val) {
                        ref.read(recommendationConditionProvider.notifier).state =
                            currentCond.copyWith(childAge: val.round());
                      },
                    ),
                    const Gap(12),

                    // 人数
                    Text('参加人数: ${currentCond.participantCount}人',
                        style: Theme.of(context).textTheme.titleMedium),
                    Slider(
                      value: currentCond.participantCount.toDouble(),
                      min: 1,
                      max: 8,
                      divisions: 7,
                      label: '${currentCond.participantCount}人',
                      onChanged: (val) {
                        ref.read(recommendationConditionProvider.notifier).state =
                            currentCond.copyWith(participantCount: val.round());
                      },
                    ),
                    const Gap(12),

                    // 場所
                    Text('実施場所:', style: Theme.of(context).textTheme.titleMedium),
                    const Gap(8),
                    Wrap(
                      spacing: 8,
                      children: LocationType.values.map((loc) {
                        final isSelected = currentCond.locationType == loc;
                        return ChoiceChip(
                          label: Text(loc.label),
                          selected: isSelected,
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

                    // 想定時間
                    Text('想定時間: ${currentCond.availableTimeMinutes}分',
                        style: Theme.of(context).textTheme.titleMedium),
                    Slider(
                      value: currentCond.availableTimeMinutes.toDouble(),
                      min: 10,
                      max: 60,
                      divisions: 10,
                      label: '${currentCond.availableTimeMinutes}分',
                      onChanged: (val) {
                        ref.read(recommendationConditionProvider.notifier).state =
                            currentCond.copyWith(availableTimeMinutes: val.round());
                      },
                    ),
                    const Gap(12),

                    // 今日の子どもの状態
                    Text('今日の子どもの状態:', style: Theme.of(context).textTheme.titleMedium),
                    const Gap(8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: ChildMoodState.values.map((m) {
                        final isSelected = currentCond.childMoodState == m;
                        return ChoiceChip(
                          label: Text(m.label),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              ref.read(recommendationConditionProvider.notifier).state =
                                  currentCond.copyWith(childMoodState: m);
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const Gap(16),

                    // 季節
                    Text('季節:', style: Theme.of(context).textTheme.titleMedium),
                    const Gap(8),
                    Wrap(
                      spacing: 8,
                      children: Season.values.map((s) {
                        final isSelected = currentCond.season == s;
                        return ChoiceChip(
                          label: Text(s.label),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              ref.read(recommendationConditionProvider.notifier).state =
                                  currentCond.copyWith(season: s);
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const Gap(16),

                    // 雨天スイッチ
                    SwitchListTile(
                      title: const Text('今日は雨が降っている'),
                      subtitle: const Text('屋内・雨天OKな遊びを中心に検索'),
                      value: currentCond.isRaining,
                      onChanged: (val) {
                        ref.read(recommendationConditionProvider.notifier).state =
                            currentCond.copyWith(isRaining: val);
                      },
                    ),
                    const Gap(20),

                    CustomButton(
                      text: '設定を反映して閉じる',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            icon: const Icon(Icons.favorite_rounded, color: AppTheme.accentColor),
            tooltip: 'お気に入り',
            onPressed: () => context.push(AppRoutes.favorites),
          ),
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: '履歴',
            onPressed: () => context.push(AppRoutes.history),
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: '設定',
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 公式ロゴ表示エリア (PCでは2カラム機能的レイアウト、スマホではコンパクト表示)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.25), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: isMobile
                  ? Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            AppConstants.logoBannerPath,
                            width: double.infinity,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                AppConstants.appName,
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        // PC左側: ロゴ画像（上品でちょうど良いサイズ）
                        Expanded(
                          flex: 5,
                          child: Container(
                            height: 140,
                            alignment: Alignment.center,
                            child: Image.asset(
                              AppConstants.logoBannerPath,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Text(
                                AppConstants.appName,
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                              ),
                            ),
                          ),
                        ),
                        const Gap(16),
                        Container(
                          height: 110,
                          width: 1,
                          color: AppTheme.primaryColor.withOpacity(0.2),
                        ),
                        const Gap(20),
                        // PC右側: 今日のクイック気分・条件案内パネル
                        Expanded(
                          flex: 6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.auto_awesome_rounded, color: AppTheme.secondaryColor, size: 20),
                                  const Gap(6),
                                  Text(
                                    '今日のお子さまの気分・状態は？',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textDarkColor,
                                        ),
                                  ),
                                ],
                              ),
                              const Gap(8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: ChildMoodState.values.take(4).map((mood) {
                                  final isSelected = currentCondition.childMoodState == mood;
                                  return ChoiceChip(
                                    label: Text(mood.label, style: const TextStyle(fontSize: 12)),
                                    selected: isSelected,
                                    selectedColor: AppTheme.primaryContainer,
                                    onSelected: (val) {
                                      if (val) {
                                        ref.read(recommendationConditionProvider.notifier).state =
                                            currentCondition.copyWith(childMoodState: mood);
                                        context.push(AppRoutes.recommendations);
                                      }
                                    },
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),

            // 挨拶エリア
            Text(
              'こんにちは、${user?.displayName ?? "保護者"}さま！',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20, color: AppTheme.textDarkColor),
            ),
            const Gap(4),
            Text(
              '今日のお子さまの気分や時間に合わせて最適なおすすめが見つかります。',
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
                    text: 'この条件でおすすめを検索（決定）',
                    icon: Icons.search_rounded,
                    onPressed: () {
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

                return SizedBox(
                  height: 220,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Gap(16),
                    itemBuilder: (context, index) {
                      final item = list[index];
                      return SizedBox(
                        width: 240,
                        child: CustomCard(
                          padding: const EdgeInsets.all(16),
                          onTap: () {
                            // Tap 3: 詳細画面へ
                            context.push(AppRoutes.buildActivityDetailPath(item.id));
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 80,
                                decoration: BoxDecoration(
                                  color: AppTheme.secondaryContainer.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.sports_kabaddi_rounded,
                                    size: 40,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                              const Gap(10),
                              Text(
                                item.title,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontSize: 16,
                                    ),
                                maxLines: 1,
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
                        ),
                      );
                    },
                  ),
                );
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
                label: const Text('すべての遊び・運動一覧を見る（全200件）'),
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
}
