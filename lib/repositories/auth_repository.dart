import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';

/// 認証状態クラス
class AuthState {
  final bool isAuthenticated;
  final UserProfile? user;
  final String? errorMessage;

  const AuthState({
    required this.isAuthenticated,
    this.user,
    this.errorMessage,
  });

  factory AuthState.unauthenticated() {
    return const AuthState(isAuthenticated: false);
  }

  factory AuthState.authenticated(UserProfile user) {
    return AuthState(isAuthenticated: true, user: user);
  }
}

/// 認証リポジトリのインターフェース
abstract class AuthRepository {
  Stream<AuthState> get authStateChanges;
  Future<UserProfile> signInWithGoogle();
  Future<UserProfile> signInWithApple();
  Future<void> signOut();
  UserProfile? get currentUser;
}

/// Firebase Auth Mock/Real 統合 AuthRepository 実装
class FirebaseAuthRepository implements AuthRepository {
  // 初期デモユーザー
  static const _demoUser = UserProfile(
    uid: 'user_demo_123',
    displayName: '山田 太郎（保護者）',
    email: 'taro.yamada@example.com',
    defaultChildAge: 6,
    defaultParticipantCount: 2,
    createdAt: '2026-08-01',
  );

  UserProfile? _currentUser = _demoUser;

  @override
  Stream<AuthState> get authStateChanges async* {
    if (_currentUser != null) {
      yield AuthState.authenticated(_currentUser!);
    } else {
      yield AuthState.authenticated(_demoUser);
    }
  }

  @override
  Future<UserProfile> signInWithGoogle() async {
    // Google SignIn Logic (Mock or Firebase Auth)
    await Future.delayed(const Duration(milliseconds: 600));
    _currentUser = _demoUser;
    return _demoUser;
  }

  @override
  Future<UserProfile> signInWithApple() async {
    // Apple SignIn Logic
    await Future.delayed(const Duration(milliseconds: 600));
    _currentUser = _demoUser;
    return _demoUser;
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
  }

  @override
  UserProfile? get currentUser => _currentUser;
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository();
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});
