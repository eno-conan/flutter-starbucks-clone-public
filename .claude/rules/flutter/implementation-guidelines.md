---
paths:
  - "lib/**/*.dart"
  - "lib/screens/**/*"
  - "lib/shared/widgets/**/*"
---

# 実装ガイドライン・推奨パターン

## コード実装時とレビュー時にチェックしてほしい箇所

### Widget設計の基本原則

- 他クラスからimportしない`StatelessWidget`はprivateにすること
    ```dart
    class MyHomeScreen extends StatelessWidget {
    const MyHomeScreen({super.key});

    @override
    Widget build(BuildContext context) {
        return Column(
        mainAxisAlignment: .center,
        children: const [
            HelloText(name: 'Flutter'), // 外部Widget
            SizedBox(height: 16),
            _LocalMessage(), // プライベートWidget
        ],
        );
    }
    }

    // このファイル内でしか使われないWidget（プライベート）
    class _LocalMessage extends StatelessWidget {
    const _LocalMessage();

    @override
    Widget build(BuildContext context) {
        return Text(
        'This is a private widget',
        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        );
    }
    }
    ```

### ドキュメンテーション要件

- 他クラスからimportされるWidgetにはドキュメンテーションコメントがあること
- プライベートクラスは、通常のコメント（`//`）でいいので、Widgetの説明があること

```dart
/// MyHomeScreen is a simple stateless widget that displays
/// a greeting message and a private informational widget.
/// 
/// It demonstrates the use of both an imported public widget
/// (`HelloText`) and a private widget (`_LocalMessage`) defined
/// in the same file.
class MyHomeScreen extends StatelessWidget {
  const MyHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: .center,
      children: const [
        // Public widget imported from another file
        HelloText(name: 'Flutter'),

        SizedBox(height: 16),

        // Private widget used only in this file
        _LocalMessage(),
      ],
    );
  }
}
```

## ✅ 推奨する実装パターン

### 1. Riverpod初期化パターン

**パターン1: didChangeDependenciesを使用**
```dart
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  
  // ✅ didChangeDependencies内ではref.watch()が使用可能
  final someProvider = ref.watch(someProvider);
  _handleProviderData(someProvider);
}
```

**パターン2: PostFrameCallbackを使用**
```dart
@override
void initState() {
  super.initState();
  
  // ✅ ビルド完了後に実行
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final someProvider = ref.watch(someProvider);
    _handleProviderData(someProvider);
  });
}
```

**パターン3: Future.microtaskを使用**
```dart
@override
void initState() {
  super.initState();
  
  // ✅ 次のマイクロタスクで実行
  Future.microtask(() {
    final someProvider = ref.watch(someProvider);
    _handleProviderData(someProvider);
  });
}
```

### 2. コードの可読性・保守性を向上させる書き方

**定数の適切な定義**
```dart
// ✅ 良い例
class AppConstants {
  static const double defaultContainerHeight = 200;
  static const double defaultContainerWidth = 300;
  static const Color primaryBlue = Color(0xFF4A90E2);
  static const EdgeInsets defaultPadding = .all(16);
}

Widget build(BuildContext context) {
  return Container(
    height: AppConstants.defaultContainerHeight,
    width: AppConstants.defaultContainerWidth,
    color: AppConstants.primaryBlue,
    padding: AppConstants.defaultPadding,
  );
}
```

**名前付き定数の使用**
```dart
// ✅ 良い例
class Priority {
  static const int low = 1;
  static const int normal = 3;
  static const int high = 5;
  static const int critical = 8;
}

for (final item in items) {
  if (item.priority > Priority.high) {
    processHighPriorityItem(item);
  }
}
```

**Early returnパターンの使用**
```dart
// ✅ 良い例
Widget build(BuildContext context) {
  if (user == null) return UnauthorizedView();
  if (!user.isActive) return InactiveUserView();
  if (!user.hasPermission) return NoPermissionView();
  if (!user.isVerified) return UnverifiedView();
  
  return AdminPanel();
}
```

### 3. State管理・パフォーマンスを改善する書き方

**BuildContextの安全な使用**
```dart
// ✅ 良い例
Future<void> _loadData() async {
  await Future<void>.delayed(Duration(seconds: 2));
  
  if (!mounted) return; // mountedチェック
  
  if (context.mounted) { // さらに安全にチェック
    Navigator.of(context).pushNamed('/home');
  }
}
```

**効率的なsetStateの使用**
```dart
// ✅ 良い例
void _updateCounter() {
  setState(() {
    counter += 1;
    lastUpdated = DateTime.now(); // 関連する状態をまとめて更新
  });
}
```

**constコンストラクターの活用**
```dart
// ✅ 良い例
class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
  });
  
  final String text;
  final VoidCallback onPressed;
  
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(text),
    );
  }
}

// 使用時
const CustomButton(
  text: 'Submit',
  onPressed: _onSubmit,
)
```

### 4. 堅牢なエラーハンドリング

**Result型パターンの使用**
```dart
// ✅ 良い例
class Result<T> {
  const Result.success(this.data) : error = null;
  const Result.failure(this.error) : data = null;
  
  final T? data;
  final String? error;
  
  bool get isSuccess => error == null;
  bool get isFailure => error != null;
}

Future<Result<UserData>> fetchUser() async {
  try {
    final result = await api.fetchData();
    return Result.success(result);
  } catch (e) {
    logger.error('Failed to fetch user: $e');
    return Result.failure('データの取得に失敗しました');
  }
}
```

**型安全なデータアクセス**
```dart
// ✅ 良い例
class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
  });
  
  final int id;
  final String name;
  final String email;
  
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }
}
```

### 5. Widget設計のベストプラクティス

**単一責任の原則に従ったWidget設計**
```dart
// ✅ 良い例：責任を分割
class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key, required this.user});
  
  final User user;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _UserAvatar(user: user),
          _UserInfo(user: user),
          _UserActions(user: user),
        ],
      ),
    );
  }
  
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text('${user.name}のプロフィール'),
    );
  }
}

// プライベートWidgetとして分割
class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.user});
  final User user;
  
  @override
  Widget build(BuildContext context) {
    // アバター表示のロジック
  }
}
```

**拡張可能なテーマ設計**
```dart
// ✅ 良い例
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
      ),
      textTheme: _textTheme,
      elevatedButtonTheme: _elevatedButtonTheme,
    );
  }
  
  static const TextTheme _textTheme = TextTheme(
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      height: 1.5,
    ),
  );
  
  static ElevatedButtonThemeData get _elevatedButtonTheme {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(120, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
```

## ベストプラクティス

1. **初期化処理は`didChangeDependencies()`で行う**
2. **一度だけ実行したい場合は、フラグを使用して重複実行を防ぐ**
3. **ビルド後の処理は`PostFrameCallback`を使用**
4. **状態管理の処理は可能な限り`build()`メソッド内で行う**

```dart
class _MyWidgetState extends ConsumerState<MyWidget> {
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // 一度だけ実行
    if (!_isInitialized) {
      final someProvider = ref.watch(someProvider);
      _handleInitialization(someProvider);
      _isInitialized = true;
    }
  }
}
```

## 理由

- `initState()`内では、まだWidgetツリーが完全に構築されていないため、InheritedWidget（Riverpodが内部で使用）にアクセスできません
- `ref.watch()`、`ref.read()`、`ref.listen()`はすべてInheritedWidgetに依存するため、`initState()`完了前には使用できません

## 🔍 コードレビュー時のチェックポイント

### 必須チェック項目
1. **型安全性**: nullチェック、型キャストの適切性
2. **リソース管理**: dispose()の実装、メモリリークの有無
3. **パフォーマンス**: 不要な再ビルド、重い処理の最適化
4. **アクセシビリティ**: Semanticsの適切な設定
5. **テスタビリティ**: 依存性注入、モックしやすい設計

### 推奨チェック項目
1. **コードの一貫性**: プロジェクト全体のスタイル統一
2. **ドキュメント**: 複雑なロジックのコメント
3. **エラーメッセージ**: ユーザーフレンドリーなメッセージ
4. **ローカライゼーション**: ハードコーディングされた文字列の有無
5. **セキュリティ**: 機密情報の適切な処理