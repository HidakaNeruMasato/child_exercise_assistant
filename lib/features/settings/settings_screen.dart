import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../repositories/auth_repository.dart';
import '../../routing/routes.dart';

import '../../models/notification_settings.dart';
import '../../repositories/history_repository.dart';
import '../../services/notification_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showNotificationSettingsModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final settings = ref.watch(notificationSettingsProvider);
            final notifier = ref.read(notificationSettingsProvider.notifier);

            return Padding(
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '未運動リマインダー設定',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Gap(16),

                  // ON / OFF トグルスイッチ
                  SwitchListTile(
                    title: const Text('未運動リマインダーを有効にする'),
                    subtitle: Text(
                      settings.isEnabled ? '新しい遊びの記録がない場合に通知します' : '現在リマインダー通知はOFFです',
                      style: TextStyle(
                        fontSize: 12,
                        color: settings.isEnabled ? AppTheme.primaryColor : AppTheme.textMutedColor,
                      ),
                    ),
                    value: settings.isEnabled,
                    activeColor: AppTheme.primaryColor,
                    onChanged: (val) {
                      notifier.toggleEnabled(val);
                    },
                  ),
                  const Divider(),
                  const Gap(8),

                  if (settings.isEnabled) ...[
                    Text(
                      'あそびの記録がない日数の閾値:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Gap(4),
                    Text(
                      '【 ${settings.inactiveDaysThreshold} 日間 】新しい遊びの記録がない場合に通知',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                        fontSize: 15,
                      ),
                    ),
                    Slider(
                      value: settings.inactiveDaysThreshold.toDouble(),
                      min: 1,
                      max: 14,
                      divisions: 13,
                      label: '${settings.inactiveDaysThreshold}日',
                      activeColor: AppTheme.primaryColor,
                      onChanged: (val) {
                        notifier.setInactiveDays(val.round());
                      },
                    ),
                    const Gap(12),

                    // 通知プレビューカード
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.notifications_active_rounded, color: AppTheme.primaryColor),
                          const Gap(12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '通知文面プレビュー:',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMutedColor),
                                ),
                                const Gap(2),
                                Text(
                                  '最後にあそんでから ${settings.inactiveDaysThreshold} 日が経過しました！最近のお子様の気分に合わせたおすすめの遊びはいかがですか？🌸',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textDarkColor),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(16),

                    // テスト用通知エミュレートボタン
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.notifications_outlined, size: 18),
                        label: const Text('リマインダー通知をテスト確認'),
                        onPressed: () async {
                          final result = await ref.read(reminderServiceProvider).checkReminder();
                          if (!context.mounted) return;
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Row(
                                children: [
                                  Icon(Icons.notifications_active_rounded, color: AppTheme.primaryColor),
                                  Gap(8),
                                  Text('通知テスト'),
                                ],
                              ),
                              content: Text(result.message),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const Gap(24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(notificationSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('アプリ設定'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ListTile(
            leading: const Icon(Icons.library_books_rounded, color: AppTheme.primaryColor),
            title: const Text('すべての遊び・運動ライブラリ'),
            subtitle: const Text('全200件の遊びをカテゴリ別・検索で見る'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              context.push(AppRoutes.allActivities);
            },
          ),
          ListTile(
            leading: const Icon(Icons.family_restroom_rounded, color: AppTheme.primaryColor),
            title: const Text('家族間で共有（ファミリー合言葉）'),
            subtitle: Text('合言葉: 【 ${ref.watch(familyIdProvider)} 】 (個人情報不要)'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              context.push(AppRoutes.history);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.notifications_rounded, color: AppTheme.primaryColor),
            title: const Text('未運動リマインダー・通知設定'),
            subtitle: Text(
              settings.isEnabled
                  ? 'ON (${settings.inactiveDaysThreshold}日間 記録なしで通知)'
                  : 'OFF (通知は送られません)',
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showNotificationSettingsModal(context, ref),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.privacy_tip_rounded, color: AppTheme.primaryColor),
            title: const Text('プライバシーポリシー'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.description_rounded, color: AppTheme.primaryColor),
            title: const Text('利用規約'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_rounded, color: AppTheme.primaryColor),
            title: const Text('アプリ情報'),
            subtitle: const Text('バージョン 1.0.0 (Clean Architecture)'),
          ),
          const Gap(32),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('ログアウト'),
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) {
                context.go(AppRoutes.login);
              }
            },
          ),
        ],
      ),
    );
  }
}
