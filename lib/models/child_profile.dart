import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 兄弟・姉妹のお子さまプロフィールモデル
class ChildProfile {
  final String id;
  final String name; // 名前 (例: "たろう")
  final int age; // 年齢
  final String emoji; // アイコン絵文字 (例: "👦", "👧", "👶")

  const ChildProfile({
    required this.id,
    required this.name,
    required this.age,
    this.emoji = '👦',
  });

  ChildProfile copyWith({
    String? id,
    String? name,
    int? age,
    String? emoji,
  }) {
    return ChildProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      emoji: emoji ?? this.emoji,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'emoji': emoji,
    };
  }

  factory ChildProfile.fromJson(Map<String, dynamic> json) {
    return ChildProfile(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'お子さま',
      age: (json['age'] as num?)?.toInt() ?? 6,
      emoji: json['emoji'] as String? ?? '👦',
    );
  }
}

/// 登録されているお子さまリストStateNotifier
final childrenProfilesProvider =
    StateNotifierProvider<ChildrenProfilesNotifier, List<ChildProfile>>((ref) {
  return ChildrenProfilesNotifier();
});

class ChildrenProfilesNotifier extends StateNotifier<List<ChildProfile>> {
  ChildrenProfilesNotifier()
      : super(const [
          ChildProfile(id: 'child_1', name: 'たろう', age: 6, emoji: '👦'),
          ChildProfile(id: 'child_2', name: 'はなこ', age: 4, emoji: '👧'),
          ChildProfile(id: 'child_3', name: 'じろう', age: 2, emoji: '👶'),
        ]);

  /// 無料枠制限（初期最大3人まで）
  static const int maxFreeChildren = 3;

  void updateChild(ChildProfile child) {
    state = state.map((c) => c.id == child.id ? child : c).toList();
  }

  bool addChild(String name, int age, String emoji) {
    if (state.length >= maxFreeChildren) {
      return false; // 最大3人制限
    }
    final newChild = ChildProfile(
      id: 'child_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      age: age,
      emoji: emoji,
    );
    state = [...state, newChild];
    return true;
  }

  void removeChild(String id) {
    if (state.length <= 1) return; // 最低1人は保持
    state = state.where((c) => c.id != id).toList();
  }
}
