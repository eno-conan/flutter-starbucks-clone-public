---
description: 画面・Widget実装ガイドライン(screens、widgets配下)
paths:
  - "lib/screens/**/*.dart"
  - "lib/shared/widgets/**/*.dart"
---

# 画面・Widget実装ガイドライン

## スクリーンおよびWidgetファイル専用ルール

### 画面設計の基本原則

1. **責任の分離**: 各画面は単一の責任を持つべき
2. **再利用可能なWidgetの分離**: 共通Widgetは`lib/shared/widgets/`に配置
3. **状態管理の適切な使用**: Riverpod 3.0のNotifier APIを使用

### ファイル構成ルール

```
lib/screens/
  ├── feature_name/
  │   ├── main.dart              # メイン画面
  │   ├── components/            # この画面専用のコンポーネント
  │   └── widgets/               # この画面専用のWidget
  └── shared_screen.dart         # 複数機能で使われる画面
```

### Widget命名規則

- 画面クラス: `FeatureNameScreen`
- 専用Widget: `_PrivateWidgetName` (外部から使用されない場合)
- 共用Widget: `PublicWidgetName`

### 状態管理ルール

画面レベルでの状態管理は必ずRiverpod 3.0のNotifier APIを使用し、
`lib/provider/` に配置してください。
