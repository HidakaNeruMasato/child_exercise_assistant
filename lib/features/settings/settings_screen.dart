import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../repositories/auth_repository.dart';
import '../../routing/routes.dart';

import '../../models/child_profile.dart';
import '../../models/notification_settings.dart';
import '../../repositories/history_repository.dart';
import '../../services/notification_service.dart';
import '../../shared/widgets/feedback_dialog.dart';

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

  void _showAddOrEditChildDialog(BuildContext context, WidgetRef ref, [ChildProfile? existingChild]) {
    final isEditing = existingChild != null;
    final nameController = TextEditingController(text: isEditing ? existingChild.name : '');
    int age = isEditing ? existingChild.age : 5;
    String selectedEmoji = isEditing ? existingChild.emoji : '👦';

    final emojis = ['👦', '👧', '👶', '🧒', '🧒‍♂️', '🧒‍♀️'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.face_rounded, color: AppTheme.primaryColor),
                  const Gap(8),
                  Text(isEditing ? 'お子さま情報の変更' : 'お子さまの追加'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 名前入力
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'お名前（またはニックネーム）',
                        hintText: '例: たろう',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const Gap(16),

                    // 年齢選択
                    Text(
                      '年齢: 【 $age 歳 】',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                    ),
                    Slider(
                      value: age.toDouble(),
                      min: 1,
                      max: 12,
                      divisions: 11,
                      label: '$age歳',
                      activeColor: AppTheme.primaryColor,
                      onChanged: (val) {
                        setDialogState(() => age = val.round());
                      },
                    ),
                    const Gap(12),

                    // アイコン絵文字選択
                    const Text('アイコン絵文字:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const Gap(8),
                    Wrap(
                      spacing: 10,
                      children: emojis.map((emoji) {
                        final isSelected = selectedEmoji == emoji;
                        return InkWell(
                          onTap: () => setDialogState(() => selectedEmoji = emoji),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primaryContainer : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Text(emoji, style: const TextStyle(fontSize: 24)),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('キャンセル'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    final notifier = ref.read(childrenProfilesProvider.notifier);
                    if (isEditing) {
                      notifier.updateChild(existingChild.copyWith(name: name, age: age, emoji: selectedEmoji));
                    } else {
                      notifier.addChild(name, age, selectedEmoji);
                    }
                    Navigator.pop(context);
                  },
                  child: Text(isEditing ? '保存する' : '追加する'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showChildrenManagementModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final children = ref.watch(childrenProfilesProvider);
            final notifier = ref.read(childrenProfilesProvider.notifier);

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
                      Row(
                        children: [
                          const Icon(Icons.child_care_rounded, color: AppTheme.primaryColor, size: 28),
                          const Gap(8),
                          Text(
                            'お子さまプロフィールの管理',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Gap(8),
                  Text(
                    '登録人数: ${children.length}人 / 無料枠上限: 3人 (プレミアムで最大6人まで拡張可能)',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMutedColor),
                  ),
                  const Gap(16),

                  // お子さまリスト表示（最大6人まで余裕を持ったカード表示レイアウト）
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 320),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: children.length,
                      separatorBuilder: (_, __) => const Gap(10),
                      itemBuilder: (context, index) {
                        final item = children[index];
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryContainer.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                                ),
                                child: Text(item.emoji, style: const TextStyle(fontSize: 24)),
                              ),
                              const Gap(12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${item.name} ちゃん',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '${item.age} 歳',
                                      style: const TextStyle(fontSize: 12, color: AppTheme.textMutedColor),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_rounded, color: AppTheme.primaryColor, size: 20),
                                tooltip: '編集',
                                onPressed: () => _showAddOrEditChildDialog(context, ref, item),
                              ),
                              if (children.length > 1)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                  tooltip: '削除',
                                  onPressed: () => notifier.removeChild(item.id),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const Gap(16),

                  // 追加ボタン ＆ 有料版案内
                  if (children.length < ChildrenProfilesNotifier.maxFreeChildren) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.person_add_rounded),
                        label: Text('＋ お子さまを追加 (${children.length}/3人・無料枠)'),
                        onPressed: () => _showAddOrEditChildDialog(context, ref),
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade400),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 28),
                          const Gap(10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '無料枠上限 (3名) に達しています',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                Text(
                                  'プレミアムプラン（有料版）で最大6名まで個別拡張できます✨',
                                  style: TextStyle(fontSize: 11, color: Colors.brown),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: const Size(60, 30),
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('プレミアム機能（最大6名登録）は将来のアップデートで提供予定です！')),
                              );
                            },
                            child: const Text('詳細', style: TextStyle(fontSize: 11)),
                          ),
                        ],
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
            leading: const Icon(Icons.child_care_rounded, color: AppTheme.primaryColor),
            title: const Text('お子さまプロフィールの管理'),
            subtitle: Text(
              '登録中: ${ref.watch(childrenProfilesProvider).map((c) => "${c.name}(${c.age}歳)").join("・")} (無料枠最大3名)',
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showChildrenManagementModal(context, ref),
          ),
          const Divider(),
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
            leading: const Icon(Icons.rate_review_rounded, color: AppTheme.primaryColor),
            title: const Text('アプリへのご意見・ご要望（フィードバック）'),
            subtitle: const Text('使い勝手や新機能のご要望をお聞かせください'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => FeedbackDialog.showAppFeedback(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.dashboard_customize_rounded, color: AppTheme.secondaryColor),
            title: const Text('フィードバック管理ダッシュボード'),
            subtitle: const Text('ユーザーの評価・ご意見・満足度統計の集計'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(AppRoutes.feedbackDashboard),
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
            subtitle: const Text('${AppConstants.appName} v2.0'),
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
