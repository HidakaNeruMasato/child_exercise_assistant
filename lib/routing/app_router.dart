import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../features/activity_detail/activity_detail_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/favorites/favorites_screen.dart';
import '../features/history/history_screen.dart';
import '../features/home/home_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/recommendation/recommendation_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/splash/splash_screen.dart';
import 'routes.dart';

import '../features/all_activities/all_activities_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      // 全主要ページで最下部に固定ナビゲーションバーを表示するShellRoute
      ShellRoute(
        builder: (context, state, child) {
          return MainShellLayout(
            location: state.uri.toString(),
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.recommendations,
            builder: (context, state) => const RecommendationScreen(),
          ),
          GoRoute(
            path: AppRoutes.activityDetail,
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              return ActivityDetailScreen(activityId: id);
            },
          ),
          GoRoute(
            path: AppRoutes.favorites,
            builder: (context, state) => const FavoritesScreen(),
          ),
          GoRoute(
            path: AppRoutes.history,
            builder: (context, state) => const HistoryScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: AppRoutes.allActivities,
            builder: (context, state) => const AllActivitiesScreen(),
          ),
        ],
      ),
    ],
  );
});

/// 画面最下部に固定される常時ナビゲーションバー構成レイアウト
class MainShellLayout extends StatelessWidget {
  final String location;
  final Widget child;

  const MainShellLayout({
    super.key,
    required this.location,
    required this.child,
  });

  int _calculateSelectedIndex(String loc) {
    if (loc.startsWith(AppRoutes.home)) return 0;
    if (loc.startsWith(AppRoutes.recommendations) || loc.startsWith(AppRoutes.allActivities)) return 1;
    if (loc.startsWith(AppRoutes.favorites)) return 2;
    if (loc.startsWith(AppRoutes.history)) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
        break;
      case 1:
        context.go(AppRoutes.recommendations);
        break;
      case 2:
        context.go(AppRoutes.favorites);
        break;
      case 3:
        context.go(AppRoutes.history);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _calculateSelectedIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: AppTheme.textMutedColor,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedFontSize: 12,
          unselectedFontSize: 11,
          onTap: (index) => _onItemTapped(index, context),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              activeIcon: Icon(Icons.home_rounded, color: AppTheme.primaryColor),
              label: 'ホーム',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_rounded),
              activeIcon: Icon(Icons.search_rounded, color: AppTheme.primaryColor),
              label: '探す',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_rounded),
              activeIcon: Icon(Icons.favorite_rounded, color: AppTheme.primaryColor),
              label: 'お気に入り',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_rounded),
              activeIcon: Icon(Icons.history_rounded, color: AppTheme.primaryColor),
              label: '記録',
            ),
          ],
        ),
      ),
    );
  }
}
