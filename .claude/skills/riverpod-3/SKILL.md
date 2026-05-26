---
name: riverpod-3
description: |
  Riverpod 3.0のNotifier API実装パターン。StateNotifierProvider/StateProviderからの移行、
  新規Provider作成時に使用。Legacy API（StateNotifierProvider、StateProvider）は非推奨。
  トリガーワード: riverpod, provider, notifier, 状態管理, StateNotifierProvider, StateProvider, 移行, @riverpod
  典型的なユーザー質問: "Providerを作成したい", "StateNotifierProviderを移行したい", "Riverpod 3.0の書き方を教えて"
  【対象外】: データベース設計、UIデザイン、ビジネスロジックの実装
user-invocable: true
disable-model-invocation: false
allowed-tools: Read, Grep
license: MIT
compatibility: |
  - Flutter SDK 3.0+
  - Riverpod 3.0+
metadata:
  author: flutter-starbucks-clone
  version: 1.0.0
  last-updated: 2025-02-11
argument-hint: [action] [provider-type]
---

# Riverpod 3.0 実装スキル

このスキルは、Riverpod 3.0の**Notifier API**を使った状態管理の実装パターンを提供します。

## 📋 使用場面

- 新規Providerの作成
- Legacy API（StateNotifierProvider、StateProvider）からの移行
- 複雑な状態管理の実装
- 非同期処理を含むProviderの実装

## 引数による実行

このスキルは引数をサポートしています。

**基本形式**: `/riverpod-3 [action] [provider-type]`

**引数**:
- `$1` (action): 実行するアクション
  - `create` - 新規Provider作成
  - `migrate` - Legacy APIからの移行
  - `check` - Legacy API使用箇所の検出
- `$2` (provider-type): Providerの種類（オプション）
  - `simple` - シンプルなNotifier
  - `complex` - 複雑な状態を持つNotifier
  - `async` - 非同期処理を含むNotifier

**実行例**:
```bash
# Legacy API使用箇所を検出
/riverpod-3 check

# StateNotifierProviderからの移行手順を提示
/riverpod-3 migrate

# 新規Provider作成（非同期処理を含む）
/riverpod-3 create async
```

## ✅ 基本パターン

**Legacy API使用箇所**: !`grep -rE "StateNotifierProvider|StateProvider" lib/ | wc -l`

**Notifier API使用箇所**: !`grep -r "NotifierProvider" lib/ | wc -l`

**Riverpodバージョン**: !`grep "riverpod:" pubspec.yaml`

**StateNotifierProvider詳細**: !`grep -r "StateNotifierProvider" lib/`

### 1. シンプルなNotifier

```dart
class SelectedTabNotifier extends Notifier<int> {
  @override
  int build() => 0; // 初期値

  void setTab(int index) {
    state = index;
  }
}

final selectedTabProvider = NotifierProvider<SelectedTabNotifier, int>(
  SelectedTabNotifier.new,
);
```

**使用例:**
```dart
// Widget内での使用
final selectedTab = ref.watch(selectedTabProvider);

// 状態更新
ref.read(selectedTabProvider.notifier).setTab(1);
```

### 2. 複雑な状態を持つNotifier

```dart
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

  Future<void> refreshLocation() async {
    state = state.copyWith(isLoading: true);
    await _initializeLocation();
  }
}

final locationProvider = NotifierProvider<LocationNotifier, LocationState>(
  LocationNotifier.new,
);
```

### 3. @riverpod アノテーション（関数型）

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_check_provider.g.dart';

@riverpod
Stream<List<ConnectivityResult>> connectivityCheck(Ref ref) {
  return Connectivity().onConnectivityChanged;
}
```

**ビルドコマンド:**
```bash
dart run build_runner build --delete-conflicting-outputs
```

## ❌ 避けるべきLegacy API

### StateNotifierProvider（非推奨）

```dart
// ❌ 避ける
import 'package:flutter_riverpod/legacy.dart';

class CounterNotifier extends StateNotifier<int> {
  CounterNotifier() : super(0);
  void increment() => state++;
}

final counterProvider = StateNotifierProvider<CounterNotifier, int>(
  (ref) => CounterNotifier(),
);
```

**✅ 正しい移行先:**
```dart
class CounterNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void increment() {
    state++;
  }
}

final counterProvider = NotifierProvider<CounterNotifier, int>(
  CounterNotifier.new,
);
```

### StateProvider（非推奨）

```dart
// ❌ 避ける
final selectedTabProvider = StateProvider<int>((ref) => 0);
```

**✅ 正しい移行先:** 上記のNotifierパターンを使用

## 🔄 移行手順

詳細な移行手順は [`migration-guide.md`](./migration-guide.md) を参照してください。

### クイックステップ

1. **検出**: Legacy APIの使用箇所を検索
   ```bash
   grep -r "StateNotifierProvider\|StateProvider" lib/
   ```

2. **移行**: Notifier APIに書き換え
   - `StateNotifier<T>` → `Notifier<T>`
   - `StateNotifierProvider` → `NotifierProvider`
   - コンストラクター引数削除（`build()`で初期化）

3. **検証**: Lint警告の確認
   ```bash
   flutter analyze
   ```

## 📚 コード例

- [simple-counter.dart](./examples/simple-counter.dart) - 基本的なカウンター実装
- [complex-state.dart](./examples/complex-state.dart) - エラーハンドリング付き状態管理
- [async-operations.dart](./examples/async-operations.dart) - 非同期処理の実装例

## 🔗 詳細ドキュメント

完全なガイドラインは以下を参照:
- [Riverpod 3.0 状態管理ガイドライン](../../rules/flutter/riverpod-3-guidelines.md) - 396行の詳細リファレンス
- [Riverpod 公式ドキュメント](https://riverpod.dev/)

## 🚨 よくある問題

### 問題1: `.state` への直接アクセス警告

```dart
// ❌ 避ける
ref.read(myProvider.notifier).state = newValue;
```

**✅ 解決策:** 専用のsetterメソッドを作成
```dart
class MyNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setValue(int value) {
    state = value; // Notifier内部でのみ許可
  }
}
```

### 問題2: build()内での非同期処理

```dart
// ❌ 避ける
@override
Future<MyState> build() async {
  return await fetchData(); // buildはFutureを返せない
}
```

**✅ 解決策:** buildは同期的に初期値を返し、別メソッドで非同期処理
```dart
@override
MyState build() {
  final initialState = MyState(isLoading: true);
  _initializeAsync();
  return initialState;
}

Future<void> _initializeAsync() async {
  final data = await fetchData();
  state = state.copyWith(data: data, isLoading: false);
}
```

## 🎯 チェックリスト

新規Provider実装時の確認項目:

- [ ] `Notifier<T>` または `@riverpod` を使用している
- [ ] `StateNotifierProvider`/`StateProvider` を使用していない
- [ ] `build()` メソッドで初期値を返している
- [ ] 状態更新は専用メソッド経由で行っている
- [ ] `.state` への直接アクセスを外部に公開していない
- [ ] 非同期処理は `build()` 外で実行している
- [ ] `flutter analyze` で警告が出ていない

---

**関連スキル:**
- `/code-quality` - Lint警告対処
- `/flutter-patterns` - Widget設計パターン
