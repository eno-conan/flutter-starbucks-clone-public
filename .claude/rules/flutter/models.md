---
description: データモデル実装ガイドライン（Equatable、JSON処理）
---

# データモデル実装ガイドライン

## データクラス・モデル専用ルール

このルールは以下のディレクトリのDartファイル作業時に適用されます:
- `lib/core/models/`
- `lib/*/model/` (任意のディレクトリ下のmodel)
- `lib/*/models/` (任意のディレクトリ下のmodels)

### モデルクラス設計原則

1. **Immutableクラス**: 全てのフィールドはfinalで定義
2. **Factory Constructor**: JSONシリアライゼーション用のfactory constructor
3. **Copyコンストラクター**: データ変更用のcopyWithメソッド
4. **Equatable**: 値比較のためのEquatableミックスイン使用

### 実装テンプレート

```dart
import 'package:equatable/equatable.dart';

class ModelName extends Equatable {
  const ModelName({
    required this.id,
    required this.name,
    this.optionalField,
  });

  final String id;
  final String name;
  final String? optionalField;

  factory ModelName.fromJson(Map<String, dynamic> json) {
    return ModelName(
      id: json['id'] as String,
      name: json['name'] as String,
      optionalField: json['optional_field'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (optionalField != null) 'optional_field': optionalField,
  };

  ModelName copyWith({
    String? id,
    String? name,
    String? optionalField,
  }) {
    return ModelName(
      id: id ?? this.id,
      name: name ?? this.name,
      optionalField: optionalField ?? this.optionalField,
    );
  }

  @override
  List<Object?> get props => [id, name, optionalField];
}
```

### 命名規則

- モデルクラス名: `PascalCase` (例: `UserProfile`, `OrderDetail`)
- ファイル名: `snake_case.dart` (例: `user_profile.dart`, `order_detail.dart`)
- フィールド名: `camelCase` (例: `firstName`, `createdAt`)

### JSON処理ルール

1. **Null安全**: 全てのフィールドでnull安全を考慮
2. **型安全**: `as` キャストを適切に使用
3. **オプションフィールド**: nullableフィールドは条件付きでJSONに含める
