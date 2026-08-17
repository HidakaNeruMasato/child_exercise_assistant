import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/activity.dart';
import '../../models/scored_activity.dart';
import '../../repositories/activity_repository.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/favorite_repository.dart';
import '../../repositories/history_repository.dart';
import '../../routing/routes.dart';
import '../../services/recommendation_service.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/tag_chip.dart';

class ActivityDetailScreen extends ConsumerStatefulWidget {
  final String activityId;

  const ActivityDetailScreen({super.key, required this.activityId});

  @override
  ConsumerState<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends ConsumerState<ActivityDetailScreen> {
  Activity? _activity;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActivity();
  }

  List<Activity> _similarActivities = [];

  Future<void> _loadActivity() async {
    final repo = ref.read(activityRepositoryProvider);
    final data = await repo.getActivityById(widget.activityId);
    final allActivities = await repo.getAllActivities();

    if (data != null && mounted) {
      // 類似テイストの遊びを選出 (自分以外で場所/運動強度/年齢が近いもの)
      final candidates = allActivities.where((a) => a.id != data.id).toList();
      candidates.sort((a, b) {
        int scoreA = 0;
        int scoreB = 0;

        // 場所の一致
        if (a.locationTypes.any((l) => data.locationTypes.contains(l))) scoreA += 3;
        if (b.locationTypes.any((l) => data.locationTypes.contains(l))) scoreB += 3;

        // 運動強度の一致
        if (a.intensityLevel == data.intensityLevel) scoreA += 2;
        if (b.intensityLevel == data.intensityLevel) scoreB += 2;

        // 雨天条件の一致
        if (a.isIndoorOk == data.isIndoorOk) scoreA += 2;
        if (b.isIndoorOk == data.isIndoorOk) scoreB += 2;

        return scoreB.compareTo(scoreA);
      });

      setState(() {
        _activity = data;
        _similarActivities = candidates.take(3).toList();
        _isLoading = false;
      });
    }
  }

  void _shuffleSimilarActivities() async {
    final repo = ref.read(activityRepositoryProvider);
    final all = await repo.getAllActivities();
    if (_activity == null) return;

    final candidates = all.where((a) => a.id != _activity!.id).toList();
    candidates.shuffle();
    setState(() {
      _similarActivities = candidates.take(3).toList();
    });
  }

  Future<void> _recordPlayed() async {
    final user = ref.read(authRepositoryProvider).currentUser;
    final userId = user?.uid ?? 'user_demo_123';
    if (_activity == null) return;

    final played = _activity!;

    await ref.read(historyStateProvider.notifier).recordPlay(
          userId,
          played,
          rating: 5,
        );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('「今日あそんだ！」に記録しました！おつかれさまでした🎉'),
        backgroundColor: AppTheme.secondaryColor,
        duration: Duration(seconds: 2),
      ),
    );

    // 想定時間が30分未満の場合は運動効果を補完する遊びを提案
    if (played.durationMinutes < 30) {
      final repo = ref.read(activityRepositoryProvider);
      final all = await repo.getAllActivities();
      final recService = ref.read(recommendationServiceProvider);

      final complementaryList = await recService.getComplementaryRecommendations(
        candidates: all,
        playedActivity: played,
        targetTotalMinutes: 30,
      );

      if (complementaryList.isNotEmpty && mounted) {
        _showComplementaryDialog(context, complementaryList, 30 - played.durationMinutes);
      }
    }
  }

  void _showComplementaryDialog(
    BuildContext context,
    List<ScoredActivity> recommendations,
    int remainingMinutes,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.stars_rounded, color: AppTheme.primaryColor, size: 28),
                  const Gap(8),
                  Expanded(
                    child: Text(
                      '合わせてこの遊び・運動もどうぞ！',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                    ),
                  ),
                ],
              ),
              const Gap(10),
              Text(
                '今の遊び（${_activity!.durationMinutes}分）にプラス約${remainingMinutes}分！合計30分のしっかり運動で、運動効果がさらにアップするおすすめの組み合わせです：',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textDarkColor,
                    ),
              ),
              const Gap(16),

              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recommendations.length,
                  separatorBuilder: (_, __) => const Gap(12),
                  itemBuilder: (context, index) {
                    final item = recommendations[index];
                    return CustomCard(
                      onTap: () {
                        Navigator.of(ctx).pop();
                        context.pushReplacement(AppRoutes.buildActivityDetailPath(item.activity.id));
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.activity.title,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                              Chip(
                                label: Text('${item.activity.durationMinutes}分'),
                                backgroundColor: AppTheme.secondaryContainer.withOpacity(0.5),
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                          const Gap(6),
                          Text(
                            item.activity.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const Gap(8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: item.matchReasons.map((reason) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryContainer.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '✨ $reason',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textDarkColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const Gap(16),

              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('今日はこれで完了にする'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_activity == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('遊び詳細')),
        body: const Center(child: Text('遊びデータが見つかりませんでした')),
      );
    }

    final activity = _activity!;
    final user = ref.watch(authRepositoryProvider).currentUser;
    final userId = user?.uid ?? 'user_demo_123';
    final favorites = ref.watch(favoritesStateProvider);
    final isFav = favorites.any((f) => f.activityId == activity.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(activity.title),
        actions: [
          IconButton(
            icon: Icon(
              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: AppTheme.primaryColor,
            ),
            onPressed: () {
              ref
                  .read(favoritesStateProvider.notifier)
                  .toggleFavorite(userId, activity);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 2D動作解説イラスト
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              child: Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer.withOpacity(0.2),
                ),
                child: activity.imageUrl != null
                    ? (activity.imageUrl!.startsWith('assets/')
                        ? Image.asset(
                            activity.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                          )
                        : Image.network(
                            activity.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                          ))
                    : _buildPlaceholderImage(),
              ),
            ),
            const Gap(8),
            Row(
              children: [
                const Icon(Icons.accessibility_new_rounded, size: 18, color: AppTheme.primaryColor),
                const Gap(6),
                Text(
                  'フォーム解説: イラストで肘・膝の曲げ方やポーズを確認できます',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const Gap(16),

            // タイトル・概要
            Text(
              activity.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 24),
            ),
            const Gap(8),
            Text(
              activity.description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textDarkColor,
                  ),
            ),
            const Gap(16),

            // タグ一覧
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                TagChip(
                  label: '対象年齢: ${activity.minAge}〜${activity.maxAge}歳',
                  icon: Icons.child_care_rounded,
                ),
                TagChip(
                  label: '人数: ${activity.minParticipants}〜${activity.maxParticipants}人',
                  icon: Icons.groups_rounded,
                ),
                TagChip(
                  label: '想定時間: ${activity.durationMinutes}分',
                  icon: Icons.timer_rounded,
                ),
                TagChip(
                  label: '親の関わり: ${activity.parentInvolvement.label}',
                  icon: Icons.face_rounded,
                  backgroundColor: AppTheme.secondaryContainer.withOpacity(0.6),
                ),
                TagChip(
                  label: '強度: ${activity.intensityLevel.label}',
                  icon: Icons.bolt_rounded,
                ),
                TagChip(
                  label: '適した季節: ${activity.seasons.length == 4 ? "通年 OK" : activity.seasons.map((s) => s.label).join("・")}',
                  icon: Icons.wb_sunny_outlined,
                  backgroundColor: AppTheme.primaryContainer.withOpacity(0.5),
                ),
                TagChip(
                  label: '難易度: ${activity.difficultyLevel.label}',
                  icon: Icons.star_rounded,
                ),
              ],
            ),
            const Gap(12),
            // 親の関わり補足説明
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.secondaryContainer.withOpacity(0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 18, color: AppTheme.secondaryColor),
                  const Gap(8),
                  Expanded(
                    child: Text(
                      activity.parentInvolvement.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 13,
                            color: AppTheme.textDarkColor,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const Gap(24),

            // 安全レベル＆保護者アドバイス
            CustomCard(
              backgroundColor: const Color(0xFFFFF3E0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shield_rounded, color: Colors.orange),
                      const Gap(8),
                      Text(
                        '保護者さまへのお約束・安全チェック',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.deepOrange,
                            ),
                      ),
                    ],
                  ),
                  const Gap(10),
                  ...activity.safetyTips.map(
                    (tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('・ ', style: TextStyle(fontWeight: FontWeight.bold)),
                          Expanded(
                            child: Text(
                              tip,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Gap(24),

            // 遊ぶ手順 (Steps)
            Text(
              'あそびかた手順',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20),
            ),
            const Gap(12),

            ...activity.steps.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final stepText = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: CustomCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppTheme.secondaryColor,
                        child: Text(
                          '$idx',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Gap(12),
                      Expanded(
                        child: Text(
                          stepText,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const Gap(24),

            // 親からの適切な声掛け例 (Praise Tips)
            if (activity.parentPraiseTips.isNotEmpty) ...[
              CustomCard(
                backgroundColor: const Color(0xFFE8F5E9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.record_voice_over_rounded, color: Colors.green),
                        const Gap(8),
                        Text(
                          '親からの声掛け例（モチベーションUP！）',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.green.shade800,
                              ),
                        ),
                      ],
                    ),
                    const Gap(12),
                    ...activity.parentPraiseTips.map(
                      (praise) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.format_quote_rounded,
                                  size: 20, color: Colors.green),
                              const Gap(8),
                              Expanded(
                                child: Text(
                                  praise,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green.shade900,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(24),
            ],

            // 完了ボタン
            CustomButton(
              text: '今日このあそびをやった！',
              icon: Icons.check_circle_outline_rounded,
              onPressed: _recordPlayed,
            ),
            const Gap(32),

            // 類似・別の遊びを表示するエリア（子どもがやりたくなかった場合のチェンジ機能）
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'お子様が乗り気じゃない時は？',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.primaryColor,
                              fontSize: 18,
                            ),
                      ),
                      Text(
                        '似たテイストの別の遊びを表示します',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textMutedColor,
                              fontSize: 13,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryColor),
                  tooltip: '別の選択肢をランダム表示',
                  onPressed: _shuffleSimilarActivities,
                ),
              ],
            ),
            const Gap(12),

            if (_similarActivities.isEmpty)
              const Text('他の類似遊びが見つかりませんでした')
            else
              Column(
                children: _similarActivities.map((similar) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: CustomCard(
                      padding: const EdgeInsets.all(14),
                      onTap: () {
                        // 類似遊びの個別ページへダイレクト遷移
                        context.pushReplacement(AppRoutes.buildActivityDetailPath(similar.id));
                      },
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryContainer.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.change_circle_rounded,
                              color: AppTheme.secondaryColor,
                            ),
                          ),
                          const Gap(12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  similar.title,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontSize: 16,
                                      ),
                                ),
                                const Gap(2),
                                Text(
                                  '${similar.minAge}〜${similar.maxAge}歳 | ${similar.durationMinutes}分 | ${similar.parentInvolvement.label}',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontSize: 12,
                                        color: AppTheme.textMutedColor,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppTheme.textMutedColor),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

            const Gap(12),
            CustomButton(
              text: '他の候補をシャッフル切り替え',
              icon: Icons.swap_horiz_rounded,
              isOutlined: true,
              onPressed: _shuffleSimilarActivities,
            ),
            const Gap(40),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: AppTheme.primaryContainer.withOpacity(0.3),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.palette_rounded,
              size: 56,
              color: AppTheme.primaryColor,
            ),
            Gap(8),
            Text(
              'あそび・運動イラスト',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
