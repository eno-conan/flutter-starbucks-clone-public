# 実装パターン集

## 1. Riverpod 3.0 Notifier パターン

### 基本形（同期状態）
```dart
class MyNotifier extends Notifier<MyState> {
  @override
  MyState build() => const MyState.initial();

  void update(SomeValue value) {
    state = state.copyWith(value: value);
  }
}

final myProvider = NotifierProvider<MyNotifier, MyState>(MyNotifier.new);
```

### 非同期状態
```dart
class MyAsyncNotifier extends AsyncNotifier<MyData> {
  @override
  Future<MyData> build() async {
    return await _fetchData();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetchData);
  }
}

final myProvider = AsyncNotifierProvider<MyAsyncNotifier, MyData>(MyAsyncNotifier.new);
```

### sealed class を使った状態ステートマシン（orderSettlementProviderの例）
```dart
sealed class MyState { const MyState(); }
class MyStateInitial extends MyState { const MyStateInitial(); }
class MyStateLoading extends MyState { const MyStateLoading(); }
class MyStateSuccess extends MyState {
  const MyStateSuccess(this.data);
  final MyData data;
}
class MyStateError extends MyState {
  const MyStateError(this.message);
  final String message;
}

class MyNotifier extends Notifier<MyState> {
  @override
  MyState build() => const MyStateInitial();

  Future<void> execute() async {
    state = const MyStateLoading();
    try {
      final data = await _service.fetchData();
      state = MyStateSuccess(data);
    } catch (e) {
      state = MyStateError(e.toString());
    }
  }
}
```

---

## 2. responsiveDimensionsProvider パターン

### ConsumerWidget での使用（推奨）
```dart
class MyScreen extends ConsumerWidget {
  const MyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dimensions = ref.watch(responsiveDimensionsProvider);

    return Container(
      width: dimensions.width * 0.8,
      padding: EdgeInsets.symmetric(horizontal: dimensions.marginHorizontal),
    );
  }
}
```

### 親→子へプロップスで渡すパターン（GridView等）
```dart
// 親でProviderを一度だけ取得
class ParentWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dimensions = ref.watch(responsiveDimensionsProvider);

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: dimensions.gridCrossAxisCount,
      ),
      itemBuilder: (context, index) => ChildCard(
        imageFactor: dimensions.imageSizeFactor,  // プロップスで渡す
      ),
    );
  }
}

// 子はStatelessWidget（Providerを直接持たない）
class ChildCard extends StatelessWidget {
  const ChildCard({super.key, required this.imageFactor});
  final double imageFactor;
  // ...
}
```

### 禁止: MediaQuery直接使用
```dart
// ❌ 禁止
final width = MediaQuery.sizeOf(context).width;

// ✅ 推奨
final dimensions = ref.watch(responsiveDimensionsProvider);
final width = dimensions.width;
```

---

## 3. LoggerService パターン

### 基本パターン（info/warn）
```dart
// 正常フロー
LoggerService.info('商品データ取得完了: ${products.length}件');

// エラー・例外発生時
try {
  await someOperation();
} catch (error) {
  LoggerService.warn('操作に失敗しました', error);
  rethrow;
}
```

### throwとの組み合わせ
```dart
String getUserId() {
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) {
    LoggerService.warn('ユーザーが認証されていません');
    throw Exception('ユーザーが認証されていません');
  }
  return userId;
}
```

### 開発環境のみ出力
```dart
if (kDebugMode) {
  LoggerService.info('デバッグ情報: $debugData');
}
```

### 禁止: print / debugPrint
```dart
// ❌ 禁止
print('データ: $data');
debugPrint('エラー: $e');

// ✅ 推奨
LoggerService.info('データ: $data');
LoggerService.warn('エラー発生', e);
```

---

## 4. context.mounted チェックパターン

### 非同期処理後の安全なcontext使用
```dart
Future<void> _handleSubmit() async {
  try {
    await someAsyncOperation();

    if (!context.mounted) return;  // ← 必須

    context.go('/success');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('完了しました')),
    );
  } catch (error) {
    LoggerService.warn('操作に失敗しました', error);

    if (!context.mounted) return;  // ← catch内でも必須

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('エラー: $error')),
    );
  }
}
```

---

## 5. Supabase RPC 呼び出しパターン

### 定数を使ったRPC呼び出し
```dart
import 'package:flutter_starbucks_clone/constants/supabase_rpcs.dart';

// ✅ 定数を使用
final response = await supabase.rpc(
  Rpcs.getCartDetails,
  params: {'p_user_id': userId},
);

// ❌ 文字列リテラル直書き禁止
final response = await supabase.rpc('get_cart_details', ...);
```

### テーブルアクセスパターン
```dart
import 'package:flutter_starbucks_clone/constants/supabase_tables.dart';

// ✅ 定数を使用
final response = await supabase.from(Tables.stores).select();

// ❌ 文字列リテラル直書き禁止
final response = await supabase.from('stores').select();
```

---

## 6. Service のシングルトンパターン

### getInstance() パターン（実プロジェクトで使用）
```dart
class OrderSettlementService {
  static OrderSettlementService? _instance;

  static OrderSettlementService getInstance() {
    _instance ??= OrderSettlementService._internal();
    return _instance!;
  }

  OrderSettlementService._internal();
}

// 使用側
final service = OrderSettlementService.getInstance();
```

---

## 7. go_router ナビゲーション

### context.go / context.push
```dart
// ルートを置き換え
context.go('/home');

// スタックに追加
context.push('/detail', extra: {'id': itemId});
```

### 非同期処理後（mountedチェック必須）
```dart
await operation();
if (!context.mounted) return;
context.go('/next');
```

---

## 8. import ルール

### package import を使用（相対 import 禁止）
```dart
// ✅ 推奨
import 'package:flutter_starbucks_clone/constants/supabase_rpcs.dart';

// ❌ 禁止
import '../constants/supabase_rpcs.dart';
```

### シングルクォートを使用
```dart
// ✅ 推奨
import 'package:flutter/material.dart';

// ❌ 禁止
import "package:flutter/material.dart";
```
