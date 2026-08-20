import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/recommendation_condition.dart';
import '../../models/scored_activity.dart';
import '../../repositories/activity_repository.dart';
import '../../routing/routes.dart';
import '../../services/recommendation_service.dart';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/tag_chip.dart';

class RecommendationScreen extends ConsumerStatefulWidget {
  const RecommendationScreen({super.key});

  @override
  ConsumerState<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends ConsumerState<RecommendationScreen> {
  List<ScoredActivity>? _recommendations;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _fetchRecommendations());
  }

  Future<void> _fetchRecommendations() async {
    setState(() => _isLoading = true);
    final activities = await ref.read(activityRepositoryProvider).getAllActivities();
    final recService = ref.read(recommendationServiceProvider);
    final currentCondition = ref.read(recommendationConditionProvider);

    final results = await recService.getRecommendations(
      candidates: activities,
      condition: currentCondition,
      limit: AppConstants.defaultRecommendationLimit,
    );

    if (mounted) {
      setState(() {
        _recommendations = results;
        _isLoading = false;
      });
    }
  }

  void _updateCondition(RecommendationCondition newCondition) {
    ref.read(recommendationConditionProvider.notifier).state = newCondition;
    _fetchRecommendations();
  }

  @override
  Widget build(BuildContext context) {
    final condition = ref.watch(recommendationConditionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('おすすめの遊び（上位5選）'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // フィルター条件変更ドロワー/アコーディオン
            ExpansionTile(
              title: Text(
                '条件を変更・絞り込み (${condition.childAge}歳 / ${condition.locationType.label} / ${condition.isRaining ? "雨" : "晴・曇"})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.primaryColor,
                      fontSize: 15,
                    ),
              ),
              leading: const Icon(Icons.filter_alt_rounded, color: AppTheme.primaryColor),
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 年齢（数字直接タップ）
                      Text('子どもの年齢: ${condition.childAge}歳',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const Gap(6),
                      SizedBox(
                        height: 38,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: 11, // 2歳〜12歳
                          separatorBuilder: (_, __) => const Gap(6),
                          itemBuilder: (context, index) {
                            final age = index + 2;
                            final isSelected = condition.childAge == age;
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
                                  _updateCondition(condition.copyWith(childAge: age));
                                }
                              },
                            );
                          },
                        ),
                      ),
                      const Gap(12),

                      // 人数（数字直接タップ）
                      Text('人数: ${condition.participantCount}人',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const Gap(6),
                      Wrap(
                        spacing: 8,
                        children: [1, 2, 3, 4, 5, 6].map((count) {
                          final isSelected = condition.participantCount == count;
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
                                _updateCondition(condition.copyWith(participantCount: count));
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const Gap(12),

                      // 今日の子どもの状態選択
                      Text('今日の子どもの状態:', style: Theme.of(context).textTheme.bodyLarge),
                      const Gap(4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: ChildMoodState.values.map((m) {
                          final isSelected = condition.childMoodState == m;
                          return ChoiceChip(
                            label: Text(m.label),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                _updateCondition(condition.copyWith(childMoodState: m));
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const Gap(12),

                      // 実施場所選択
                      Text('実施場所:', style: Theme.of(context).textTheme.bodyLarge),
                      const Gap(6),
                      Wrap(
                        spacing: 8,
                        children: LocationType.values.map((loc) {
                          final isSelected = condition.locationType == loc;
                          return ChoiceChip(
                            label: Text(loc.label),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                _updateCondition(condition.copyWith(locationType: loc));
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const Gap(12),

                      // 季節選択
                      Text('対象季節:', style: Theme.of(context).textTheme.bodyLarge),
                      const Gap(6),
                      Wrap(
                        spacing: 8,
                        children: Season.values.map((s) {
                          final isSelected = condition.season == s;
                          return ChoiceChip(
                            label: Text(s.label),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                _updateCondition(condition.copyWith(season: s));
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const Gap(12),

                      // 所要時間スライダー
                      Row(
                        children: [
                          Text('想定時間: ${condition.availableTimeMinutes}分',
                              style: Theme.of(context).textTheme.bodyLarge),
                          Expanded(
                            child: Slider(
                              value: condition.availableTimeMinutes.toDouble(),
                              min: 10,
                              max: 60,
                              divisions: 10,
                              label: '${condition.availableTimeMinutes}分',
                              onChanged: (val) {
                                _updateCondition(
                                    condition.copyWith(availableTimeMinutes: val.round()));
                              },
                            ),
                          ),
                        ],
                      ),
                      const Gap(8),

                      // 雨天スイッチ
                      SwitchListTile(
                        title: const Text('今日は雨が降っている（雨天・室内対応）'),
                        value: condition.isRaining,
                        onChanged: (val) {
                          _updateCondition(condition.copyWith(isRaining: val));
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Gap(16),

            Text(
              'マッチ度順おすすめ結果',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20),
            ),
            const Gap(12),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_recommendations == null || _recommendations!.isEmpty)
              const CustomCard(
                child: Text('条件にマッチする遊びが見つかりませんでした。条件を少し広げてみてください。'),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recommendations!.length,
                separatorBuilder: (_, __) => const Gap(16),
                itemBuilder: (context, index) {
                  final scored = _recommendations![index];
                  final activity = scored.activity;
                  final rank = index + 1;

                  return CustomCard(
                    onTap: () {
                      context.push(AppRoutes.buildActivityDetailPath(activity.id));
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (activity.imageUrl != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: SizedBox(
                                height: 120,
                                width: double.infinity,
                                child: activity.imageUrl!.startsWith('assets/')
                                    ? Image.asset(activity.imageUrl!, fit: BoxFit.cover)
                                    : Image.network(activity.imageUrl!, fit: BoxFit.cover),
                              ),
                            ),
                          ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: rank == 1
                                    ? AppTheme.tertiaryColor
                                    : AppTheme.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '$rank',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                            const Gap(12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
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
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(5, (starIndex) {
                                    final isFilled = starIndex < scored.starRating;
                                    return Icon(
                                      isFilled ? Icons.star_rounded : Icons.star_border_rounded,
                                      color: isFilled ? const Color(0xFFFFB800) : Colors.grey.shade400,
                                      size: 18,
                                    );
                                  }),
                                ),
                                const Gap(4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryContainer.withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    scored.starLabel,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Gap(12),
                        const Divider(height: 1),
                        const Gap(10),
                        // マッチ理由タグ
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: scored.matchReasons
                              .map(
                                (reason) => TagChip(
                                  label: reason,
                                  icon: Icons.check_circle_rounded,
                                  backgroundColor: AppTheme.primaryContainer.withOpacity(0.3),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
