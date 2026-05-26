# Riverpod 3.0 移行ガイド

このドキュメントは、Legacy API（StateNotifierProvider、StateProvider）からRiverpod 3.0のNotifier APIへの移行手順を説明します。

## 📋 移行が必要なケース

以下のいずれかを使用している場合、移行が必要です：

1. `StateNotifierProvider`
2. `StateProvider`
3. `FamilyNotifier`（削除済み）
4. `flutter_riverpod/legacy.dart` のインポート

## 🔍 Step 1: Legacy APIの検出

### 検索コマンド

```bash
# StateNotifierProviderの検索
grep -r "StateNotifierProvider" lib/

# StateProviderの検索
grep -r "StateProvider" lib/

# Legacyインポートの検索
grep -r "flutter_riverpod/legacy.dart" lib/
```

### 検出例

```dart
// 検出される例
import 'package:flutter_riverpod/legacy.dart';

class CounterNotifier extends StateNotifier<int> {
  CounterNotifier() : super(0);
  void increment() => state++;
}

final counterProvider = StateNotifierProvider<CounterNotifier, int>(
  (ref) => CounterNotifier(),
);
```

## 🔄 Step 2: パターン別の移行方法

### パターン1: StateProvider → NotifierProvider

#### Before（Legacy）
```dart
final selectedTabProvider = StateProvider<int>((ref) => 0);

// Widget内での使用
final selectedTab = ref.watch(selectedTabProvider);
ref.read(selectedTabProvider.notifier).state = 1;
```

#### After（Riverpod 3.0）
```dart
class SelectedTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setTab(int index) {
    state = index;
  }
}

final selectedTabProvider = NotifierProvider<SelectedTabNotifier, int>(
  SelectedTabNotifier.new,
);

// Widget内での使用
final selectedTab = ref.watch(selectedTabProvider);
ref.read(selectedTabProvider.notifier).setTab(1);
```

**変更ポイント:**
- `StateProvider` → `NotifierProvider`
- `Notifier<T>` クラスを作成
- `build()` メソッドで初期値を返す
- 状態更新は専用メソッド（`setTab`）経由

### パターン2: StateNotifierProvider → NotifierProvider

#### Before（Legacy）
```dart
class LocationNotifier extends StateNotifier<LocationState> {
  LocationNotifier() : super(LocationState(isLoading: true)) {
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      state = state.copyWith(position: position, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>(
  (ref) => LocationNotifier(),
);
```

#### After（Riverpod 3.0）
```dart
class LocationNotifier extends Notifier<LocationState> {
  @override
  LocationState build() {
    final initialState = LocationState(isLoading: true);
    _initializeLocation();
    return initialState;
  }

  Future<void> _initializeLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      state = state.copyWith(position: position, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final locationProvider = NotifierProvider<LocationNotifier, LocationState>(
  LocationNotifier.new,
);
```

**変更ポイント:**
- `StateNotifier<T>` → `Notifier<T>`
- コンストラクター削除、`build()` メソッドで初期化
- `StateNotifierProvider` → `NotifierProvider`
- Provider定義が `ClassName.new` に簡潔化

### パターン3: FamilyNotifier（削除済み）→ @riverpod

#### Before（Legacy）
```dart
class UserNotifier extends FamilyNotifier<User, String> {
  @override
  User build(String userId) {
    // 初期化
    return User(id: userId);
  }
}

final userProvider = NotifierProvider.family<UserNotifier, User, String>(
  UserNotifier.new,
);
```

#### After（Riverpod 3.0）
```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_provider.g.dart';

@riverpod
class User extends _$User {
  @override
  UserData build(String userId) {
    // 初期化
    return UserData(id: userId);
  }
}

// 使用例
final user = ref.watch(userProvider('123'));
```

**変更ポイント:**
- `FamilyNotifier` → `@riverpod` アノテーション
- `part` ディレクティブ追加
- `build_runner` でコード生成が必要

## 🛠️ Step 3: call siteの更新

### 読み取り（watch）

#### Before & After（変更なし）
```dart
final value = ref.watch(myProvider);
```

### 状態更新

#### Before（Legacy）
```dart
// 直接.stateアクセス
ref.read(myProvider.notifier).state = newValue;
```

#### After（Riverpod 3.0）
```dart
// 専用メソッド経由
ref.read(myProvider.notifier).setValue(newValue);
```

**警告対処:**
- `direct_state_access` 警告が出る場合は、専用のsetterメソッドを作成
- `.state` への直接アクセスはNotifier内部のみで許可

## ✅ Step 4: 検証

### 1. Lintチェック

```bash
flutter analyze
```

**よくある警告:**
- `direct_state_access` → 専用setterメソッドを作成
- `deprecated_member_use` → Legacy APIをまだ使用している

### 2. テスト実行

```bash
flutter test
```

### 3. 動作確認

- アプリケーションを起動し、移行したProvider周辺の機能を確認
- 状態更新が正しく動作するか確認
- エラーハンドリングが正しく動作するか確認

## 🎯 移行チェックリスト

### Provider作成時
- [ ] `Notifier<T>` または `@riverpod` を使用
- [ ] `StateNotifierProvider`/`StateProvider` を削除
- [ ] `build()` メソッドで初期値を返す
- [ ] コンストラクター引数を削除（`build()` に移行）

### 状態更新時
- [ ] `.state` への直接アクセスを削除
- [ ] 専用のsetterメソッドを作成
- [ ] 非同期処理は `build()` 外で実行

### 検証時
- [ ] `flutter analyze` で警告なし
- [ ] テストがパスする
- [ ] アプリケーションが正常動作する

## 📊 移行の優先順位

### 優先度：高
1. **新規実装**: 必ずNotifier APIを使用
2. **頻繁に変更される箇所**: 早期に移行
3. **バグが報告されている箇所**: 移行時に修正

### 優先度：中
4. **定期的にメンテナンスされる箇所**: 次回変更時に移行
5. **Legacy import使用箇所**: `flutter_riverpod/legacy.dart` 削除

### 優先度：低
6. **安定稼働している箇所**: 大規模リファクタリング時に移行

## 🚨 よくある移行エラー

### エラー1: build()でFutureを返す

```dart
// ❌ 間違い
@override
Future<MyState> build() async {
  return await fetchData();
}
```

**修正:**
```dart
// ✅ 正しい
@override
MyState build() {
  final initialState = MyState(isLoading: true);
  _fetchDataAsync();
  return initialState;
}

Future<void> _fetchDataAsync() async {
  final data = await fetchData();
  state = state.copyWith(data: data, isLoading: false);
}
```

### エラー2: コンストラクターで初期化

```dart
// ❌ 間違い
class MyNotifier extends Notifier<int> {
  MyNotifier() : super(); // コンストラクターは不要

  @override
  int build() => 0;
}
```

**修正:**
```dart
// ✅ 正しい
class MyNotifier extends Notifier<int> {
  @override
  int build() => 0; // build()のみで初期化
}
```

### エラー3: .stateへの外部アクセス

```dart
// ❌ 間違い
ref.read(myProvider.notifier).state = newValue;
```

**修正:**
```dart
// ✅ 正しい: Notifier内に専用メソッド作成
class MyNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setValue(int value) {
    state = value; // Notifier内部でのみ許可
  }
}

// 使用側
ref.read(myProvider.notifier).setValue(newValue);
```

## 🔗 参考リソース

- [Riverpod 3.0 公式マイグレーションガイド](https://riverpod.dev/docs/migration/from_state_notifier)
- [プロジェクト内ガイドライン](../../rules/flutter/riverpod-3-guidelines.md)
- [コード例](./examples/)

## 📝 移行テンプレート

以下のテンプレートを参考に移行してください：

```dart
// Legacy → Riverpod 3.0 移行テンプレート

// ===== Before (Legacy) =====
class MyNotifier extends StateNotifier<MyState> {
  MyNotifier() : super(MyState.initial()) {
    _initialize();
  }

  Future<void> _initialize() async {
    // 初期化処理
  }

  void updateValue(String value) {
    state = state.copyWith(value: value);
  }
}

final myProvider = StateNotifierProvider<MyNotifier, MyState>(
  (ref) => MyNotifier(),
);

// ===== After (Riverpod 3.0) =====
class MyNotifier extends Notifier<MyState> {
  @override
  MyState build() {
    final initialState = MyState.initial();
    _initialize();
    return initialState;
  }

  Future<void> _initialize() async {
    // 初期化処理
  }

  void updateValue(String value) {
    state = state.copyWith(value: value);
  }
}

final myProvider = NotifierProvider<MyNotifier, MyState>(
  MyNotifier.new,
);
```

---

**移行に関する質問がある場合は、プロジェクトのガイドラインまたはRiverpod公式ドキュメントを参照してください。**
