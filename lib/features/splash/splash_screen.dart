import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../repositories/auth_repository.dart';
import '../../routing/routes.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkInitialAuth();
  }

  Future<void> _checkInitialAuth() async {
    // 一般的なアプリのスプラッシュ表示時間（約1.8秒）
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    try {
      final authRepo = ref.read(authRepositoryProvider);
      if (authRepo.currentUser != null) {
        context.go(AppRoutes.home);
      } else {
        context.go(AppRoutes.home); // ゲストモードとして直接ホームへ案内
      }
    } catch (_) {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor, // #F8F6F1
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // アプリ起動時の全画面公式ロゴ表示 (約1.8秒)
              Image.asset(
                AppConstants.logoBannerPath,
                width: 360,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Column(
                  children: [
                    Image.asset(AppConstants.appIconPath, width: 120),
                    const Gap(16),
                    Text(
                      AppConstants.appName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                    ),
                    const Gap(8),
                    const Text(
                      AppConstants.appSubtitle,
                      style: TextStyle(color: AppTheme.textMutedColor, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Gap(36),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
