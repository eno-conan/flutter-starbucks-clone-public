# Grid Layout レスポンシブパターン

このドキュメントは、GridView/ListViewを使ったレスポンシブなグリッドレイアウトの実装パターンを説明します。

## 📋 基本パターン

### パターン1: GridViewWithFixedCrossAxisCount

**使用場面**: 商品一覧、画像ギャラリーなど、均等なグリッド表示

```dart
class ProductGridScreen extends ConsumerWidget {
  const ProductGridScreen({super.key, required this.products});
  final List<Product> products;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Providerから一度だけ取得
    final dimensions = ref.watch(responsiveDimensionsProvider);

    return GridView.builder(
      padding: EdgeInsets.symmetric(horizontal: dimensions.marginHorizontal),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: dimensions.gridCrossAxisCount, // 2 or 3
        crossAxisSpacing: dimensions.gridCrossAxisSpacing, // 8.0 or 10.0
        mainAxisSpacing: dimensions.gridMainAxisSpacing, // 20.0 or 25.0
        childAspectRatio: dimensions.gridChildAspectRatio, // 0.7 or 0.75
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        // 子Widgetにプロップスで渡す
        return ProductCard(
          product: products[index],
          imageSize: dimensions.productImageSize,
        );
      },
    );
  }
}
```

### パターン2: SliverGridWithResponsiveColumns

**使用場面**: CustomScrollView内でのグリッド表示

```dart
class ResponsiveSliverGrid extends ConsumerWidget {
  const ResponsiveSliverGrid({super.key, required this.items});
  final List<Item> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dimensions = ref.watch(responsiveDimensionsProvider);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          title: const Text('Responsive Grid'),
          floating: true,
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: dimensions.marginHorizontal),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: dimensions.gridCrossAxisCount,
              crossAxisSpacing: dimensions.gridCrossAxisSpacing,
              mainAxisSpacing: dimensions.gridMainAxisSpacing,
              childAspectRatio: dimensions.gridChildAspectRatio,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => ItemCard(
                item: items[index],
                spacing: dimensions.cardSpacing,
              ),
              childCount: items.length,
            ),
          ),
        ),
      ],
    );
  }
}
```

### パターン3: GridViewWithMaxCrossAxisExtent

**使用場面**: デバイス幅に応じて列数を自動調整したい場合

```dart
class AdaptiveGrid extends ConsumerWidget {
  const AdaptiveGrid({super.key, required this.items});
  final List<Item> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dimensions = ref.watch(responsiveDimensionsProvider);

    return GridView.builder(
      padding: EdgeInsets.all(dimensions.marginHorizontal),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: dimensions.isNarrowDevice ? 180.0 : 200.0,
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

## 🎨 グリッドアイテムの設計

### パターン1: シンプルなカード

```dart
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.imageSize,
  });

  final Product product;
  final double imageSize;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 画像
          SizedBox(
            height: imageSize,
            width: double.infinity,
            child: Image.network(
              product.imageUrl,
              fit: BoxFit.cover,
            ),
          ),
          // タイトル
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // 価格
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              '¥${product.price}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
```

### パターン2: FractionallySizedBoxを使った比率指定

```dart
class ResponsiveProductCard extends StatelessWidget {
  const ResponsiveProductCard({
    super.key,
    required this.product,
    required this.imageFactor, // 0.95 or 1.0
    required this.spacing,
  });

  final Product product;
  final double imageFactor;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 画像: 親の幅に対する比率で指定
        FractionallySizedBox(
          widthFactor: imageFactor,
          child: AspectRatio(
            aspectRatio: 1.0, // 正方形
            child: Image.network(
              product.imageUrl,
              fit: BoxFit.cover,
            ),
          ),
        ),
        SizedBox(height: spacing),
        Text(
          product.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
```

## 🔄 デバイスサイズ別のグリッド例

### 狭い端末（< 384px）

```dart
// 2列グリッド
// 例: 360px幅 → 1列あたり約170px
gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
  crossAxisCount: 2, // 2列
  crossAxisSpacing: 8.0, // 列間スペース
  mainAxisSpacing: 20.0, // 行間スペース
  childAspectRatio: 0.7, // 縦長
)
```

**レイアウトイメージ:**
```
┌────────────┬────────────┐
│  Item 1    │  Item 2    │
│  (170x243) │  (170x243) │
└────────────┴────────────┘
┌────────────┬────────────┐
│  Item 3    │  Item 4    │
│  (170x243) │  (170x243) │
└────────────┴────────────┘
```

### 通常端末（>= 384px）

```dart
// 3列グリッド
// 例: 414px幅 → 1列あたり約128px
gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
  crossAxisCount: 3, // 3列
  crossAxisSpacing: 10.0, // 列間スペース
  mainAxisSpacing: 25.0, // 行間スペース
  childAspectRatio: 0.75, // やや縦長
)
```

**レイアウトイメージ:**
```
┌────────┬────────┬────────┐
│ Item 1 │ Item 2 │ Item 3 │
│(128x171)│(128x171)│(128x171)│
└────────┴────────┴────────┘
┌────────┬────────┬────────┐
│ Item 4 │ Item 5 │ Item 6 │
│(128x171)│(128x171)│(128x171)│
└────────┴────────┴────────┘
```

## 🛠️ 高度なパターン

### パターン1: 条件分岐によるレイアウト切り替え

```dart
class ConditionalGridLayout extends ConsumerWidget {
  const ConditionalGridLayout({super.key, required this.items});
  final List<Item> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dimensions = ref.watch(responsiveDimensionsProvider);

    if (dimensions.isNarrowDevice) {
      // 狭い端末: 2列グリッド
      return GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 20.0,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) => CompactItemCard(item: items[index]),
      );
    } else {
      // 通常端末: 3列グリッド
      return GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10.0,
          mainAxisSpacing: 25.0,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) => StandardItemCard(item: items[index]),
      );
    }
  }
}
```

### パターン2: 動的な列数計算

```dart
class DynamicColumnGrid extends ConsumerWidget {
  const DynamicColumnGrid({super.key, required this.items});
  final List<Item> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dimensions = ref.watch(responsiveDimensionsProvider);

    // デバイス幅に基づいて列数を動的に計算
    int columnCount;
    if (dimensions.width < 384) {
      columnCount = 2;
    } else if (dimensions.width < 600) {
      columnCount = 3;
    } else {
      columnCount = 4; // タブレット
    }

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columnCount,
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

### パターン3: スクロール位置保持

```dart
class GridWithScrollController extends ConsumerStatefulWidget {
  const GridWithScrollController({super.key, required this.items});
  final List<Item> items;

  @override
  ConsumerState<GridWithScrollController> createState() =>
      _GridWithScrollControllerState();
}

class _GridWithScrollControllerState
    extends ConsumerState<GridWithScrollController> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dimensions = ref.watch(responsiveDimensionsProvider);

    return GridView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: dimensions.marginHorizontal),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: dimensions.gridCrossAxisCount,
        crossAxisSpacing: dimensions.gridCrossAxisSpacing,
        mainAxisSpacing: dimensions.gridMainAxisSpacing,
        childAspectRatio: dimensions.gridChildAspectRatio,
      ),
      itemCount: widget.items.length,
      itemBuilder: (context, index) => ItemCard(item: widget.items[index]),
    );
  }
}
```

## 🚨 よくある問題と対処法

### 問題1: アスペクト比が合わない

**症状**: 画像が歪む、カードの高さが不揃い

**原因**: `childAspectRatio`が適切でない

**対処法:**
```dart
// アスペクト比を計算
// 幅 / 高さ = 0.75 の場合、幅:高さ = 3:4
childAspectRatio: 0.75, // 縦長のカード

// または、明示的に計算
childAspectRatio: dimensions.isNarrowDevice ? 0.7 : 0.75,
```

### 問題2: グリッドアイテムが小さすぎる/大きすぎる

**症状**: デバイスによってアイテムサイズが極端に変わる

**原因**: 列数が固定されすぎている

**対処法:**
```dart
// MaxCrossAxisExtentを使って最大幅を指定
gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
  maxCrossAxisExtent: 200.0, // 1列の最大幅
  crossAxisSpacing: dimensions.gridCrossAxisSpacing,
  mainAxisSpacing: dimensions.gridMainAxisSpacing,
)
```

### 問題3: パフォーマンスが悪い

**症状**: グリッドスクロールがカクつく

**原因**: 子Widgetで毎回Providerアクセス

**対処法:**
```dart
// ❌ 避ける: 各アイテムでProviderアクセス
itemBuilder: (context, index) => ItemCard(item: items[index]),
// ItemCard内でref.watch(responsiveDimensionsProvider)を使用

// ✅ 推奨: 親で一度取得し、プロップスで渡す
final dimensions = ref.watch(responsiveDimensionsProvider);
itemBuilder: (context, index) => ItemCard(
  item: items[index],
  imageSize: dimensions.productImageSize,
),
```

## ✅ チェックリスト

グリッドレイアウト実装時の確認項目:

- [ ] `responsiveDimensionsProvider`を使用している
- [ ] `gridCrossAxisCount`で列数を指定している
- [ ] `crossAxisSpacing`と`mainAxisSpacing`でスペースを指定
- [ ] `childAspectRatio`でアスペクト比を指定
- [ ] 親Widgetで一度Provider取得し、子にプロップスで渡している
- [ ] 狭い端末（360px）と通常端末（414px）で動作確認している

---

**このパターンに従うことで、デバイスサイズに応じた美しいグリッドレイアウトを実現できます。**
