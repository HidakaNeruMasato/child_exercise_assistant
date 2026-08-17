import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/favorite_repository.dart';
import '../../routing/routes.dart';
import '../../shared/widgets/custom_card.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final user = ref.read(authRepositoryProvider).currentUser;
      ref.read(favoritesStateProvider.notifier).loadFavorites(user?.uid ?? 'user_demo_123');
    });
  }

  @override
  Widget build(BuildContext context) {
    final favorites = ref.watch(favoritesStateProvider);
    final user = ref.watch(authRepositoryProvider).currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('お気に入りした遊び'),
      ),
      body: favorites.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border_rounded,
                      size: 64, color: AppTheme.textMutedColor.withOpacity(0.5)),
                  const Gap(16),
                  Text(
                    'まだお気に入りした遊びがありません',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.textMutedColor,
                        ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: favorites.length,
              separatorBuilder: (_, __) => const Gap(16),
              itemBuilder: (context, index) {
                final fav = favorites[index];
                final activity = fav.activity;

                return CustomCard(
                  onTap: () {
                    context.push(AppRoutes.buildActivityDetailPath(activity.id));
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.sports_kabaddi_rounded,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const Gap(16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activity.title,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const Gap(4),
                            Text(
                              '${activity.minAge}〜${activity.maxAge}歳 | ${activity.durationMinutes}分',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textMutedColor,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.favorite_rounded, color: AppTheme.primaryColor),
                        onPressed: () {
                          if (user != null) {
                            ref
                                .read(favoritesStateProvider.notifier)
                                .toggleFavorite(user.uid, activity);
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
