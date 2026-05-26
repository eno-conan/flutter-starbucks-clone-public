---
description: サービス・リポジトリ層ガイドライン(ビジネスロジック)
paths:
  - "lib/services/**/*.dart"
  - "lib/core/services/**/*.dart"
  - "lib/data/repository/**/*.dart"
---

# サービス・リポジトリ層ガイドライン

## ビジネスロジック・データアクセス層専用ルール

### アーキテクチャ原則

1. **単一責任の原則**: 各サービスは一つの機能領域に集中
2. **依存性注入**: Riverpod を使用してサービスを提供
3. **エラーハンドリング**: 適切な例外処理とログ出力

### サービス層の構成

```
lib/services/
  ├── feature_name/
  │   ├── feature_service.dart           # メインサービス
  │   ├── feature_cache_service.dart     # キャッシュ機能
  │   └── sub_feature_service.dart       # サブ機能
  └── common_service.dart                # 複数機能で使用
```

### 実装ルール

1. **非同期処理**: `Future<T>` または `Stream<T>` を適切に使用
2. **エラーハンドリング**: カスタム例外クラスの使用を推奨
3. **ログ出力**: LoggerService を使用した適切なログレベル設定
4. **キャッシュ戦略**: 必要に応じてキャッシュ機能を実装

### Riverpod Provider パターン

```dart
// ✅ 良い例: サービス用Provider
@riverpod
class FeatureService extends _$FeatureService {
  @override
  Future<FeatureData> build() async {
    // 初期化処理
  }

  Future<void> performAction() async {
    // アクション処理
  }
}
```

### Repository層の型安全性パターン

Repository層（`lib/data/repository/`）では、Supabase RPCや動的型の扱いに注意が必要です。以下のパターンに従い、型推論エラーや動的呼び出し警告を回避してください。

#### 1. Supabase RPC呼び出し時の型指定

**❌ 避けるべきパターン**:
```dart
// 型引数が推論できず、警告が発生
final response = await _supabase.rpc(Rpcs.getRpcFunction);
```

**✅ 推奨パターン**:
```dart
// 型引数を明示的に指定
final response = await _supabase.rpc<List<Map<String, dynamic>>>(
  Rpcs.getRpcFunction,
  params: {'user_id': userId},
);
```

**参考実装**: `lib/data/repository/cart.dart:29`

#### 2. レスポンスの型安全なキャスト

RPCレスポンスを他のメソッドに渡す際は、明示的にキャストしてください。

```dart
// ✅ レスポンスを明示的にキャスト
final response = await _supabase.rpc<List<Map<String, dynamic>>>(
  Rpcs.getProducts,
);

final List<Map<String, dynamic>> responseList =
    (response as List<dynamic>).cast<Map<String, dynamic>>();

// メソッドに型安全に渡す
final products = await _processProducts(responseList);
```

#### 3. nullable値の扱い

データベースやキャッシュから取得した値は、nullable型として扱い、適切にnullチェックを行ってください。

**❌ 避けるべきパターン**:
```dart
// nullable値を非nullableにキャストすると警告が発生
final timestamp = cacheData['timestamp'] as int;
```

**✅ 推奨パターン**:
```dart
// nullable型として扱い、nullチェックを追加
final timestamp = cacheData['timestamp'] as int?;
if (timestamp == null) {
  return null;
}

// 以降は非null確定なので安全に使用可能
final now = DateTime.now().millisecondsSinceEpoch;
if (now - timestamp < cacheDuration) {
  // キャッシュ有効
}
```

**複数のnullable値を扱う場合**:
```dart
final cacheData = result.first;

// 各フィールドをnullableとして取得
final timestamp = cacheData['timestamp'] as int?;
if (timestamp == null) {
  return null;
}

final dataString = cacheData['data'] as String?;
if (dataString == null) {
  return null;
}

// 以降は両方とも非null確定
final jsonList = jsonDecode(dataString) as List<dynamic>;
```

#### 4. 動的型へのアクセス回避

`List<dynamic>`を扱う際は、ループ変数の型を明示するか、メソッド引数の型を`List<Map<String, dynamic>>`に変更してください。

**❌ 避けるべきパターン**:
```dart
Future<List<Product>> _processData(List<dynamic> dataList) async {
  for (final data in dataList) {
    // dynamicに直接アクセスすると警告が発生
    final productId = data['product_id'] as int;
  }
}
```

**✅ 推奨パターン1: メソッド引数の型を明示**:
```dart
Future<List<Product>> _processData(
  List<Map<String, dynamic>> dataList, // 型を明示
) async {
  for (final dataMap in dataList) {
    // 型安全にアクセス
    final productId = dataMap['product_id'] as int;
    final productName = dataMap['product_name'] as String;
  }
}
```

**✅ 推奨パターン2: ループ内でキャスト**:
```dart
Future<List<Product>> _processData(List<dynamic> dataList) async {
  for (final item in dataList) {
    final dataMap = item as Map<String, dynamic>; // 明示的にキャスト
    final productId = dataMap['product_id'] as int;
  }
}
```

#### 5. よくあるエラーパターンと対処法

| エラー | 原因 | 対処法 |
|--------|------|--------|
| `inference_failure_on_function_invocation` | `.rpc()`の型引数が推論できない | 型引数`<List<Map<String, dynamic>>>`を明示 |
| `avoid_dynamic_calls` | `dynamic`型への直接アクセス | メソッド引数を`List<Map<String, dynamic>>`に変更 |
| `cast_nullable_to_non_nullable` | nullable値を非nullableにキャスト | `as int?`でキャストし、nullチェック追加 |
| `argument_type_not_assignable` | `dynamic`を`List<dynamic>`に代入 | `.cast<Map<String, dynamic>>()`で明示的にキャスト |

#### 6. 完全な実装例

以下は、これらのパターンを全て適用した完全な実装例です。

```dart
class ProductRepository {
  ProductRepository(this._supabase);
  final SupabaseClient _supabase;

  Future<List<Product>> getProducts() async {
    // 1. RPC呼び出し時に型引数を明示
    final response = await _supabase.rpc<List<Map<String, dynamic>>>(
      Rpcs.getProductsWithCategories,
    );

    // 2. レスポンスを型安全にキャスト
    final List<Map<String, dynamic>> responseList =
        (response as List<dynamic>).cast<Map<String, dynamic>>();

    // 3. 型安全なメソッドに渡す
    return _convertToProducts(responseList);
  }

  // 4. メソッド引数の型を明示
  Future<List<Product>> _convertToProducts(
    List<Map<String, dynamic>> dataList,
  ) async {
    final List<Product> products = [];

    for (final dataMap in dataList) {
      // 5. 型安全にアクセス
      final productId = dataMap['product_id'] as int;
      final productName = dataMap['product_name'] as String;

      products.add(Product(id: productId, name: productName));
    }

    return products;
  }

  Future<List<Product>?> _loadFromCache(String cacheKey) async {
    final result = await db.query('cache', where: 'id = ?', whereArgs: [cacheKey]);

    if (result.isNotEmpty) {
      final cacheData = result.first;

      // 6. nullable値として扱い、nullチェック
      final timestamp = cacheData['timestamp'] as int?;
      if (timestamp == null) {
        return null;
      }

      final dataString = cacheData['data'] as String?;
      if (dataString == null) {
        return null;
      }

      // 7. jsonDecodeの結果も明示的にキャスト
      final jsonList = jsonDecode(dataString) as List<dynamic>;
      return jsonList
          .map((json) => Product.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    return null;
  }
}
```

**この実装により、以下の警告が全て解消されます**:
- ✅ `inference_failure_on_function_invocation`
- ✅ `avoid_dynamic_calls`
- ✅ `cast_nullable_to_non_nullable`
- ✅ `argument_type_not_assignable`

**参考実装**:
- `lib/data/repository/product.dart` - 型安全な実装の完全な例
- `lib/data/repository/cart.dart:29` - RPC呼び出しの正しいパターン
- `lib/data/repository/store.dart` - nullableキャッシュ値の扱い
