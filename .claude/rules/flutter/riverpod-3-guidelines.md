---
paths:
  - "lib/**/*.dart"
  - "lib/provider/**/*"
  - "lib/services/**/*"
---

# Riverpod 3.0 状態管理ガイドライン

このプロジェクトは **Riverpod 3.0** を使用しています。以下の実装パターンとベストプラクティスを必ず遵守してください。

## ✅ Riverpod 3.0 推奨パターン

### 1. 新しい Notifier API の使用

**Notifier を使った状態管理**
```dart
// ✅ 良い例：Riverpod 3.0 の Notifier
class SelectedTabNotifier extends Notifier<int> {
  @override
  int build() {
    return 0; // 初期値
  }
  
  // 状態更新メソッド
  void setTab(int index) {
    state = index;
  }
}

final selectedTabProvider = NotifierProvider<SelectedTabNotifier, int>(
  SelectedTabNotifier.new,
);
```

**複雑な状態を持つ Notifier**
```dart
// ✅ 良い例：複雑な状態管理
class LocationState {
  const LocationState({this.position, this.isLoading = false, this.error});
  
  final Position? position;
  final bool isLoading;
  final String? error;

  LocationState copyWith({Position? position, bool? isLoading, String? error}) {
    return LocationState(
      position: position ?? this.position,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class LocationNotifier extends Notifier<LocationState> {
  @override
  LocationState build() {
    final initialState = LocationState(isLoading: true);
    _initializeLocation(); // 非同期初期化
    return initialState;
  }

  Future<void> _initializeLocation() async {
    try {
      // 位置情報取得ロジック
      final position = await Geolocator.getCurrentPosition();
      state = state.copyWith(position: position, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refreshLocation() async {
    state = state.copyWith(isLoading: true);
    await _initializeLocation();
  }
}

final locationProvider = NotifierProvider<LocationNotifier, LocationState>(
  LocationNotifier.new,
);
```

### 2. riverpod_annotation による関数型Provider

**@riverpod アノテーションの使用**
```dart
// ✅ 良い例：関数型Providerの実装
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_check_provider.g.dart';

/// ネットワーク接続状態をチェックするProvider
@riverpod
Stream<List<ConnectivityResult>> connectivityCheck(Ref ref) {
  return Connectivity().onConnectivityChanged;
}
```

### 3. StreamProvider の実装

**従来のStreamProviderも引き続き使用可能**
```dart
// ✅ 良い例：StreamProviderの使用（既存コード互換性）
final authStateProvider = StreamProvider<User?>((ref) {
  final SupabaseClient supabase = GetIt.instance<SupabaseClient>();
  return supabase.auth.onAuthStateChange
      .map((data) => data.session?.user)
      .handleError((error) {
        // エラーハンドリング
        throw error;
      });
});
```

## ❌ Riverpod 3.0 で避けるべきパターン

### 1. 非推奨となったLegacy API

**StateNotifierProvider の使用は避ける**
```dart
// ❌ 悪い例：StateNotifierProvider (Legacy)
import 'package:flutter_riverpod/legacy.dart'; // Legacy import が必要

class CounterNotifier extends StateNotifier<int> {
  CounterNotifier() : super(0); // コンストラクターが複雑
  
  void increment() => state++;
}

final counterProvider = StateNotifierProvider<CounterNotifier, int>(
  (ref) => CounterNotifier(),
);
```

**StateProvider の直接使用も避ける**
```dart
// ❌ 悪い例：StateProvider (Legacy)
import 'package:flutter_riverpod/legacy.dart';

final selectedTabProvider = StateProvider<int>((ref) => 0);
```

### 2. 旧式の Family Provider

```dart
// ❌ 悪い例：FamilyNotifier (削除済み)
class CounterNotifier extends FamilyNotifier<int, String> {
  @override
  int build(String arg) {
    return 0;
  }
}

// ✅ 良い例：コンストラクターでパラメータを受け取る
class CounterNotifier extends Notifier<int> {
  CounterNotifier(this.initialValue);
  final String initialValue;

  @override
  int build() {
    return int.tryParse(initialValue) ?? 0;
  }
}
```

## 🔄 移行時のチェックポイント

### 1. import文の確認
```dart
// ✅ 正しい import
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

// ❌ 避けるべき import（Legacy機能使用時のみ）
import 'package:flutter_riverpod/legacy.dart';
```

### 2. Provider の定義パターン
```dart
// ✅ Riverpod 3.0 パターン
final provider = NotifierProvider<MyNotifier, MyState>(MyNotifier.new);

// ❌ 旧パターン
final provider = StateNotifierProvider<MyNotifier, MyState>((ref) => MyNotifier());
```

### 3. Ref の使用方法
```dart
// ✅ 簡素化された Ref（型パラメータなし）
class MyNotifier extends Notifier<int> {
  @override
  int build() {
    // ref は自動的に利用可能
    ref.listen(anotherProvider, (prev, next) {
      // リスナー処理
    });
    return 0;
  }
}

// ❌ 旧式の型付きRef（不要）
class MyNotifier extends Notifier<int> {
  @override
  int build() {
    // ref.state++ などは Notifier.state に移動
    state = state + 1; // 直接 state にアクセス
    return 0;
  }
}
```

## 🛠️ プロジェクト固有のベストプラクティス

### 1. ファイル構成
```
lib/provider/
├── auth_state_provider.dart          # StreamProvider
├── connectivity_check_provider.dart  # @riverpod 関数型
├── location_state_provider.dart      # Notifier + 複雑な状態
├── selected_tab_provider.dart        # シンプルな Notifier
└── stores_provider.dart              # データ取得系 Notifier
```

### 2. エラーハンドリングパターン
```dart
// ✅ 推奨：エラー状態を含む State クラス
class LocationState {
  const LocationState({this.position, this.isLoading = false, this.error});
  
  final Position? position;
  final bool isLoading;
  final String? error;

  // エラー状態かどうかを判定
  bool get hasError => error != null;
  bool get isSuccess => !isLoading && error == null && position != null;
}
```

### 3. Provider の命名規則
```dart
// ✅ 推奨命名パターン
final authStateProvider = StreamProvider<User?>(...);      // StreamProvider
final selectedTabProvider = NotifierProvider<...>(...);   // NotifierProvider
final connectivityCheckProvider = StreamProvider<...>(...); // @riverpod で生成
```

## 🚨 移行時によくあるエラーとその対処法

### 1. `StateNotifier` が見つからないエラー
```dart
// エラー: Type 'StateNotifier' not found
// 対処法: Notifier を使用
class MyNotifier extends Notifier<MyState> { // StateNotifier → Notifier
  @override
  MyState build() {
    return MyState(); // super(initialState) → build() で return
  }
}
```

### 2. `StateProvider` が見つからないエラー  
```dart
// エラー: Method not found: 'StateProvider'
// 対処法: NotifierProvider を使用
final myProvider = NotifierProvider<MyNotifier, int>(MyNotifier.new);
```

### 3. **直接的な `.state` アクセス警告の解決**
```dart
// ❌ 警告が発生するパターン: 直接的な state アクセス
ref.read(selectedTabProvider.notifier).state = 3;

// ✅ 推奨解決法: 専用メソッドの定義と使用
class SelectedTabNotifier extends Notifier<int> {
  @override
  int build() {
    return 0;
  }

  // 状態更新用の専用メソッドを追加
  void setTab(int index) {
    state = index;
  }
}

// 使用側：専用メソッドを呼び出し
ref.read(selectedTabProvider.notifier).setTab(3);
```

**この修正が必要な理由:**
- Riverpod 3.0では`.state`への直接アクセスに対して警告が表示される
- 適切な状態更新メソッドを定義することで、意図的な状態変更であることを明確にする
- コードの可読性と保守性が向上する

**修正箇所の確認方法:**
```bash
# 警告が発生するパターンを検索
grep -r "\.notifier).state" lib/
# または
grep -r "\.state =" lib/ | grep notifier
```

### 4. `ProviderObserver` のインターフェース変更
```dart
// ✅ Riverpod 3.0 対応
class MyObserver extends ProviderObserver {
  @override
  void didUpdateProvider(ProviderObserverContext context, Object? value) {
    // context.provider でプロバイダーにアクセス
    // context.container でコンテナにアクセス
  }
  
  @override
  void didDisposeProvider(ProviderObserverContext context) {
    // 単一パラメータでコンテキスト情報にアクセス
  }
}
```

## ⚡ パフォーマンス最適化

### 1. 自動リトライの制御
```dart
// グローバル設定
ProviderScope(
  retry: (retryCount, error) => null, // リトライ無効
  child: MyApp(),
)

// 個別Provider設定
final myProvider = NotifierProvider<MyNotifier, MyState>(
  MyNotifier.new,
  retry: (retryCount, error) => Duration(seconds: retryCount),
);
```

### 2. out-of-view の一時停止制御
```dart
// 一時停止を制御したい場合
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TickerMode(
      enabled: true, // 常に有効にする
      child: Consumer(
        builder: (context, ref, child) {
          final value = ref.watch(myProvider);
          return Text(value.toString());
        },
      ),
    );
  }
}
```

## 📋 実際の修正例（プロジェクト内事例）

### Issue #304 での修正事例
このプロジェクトで実際に発生したRiverpod 3.0警告の修正例です。

**修正対象ファイル:**
- `lib/provider/selected_tab_provider.dart` - Notifierに専用メソッド追加
- `lib/screens/starbucks_user_side/home/widgets/mobileorder.dart`
- `lib/screens/starbucks_user_side/map/main.dart`  
- `lib/screens/starbucks_user_side/mobileorder_pay/store/tab_map/store_map.dart`
- `lib/screens/starbucks_user_side/mobileorder_pay/tab_histories/histories.dart`
- `lib/screens/starbucks_user_side/signup/signup.dart`

**修正パターン1: SelectedTabProvider**
```dart
// 修正前の問題パターン
ref.read(selectedTabProvider.notifier).state = 3;
ref.read(selectedTabProvider.notifier).state = 0;

// 修正後: 専用メソッドの使用
ref.read(selectedTabProvider.notifier).setTab(3);
ref.read(selectedTabProvider.notifier).setTab(0);
```

**修正パターン2: SelectedStoreProvider（既存メソッド活用）**
```dart
// 修正前の問題パターン
ref.read(selectedStoreProvider.notifier).state = store;

// 修正後: 既存の専用プロパティを使用
ref.read(selectedStoreProvider.notifier).store = store;
```

**学んだ教訓:**
1. 各Notifierには適切な状態更新メソッドを定義する
2. 既存の専用メソッド/プロパティがある場合はそれを活用する
3. `.state`への直接アクセスは避け、意図的な更新であることを明確にする
4. 修正時は全ファイルを検索して一貫性を保つ

このガイドラインに従って実装することで、Riverpod 3.0 の機能を最大限活用し、保守性の高い状態管理を実現できます。