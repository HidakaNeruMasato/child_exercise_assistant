import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../core/theme/app_theme.dart';
import '../../models/user_profile.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/user_repository.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/custom_card.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late int _childAge;
  late int _participantCount;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authRepositoryProvider).currentUser;
    _childAge = user?.defaultChildAge ?? 6;
    _participantCount = user?.defaultParticipantCount ?? 2;
  }

  Future<void> _saveProfile() async {
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);
    final updated = UserProfile(
      uid: user.uid,
      displayName: user.displayName,
      email: user.email,
      photoUrl: user.photoUrl,
      defaultChildAge: _childAge,
      defaultParticipantCount: _participantCount,
      createdAt: user.createdAt,
    );

    await ref.read(userRepositoryProvider).updateUserProfile(updated);

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('お子様の設定を保存しました！')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authRepositoryProvider).currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('マイページ・プロフィール'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: AppTheme.primaryContainer,
                child: const Icon(Icons.person_rounded, size: 50, color: AppTheme.primaryColor),
              ),
            ),
            const Gap(12),
            Text(
              user?.displayName ?? '保護者さま',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              user?.email ?? '',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textMutedColor,
                  ),
            ),
            const Gap(24),

            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'デフォルトのあそび設定',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Gap(16),

                  Row(
                    children: [
                      Text('子どもの基本年齢: $_childAge 歳',
                          style: Theme.of(context).textTheme.bodyLarge),
                      Expanded(
                        child: Slider(
                          value: _childAge.toDouble(),
                          min: 2,
                          max: 12,
                          divisions: 10,
                          label: '$_childAge歳',
                          onChanged: (val) => setState(() => _childAge = val.round()),
                        ),
                      ),
                    ],
                  ),
                  const Gap(12),

                  Row(
                    children: [
                      Text('基本参加人数: $_participantCount 人',
                          style: Theme.of(context).textTheme.bodyLarge),
                      Expanded(
                        child: Slider(
                          value: _participantCount.toDouble(),
                          min: 1,
                          max: 8,
                          divisions: 7,
                          label: '$_participantCount人',
                          onChanged: (val) => setState(() => _participantCount = val.round()),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Gap(24),

            CustomButton(
              text: '設定内容を保存する',
              onPressed: _saveProfile,
              isLoading: _isSaving,
            ),
          ],
        ),
      ),
    );
  }
}
