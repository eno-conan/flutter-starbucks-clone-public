---
description: サービス・リポジトリ層ガイドライン（ビジネスロジック）
---

# サービス・リポジトリ層ガイドライン

## ビジネスロジック・データアクセス層専用ルール

このルールは以下のディレクトリのDartファイル作業時に適用されます:
- `lib/services/`
- `lib/core/services/`
- `lib/data/repository/`

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
