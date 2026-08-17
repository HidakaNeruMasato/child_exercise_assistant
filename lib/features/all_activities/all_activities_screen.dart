import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';

import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../models/activity.dart';
import '../../repositories/activity_repository.dart';
import '../../repositories/favorite_repository.dart';
import '../../repositories/auth_repository.dart';
import '../../routing/routes.dart';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/tag_chip.dart';

class AllActivitiesScreen extends ConsumerStatefulWidget {
  const AllActivitiesScreen({super.key});

  @override
  ConsumerState<AllActivitiesScreen> createState() => _AllActivitiesScreenState();
}

class _AllActivitiesScreenState extends ConsumerState<AllActivitiesScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = 'すべて';
  String _searchQuery = '';
  int _displayedCount = 20;
  static const int _pageSize = 20;

  final List<String> _categories = [
    'すべて',
    '鬼ごっこ・かけっこ',
    'ボール・投げ遊び',
    '室内・布団遊び',
    '道具・新聞紙',
    '季節・水遊び',
    '思考・頭脳戦',
    '親子ふれあい',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _loadMore() {
    setState(() {
      _displayedCount += _pageSize;
    });
  }

  List<Activity> _filterActivities(List<Activity> all) {
    return all.where((a) {
      // 1. カテゴリフィルター
      bool categoryMatch = true;
      if (_selectedCategory != 'すべて') {
        switch (_selectedCategory) {
          case '鬼ごっこ・かけっこ':
            categoryMatch = a.title.contains('鬼') ||
                a.title.contains('走') ||
                a.title.contains('ダッシュ') ||
                a.trainableAbilities.contains(AbilityType.stamina);
            break;
          case 'ボール・投げ遊び':
            categoryMatch = a.title.contains('ボール') ||
                a.title.contains('投') ||
                a.toolsRequired.contains('ボール');
            break;
          case '室内・布団遊び':
            categoryMatch = a.isIndoorOk ||
                a.title.contains('布団') ||
                a.title.contains('室内') ||
                a.title.contains('部屋');
            break;
          case '道具・新聞紙':
            categoryMatch = a.toolsRequired.isNotEmpty &&
                !a.toolsRequired.contains('なし（道具不要）');
            break;
          case '季節・水遊び':
            categoryMatch = a.title.contains('水') ||
                a.title.contains('葉') ||
                a.title.contains('雪') ||
                a.title.contains('どんぐり') ||
                a.seasons.length <= 2;
            break;
          case '思考・頭脳戦':
            categoryMatch = a.trainableAbilities.contains(AbilityType.thinking) ||
                a.title.contains('クイズ') ||
                a.title.contains('謎') ||
                a.title.contains('探検');
            break;
          case '親子ふれあい':
            categoryMatch = a.parentInvolvement == ParentInvolvementLevel.active ||
                a.title.contains('抱っこ') ||
                a.title.contains('おんぶ') ||
                a.title.contains('手つなぎ');
            break;
        }
      }

      // 2. キーワード検索
      bool queryMatch = true;
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        queryMatch = a.title.toLowerCase().contains(q) ||
            a.description.toLowerCase().contains(q) ||
            a.toolsRequired.any((t) => t.toLowerCase().contains(q));
      }

      return categoryMatch && queryMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final activitiesAsync = ref.watch(activityRepositoryProvider).getAllActivities();
    final favoriteIds = ref.watch(favoriteRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('遊び・運動ライブラリ（全件表示）'),
      ),
      body: FutureBuilder<List<Activity>>(
        future: activitiesAsync,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('データの読み込みに失敗しました'));
          }

          final allActivities = snapshot.data!;
          final favorites = ref.watch(favoritesStateProvider);
          final filtered = _filterActivities(allActivities);
          final displayed = filtered.take(_displayedCount).toList();
          final hasMore = displayed.length < filtered.length;

          return Column(
            children: [
              // 上部検索＆カテゴリバー
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    // キーワード検索窓
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: '遊び名・道具・キーワードで検索...',
                        prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMutedColor),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                    _displayedCount = _pageSize;
                                  });
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        filled: true,
                        fillColor: AppTheme.backgroundColor,
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                          _displayedCount = _pageSize;
                        });
                      },
                    ),
                    const Gap(10),

                    // カテゴリ切り替えチップ横スクロール
                    SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        separatorBuilder: (_, __) => const Gap(8),
                        itemBuilder: (context, index) {
                          final cat = _categories[index];
                          final isSelected = _selectedCategory == cat;
                          return ChoiceChip(
                            label: Text(cat),
                            selected: isSelected,
                            selectedColor: AppTheme.primaryColor,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : AppTheme.textDarkColor,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedCategory = cat;
                                  _displayedCount = _pageSize;
                                });
                              }
                            },
                          );
                        },
                      ),
                    ),
                    const Gap(8),

                    // 件数ステータスバー
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '該当 ${filtered.length} 件 （${displayed.length} 件を表示中）',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMutedColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (_selectedCategory != 'すべて' || _searchQuery.isNotEmpty)
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(50, 20),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _selectedCategory = 'すべて';
                                _searchQuery = '';
                                _displayedCount = _pageSize;
                              });
                            },
                            child: const Text('リセット', style: TextStyle(fontSize: 12)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // メイン一覧リスト（無限スクロール）
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
                            const Gap(12),
                            const Text(
                              '条件に一致する遊びが見つかりませんでした',
                              style: TextStyle(color: AppTheme.textMutedColor),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: displayed.length + (hasMore ? 1 : 0),
                        separatorBuilder: (_, __) => const Gap(12),
                        itemBuilder: (context, index) {
                          if (index == displayed.length) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.arrow_downward_rounded, size: 18),
                                  label: const Text('さらに読み込む'),
                                  onPressed: _loadMore,
                                ),
                              ),
                            );
                          }

                          final activity = displayed[index];
                          final isFavorite = favorites.any((f) => f.activityId == activity.id);

                          return CustomCard(
                            onTap: () {
                              context.push(AppRoutes.buildActivityDetailPath(activity.id));
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        activity.title,
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                        color: isFavorite ? Colors.red : Colors.grey,
                                      ),
                                      onPressed: () {
                                        final userId = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
                                        ref
                                            .read(favoritesStateProvider.notifier)
                                            .toggleFavorite(userId, activity);
                                      },
                                    ),
                                  ],
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
                                const Gap(10),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    TagChip(
                                      label: '${activity.minAge}〜${activity.maxAge}歳',
                                      icon: Icons.child_care_rounded,
                                    ),
                                    TagChip(
                                      label: '${activity.durationMinutes}分',
                                      icon: Icons.timer_outlined,
                                    ),
                                    TagChip(
                                      label: activity.intensityLevel.label,
                                      icon: Icons.fitness_center_rounded,
                                    ),
                                    TagChip(
                                      label: activity.isIndoorOk ? '屋内OK' : '屋外専用',
                                      icon: activity.isIndoorOk ? Icons.home_rounded : Icons.nature_people_rounded,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
