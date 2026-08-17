import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';

abstract class UserRepository {
  Future<UserProfile?> getUserProfile(String uid);
  Future<void> updateUserProfile(UserProfile profile);
}

class FirestoreUserRepository implements UserRepository {
  UserProfile? _cacheProfile = const UserProfile(
    uid: 'user_demo_123',
    displayName: '山田 太郎（保護者）',
    email: 'taro.yamada@example.com',
    defaultChildAge: 6,
    defaultParticipantCount: 2,
  );

  @override
  Future<UserProfile?> getUserProfile(String uid) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _cacheProfile;
  }

  @override
  Future<void> updateUserProfile(UserProfile profile) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _cacheProfile = profile;
  }
}

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return FirestoreUserRepository();
});
