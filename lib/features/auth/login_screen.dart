import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../repositories/auth_repository.dart';
import '../../routing/routes.dart';
import '../../shared/widgets/custom_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signInWithGoogle();
      if (mounted) {
        context.go(AppRoutes.home);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ログインに失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAppleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signInWithApple();
      if (mounted) {
        context.go(AppRoutes.home);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ログインに失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.child_care_rounded,
                  size: 60,
                  color: AppTheme.primaryColor,
                ),
              ),
              const Gap(24),
              Text(
                AppConstants.appName,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 26,
                      color: AppTheme.textDarkColor,
                    ),
                textAlign: TextAlign.center,
              ),
              const Gap(12),
              Text(
                '保護者の方専用の運動・遊び提案アプリです。\nお子様との毎日の遊び選びをスムーズにサポートします。',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textMutedColor,
                    ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              CustomButton(
                text: 'Googleアカウントでログイン',
                icon: Icons.g_mobiledata_rounded,
                onPressed: _handleGoogleSignIn,
                isLoading: _isLoading,
              ),
              const Gap(16),
              CustomButton(
                text: 'Apple IDでサインイン',
                icon: Icons.apple_rounded,
                isOutlined: true,
                onPressed: _handleAppleSignIn,
                isLoading: _isLoading,
              ),
              const Gap(20),
              Text(
                '※当アプリはセキュリティと保護者確認のため、\n匿名ログインは非対応となっております。',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                      color: AppTheme.textMutedColor,
                    ),
                textAlign: TextAlign.center,
              ),
              const Gap(16),
            ],
          ),
        ),
      ),
    );
  }
}
