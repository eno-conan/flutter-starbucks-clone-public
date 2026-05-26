// Riverpod 3.0 複雑な状態例: エラーハンドリング付き
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 状態クラス定義
class UserProfileState {
  const UserProfileState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  final UserProfile? user;
  final bool isLoading;
  final String? error;

  // copyWithパターン（不変性を保つ）
  UserProfileState copyWith({
    UserProfile? user,
    bool? isLoading,
    String? error,
  }) {
    return UserProfileState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  // エラー状態のクリア
  UserProfileState clearError() {
    return copyWith(error: null);
  }
}

// ユーザープロフィールモデル
class UserProfile {
  const UserProfile({required this.id, required this.name, required this.email});
  final String id;
  final String name;
  final String email;
}

// ✅ Notifier実装（エラーハンドリング付き）
class UserProfileNotifier extends Notifier<UserProfileState> {
  @override
  UserProfileState build() {
    // 初期状態を返し、非同期で初期化
    final initialState = const UserProfileState(isLoading: true);
    _loadUserProfile();
    return initialState;
  }

  // プライベート: 非同期初期化
  Future<void> _loadUserProfile() async {
    try {
      // 実際はAPIから取得
      await Future<void>.delayed(const Duration(seconds: 1));

      // サンプルデータ
      const user = UserProfile(
        id: '123',
        name: 'テストユーザー',
        email: 'test@example.com',
      );

      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'ユーザー情報の読み込みに失敗しました: $e',
      );
    }
  }

  // パブリック: プロフィール更新
  Future<void> updateProfile({String? name, String? email}) async {
    if (state.user == null) return;

    state = state.copyWith(isLoading: true);

    try {
      // 実際はAPIでPUT/PATCH
      await Future<void>.delayed(const Duration(seconds: 1));

      final updatedUser = UserProfile(
        id: state.user!.id,
        name: name ?? state.user!.name,
        email: email ?? state.user!.email,
      );

      state = state.copyWith(user: updatedUser, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'プロフィール更新に失敗しました: $e',
      );
    }
  }

  // リフレッシュ
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _loadUserProfile();
  }

  // エラークリア
  void clearError() {
    state = state.clearError();
  }
}

// Provider定義
final userProfileProvider =
    NotifierProvider<UserProfileNotifier, UserProfileState>(
  UserProfileNotifier.new,
);

// Widget実装例
class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('User Profile')),
      body: Builder(
        builder: (context) {
          // エラー表示
          if (profileState.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(profileState.error!),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(userProfileProvider.notifier).clearError();
                      ref.read(userProfileProvider.notifier).refresh();
                    },
                    child: Text('再試行'),
                  ),
                ],
              ),
            );
          }

          // ローディング
          if (profileState.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // データ表示
          final user = profileState.user;
          if (user == null) {
            return const Center(child: Text('ユーザー情報が見つかりません'));
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ID: ${user.id}'),
                SizedBox(height: 8),
                Text('名前: ${user.name}'),
                SizedBox(height: 8),
                Text('メール: ${user.email}'),
                SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () async {
                    await ref
                        .read(userProfileProvider.notifier)
                        .updateProfile(name: '更新されたユーザー');
                  },
                  child: Text('プロフィール更新'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
