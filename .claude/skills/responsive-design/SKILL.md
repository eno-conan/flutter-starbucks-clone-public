---
name: responsive-design
description: |
  responsiveDimensionsProviderを使用した一貫性のあるレスポンシブデザイン実装。
  MediaQuery直接使用の置き換え、デバイスサイズ対応（狭い端末 <384px、通常端末 ≥384px）。
  トリガーワード: responsive, MediaQuery, レスポンシブ, デバイスサイズ, 画面幅, グリッドレイアウト, 固定値
  典型的なユーザー質問: "MediaQueryを使わないでレスポンシブ実装したい", "画面サイズに応じてUIを変更したい", "固定値をレスポンシブにしたい"
  【対象外】: アニメーションの実装、パフォーマンス最適化、アクセシビリティ対応
user-invocable: true
disable-model-invocation: false
allowed-tools: Read, Grep
license: MIT
compatibility: |
  - Flutter SDK 3.0+
  - Riverpod 2.0+
metadata:
  author: flutter-starbucks-clone
  version: 1.0.0
  last-updated: 2025-02-11
argument-hint: [target] [device-size]
---

# レスポンシブデザイン実装スキル

このスキルは、`responsiveDimensionsProvider`を使用した一貫性のあるレスポンシブデザイン実装方法を提供します。

## 📋 使用場面

- 新規画面・Widget作成時
- MediaQuery直接使用からの移行時
- デバイスサイズによるUI切り替え実装時
- 固定値からレスポンシブ値への変更時

## 引数による実行

このスキルは引数をサポートしています。

**基本形式**: `/responsive-design [target] [device-size]`

**引数**:
- `$1` (target): 対象の実装パターン
  - `grid` - GridViewのレスポンシブ化
  - `media-query` - MediaQuery置き換え
  - `fixed-values` - 固定値の置き換え
  - `check` - MediaQuery直接使用の検出
- `$2` (device-size): テスト対象デバイスサイズ（オプション）
  - `360` - 狭い端末
  - `384` - ブレークポイント境界
  - `414` - 標準端末

**実行例**:
```bash
# GridViewをレスポンシブ化
/responsive-design grid

# MediaQuery置き換えパターンを提示
/responsive-design media-query

# MediaQuery直接使用箇所を検出
/responsive-design check
```

## 🎯 基本原則

**MediaQuery直接使用箇所**: !`grep -r "MediaQuery.sizeOf(context)" lib/ --exclude-dir=provider | wc -l`

**固定値の使用箇所**: !`grep -rE "width:\s*[0-9]+," lib/ | wc -l`

**responsiveDimensionsProvider使用箇所**: !`grep -r "responsiveDimensionsProvider" lib/ | wc -l`

**Provider定義**: !`cat lib/provider/responsive_dimensions_provider.dart`

### 1. MediaQuery直接使用の禁止

**❌ 禁止パターン:**
```dart
// MediaQueryを直接使用
final width = MediaQuery.sizeOf(context).width;
final height = MediaQuery.sizeOf(context).height * 0.8;
```

**✅ 推奨パターン:**
```dart
// responsiveDimensionsProviderを使用
final dimensions = ref.watch(responsiveDimensionsProvider);
final width = dimensions.width;
final height = dimensions.height * 0.8;
```

**理由:**
- 一元管理により保守性向上
- デバイス判定ロジックの重複排除
- パフォーマンスの最適化
- テストの容易性

### 2. デバイス判定基準

**ブレークポイント:**
- **狭い端末**: `width < 384px`
- **通常端末**: `width >= 384px`
- **タブレット（将来対応）**: `width >= 600px`

```dart
final dimensions = ref.watch(responsiveDimensionsProvider);

if (dimensions.isNarrowDevice) {
  return CompactLayout();
} else {
  return StandardLayout();
}
```

## 🛠️ 実装パターン

### パターン1: ConsumerWidgetでの使用（推奨）

**親Widgetで一度取得し、子Widgetにプロップスで渡す:**

```dart
// 親Widget: ConsumerWidgetで値を取得
class ProductGrid extends ConsumerWidget {
  const ProductGrid({super.key, required this.products});
  final List<Product> products;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 一度だけProvider取得
    final dimensions = ref.watch(responsiveDimensionsProvider);
    final imageFactor = dimensions.imageSizeFactor;
    final spacing = dimensions.heightBetweenImageName;

    return GridView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        // 子Widgetにプロップスで渡す
        return ProductCard(
          product: products[index],
          imageFactor: imageFactor,
          spacing: spacing,
        );
      },
    );
  }
}

// 子Widget: StatelessWidgetで受け取る
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.imageFactor,
    required this.spacing,
  });

  final Product product;
  final double imageFactor;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FractionallySizedBox(
          widthFactor: imageFactor, // Providerから渡された値を使用
          child: Image.network(product.imageUrl),
        ),
        SizedBox(height: spacing),
        Text(product.name),
      ],
    );
  }
}
```

**利点:**
- Providerアクセスは親で1回のみ（効率的）
- 子Widgetは純粋な表示コンポーネント（テスト容易）
- Riverpodの再構築範囲が最小化

### パターン2: StatefulWidget内での使用

```dart
class MyStatefulWidget extends StatefulWidget {
  const MyStatefulWidget({super.key});

  @override
  State<MyStatefulWidget> createState() => _MyStatefulWidgetState();
}

class _MyStatefulWidgetState extends State<MyStatefulWidget> {
  @override
  Widget build(BuildContext context) {
    // ConsumerでラップしてProviderにアクセス
    return Consumer(
      builder: (context, ref, child) {
        final dimensions = ref.watch(responsiveDimensionsProvider);

        return Container(
          width: dimensions.width * 0.9,
          height: dimensions.buttonMinHeight,
          child: ElevatedButton(
            onPressed: _handlePress,
            child: Text('Button'),
          ),
        );
      },
    );
  }

  void _handlePress() {
    // ボタン処理
  }
}
```

### パターン3: GridViewでの列数調整

```dart
class ResponsiveGrid extends ConsumerWidget {
  const ResponsiveGrid({super.key, required this.items});
  final List<Item> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dimensions = ref.watch(responsiveDimensionsProvider);

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: dimensions.gridCrossAxisCount, // 2 or 3
        crossAxisSpacing: dimensions.gridCrossAxisSpacing,
        mainAxisSpacing: dimensions.gridMainAxisSpacing,
        childAspectRatio: dimensions.gridChildAspectRatio,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => ItemCard(item: items[index]),
    );
  }
}
```

## 📐 提供される値

### 基本値

```dart
final dimensions = ref.watch(responsiveDimensionsProvider);

// デバイスサイズ
dimensions.width        // double: デバイス幅
dimensions.height       // double: デバイス高さ

// デバイス判定
dimensions.isNarrowDevice  // bool: width < 384px
```

### グリッドレイアウト

```dart
dimensions.gridCrossAxisCount     // int: 2 (狭い) / 3 (通常)
dimensions.gridCrossAxisSpacing   // double: 8.0 / 10.0
dimensions.gridMainAxisSpacing    // double: 20.0 / 25.0
dimensions.gridChildAspectRatio   // double: 0.7 / 0.75
```

### マージン・パディング

```dart
dimensions.marginHorizontal   // double: 12.0 / 15.0
dimensions.cardSpacing        // double: 10.0 / 15.0
dimensions.sectionSpacing     // double: 20.0 / 30.0
```

### 画像・アイコンサイズ

```dart
dimensions.imageSizeFactor     // double: 0.95 / 1.0
dimensions.productImageSize    // double: 110.0 / 125.0
dimensions.iconSize            // double: 20.0 / 24.0
```

### ボタン・インタラクティブ要素

```dart
dimensions.fabHeight                // double: 40.0 / 45.0
dimensions.fabWidth                 // double: 110.0 / 128.0
dimensions.buttonMinHeight          // double: 48.0 / 60.0
dimensions.buttonPaddingHorizontal  // double: 16.0 / 20.0
```

### テキスト・フォントサイズ

```dart
dimensions.headerFontSize   // double: 24.0 / 28.0
dimensions.titleFontSize    // double: 16.0 / 18.0
dimensions.bodyFontSize     // double: 14.0 / 16.0
dimensions.captionFontSize  // double: 11.0 / 12.0
```

### BottomSheet・Dialog

```dart
dimensions.bottomSheetPaddingHorizontal  // double: 20.0 / 25.0
dimensions.dialogInsetHorizontal         // double: 12.0 / 16.0
dimensions.bottomSheetMaxWidth           // double: 600.0 (タブレット) / width
```

## 🔄 置き換えパターン

### パターン1: 固定値→レスポンシブ値

**Before:**
```dart
Container(
  width: 125,  // 固定値
  height: 125,
  child: Image.network(imageUrl),
)
```

**After:**
```dart
final dimensions = ref.watch(responsiveDimensionsProvider);

Container(
  width: dimensions.productImageSize,  // 110.0 / 125.0
  height: dimensions.productImageSize,
  child: Image.network(imageUrl),
)
```

### パターン2: MediaQuery計算→Provider計算値

**Before:**
```dart
SizedBox(
  width: MediaQuery.sizeOf(context).width * 0.4,
  child: MyWidget(),
)
```

**After:**
```dart
final dimensions = ref.watch(responsiveDimensionsProvider);

SizedBox(
  width: dimensions.width * 0.4,
  child: MyWidget(),
)
```

### パターン3: 条件分岐→Provider判定

**Before:**
```dart
final width = MediaQuery.sizeOf(context).width;

GridView(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: width < 400 ? 2 : 3,  // 独自判定
  ),
)
```

**After:**
```dart
final dimensions = ref.watch(responsiveDimensionsProvider);

GridView(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: dimensions.gridCrossAxisCount,  // 統一判定
  ),
)
```

## 🚫 アンチパターン

### ❌ 子Widget内で毎回Provider取得

```dart
// ❌ 避ける: 各カードで毎回Providerを読み込み（非効率）
class ItemCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dimensions = ref.watch(responsiveDimensionsProvider);
    return Container(width: dimensions.width * 0.3);
  }
}
```

**✅ 修正方法:** 親で一度取得し、プロップスで渡す（パターン1参照）

### ❌ MediaQueryとProvider混在

```dart
// ❌ 避ける: MediaQueryとProviderの混在
final dimensions = ref.watch(responsiveDimensionsProvider);
final width = MediaQuery.sizeOf(context).width; // MediaQuery直接使用

Container(
  width: dimensions.isNarrowDevice ? width * 0.9 : width * 0.8,
)
```

**✅ 修正方法:** 全てProviderから取得

## ✅ 実装チェックリスト

### 新規実装時

- [ ] `ConsumerWidget`または`Consumer`を使用している
- [ ] `ref.watch(responsiveDimensionsProvider)`でProvider取得
- [ ] MediaQuery.sizeOf(context)を直接使用していない
- [ ] 固定値ではなく、Providerの計算値を使用している
- [ ] 親Widgetで一度取得し、子Widgetにプロップスで渡している
- [ ] デバイス判定は`dimensions.isNarrowDevice`を使用

### 既存コード修正時

- [ ] MediaQuery.sizeOf(context)を全てProviderに置き換えた
- [ ] 固定値をProviderの計算値に置き換えた
- [ ] 独自のデバイス判定ロジックをProviderの判定に統一した
- [ ] 複数箇所でのProvider取得を親での一度取得に集約した
- [ ] 動作確認を3つのデバイスサイズで実施した

## 🔍 検出コマンド

### MediaQuery直接使用の検出

```bash
# MediaQuery直接使用を検出（ゼロであることを確認）
grep -r "MediaQuery.sizeOf(context)" lib/ --exclude-dir=provider
```

### 固定値の検出（手動確認推奨）

```bash
# 固定値が使われている可能性のある箇所を検出
grep -r "SizedBox(width: [0-9]" lib/
grep -r "Container(width: [0-9]" lib/
```

## 🧪 テスト手法

### デバイスサイズ別テスト

**テスト対象サイズ:**
- **360px**: 狭い端末（Galaxy S8など）
- **384px**: ブレークポイント境界
- **414px**: 標準端末（iPhone 11 Proなど）

**テスト方法:**
```bash
# Flutterエミュレータで異なるサイズを起動
flutter emulators --launch <emulator_id>

# または、DevToolsでサイズ変更
# DevTools > Layout Explorer > Resize
```

## 🔗 詳細ドキュメント

- [レスポンシブデザイン実装ガイドライン](../../rules/flutter/responsive-design-guidelines.md) - 690行の詳細リファレンス
- [デバイスブレークポイント](./device-breakpoints.md)
- [Grid Layout パターン](./patterns/grid-layout.md)
- [BottomSheet パターン](./patterns/bottom-sheet.md)

## 🎯 まとめ

### 重要ポイント

1. **MediaQuery直接使用は禁止** → `responsiveDimensionsProvider`を使用
2. **親で一度取得** → 子Widgetにプロップスで渡す
3. **デバイス判定はProviderに集約** → `isNarrowDevice`を使用
4. **固定値を避ける** → Provider計算値を使用
5. **テストは3サイズで実施** → 360px、384px、414px

---

**関連スキル:**
- `/riverpod-3` - Riverpod 3.0実装ガイド
- `/code-quality` - Lint警告対処
- `/flutter-patterns` - Widget設計パターン
