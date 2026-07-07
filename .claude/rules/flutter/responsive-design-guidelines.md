---
description: レスポンシブデザイン実装ガイドライン（responsiveDimensionsProvider必須）
paths:
  - "lib/screens/**/*.dart"
  - "lib/shared/widgets/**/*.dart"
---

# レスポンシブデザイン実装ガイドライン

## 📋 概要

このドキュメントは、Flutter/Dartプロジェクトにおけるレスポンシブデザインの実装標準を定義します。`responsiveDimensionsProvider`を使用した一貫性のあるレスポンシブ対応により、複数のデバイスサイズで最適なユーザー体験を提供します。

---

## 🎯 基本原則

### 1. MediaQuery直接使用の禁止

**❌ 禁止パターン**:
```dart
// MediaQueryを直接使用して計算
final width = MediaQuery.sizeOf(context).width;
final height = MediaQuery.sizeOf(context).height * 0.8;

SizedBox(
  width: MediaQuery.sizeOf(context).width * 0.4,
  child: MyWidget(),
)
```

**✅ 推奨パターン**:
```dart
// responsiveDimensionsProviderを使用
final dimensions = ref.watch(responsiveDimensionsProvider);
final width = dimensions.width;
final height = dimensions.height * 0.8;

SizedBox(
  width: dimensions.width * 0.4,
  child: MyWidget(),
)
```

**理由**:
- 一元管理により保守性向上
- デバイス判定ロジックの重複排除
- パフォーマンスの最適化
- テストの容易性

### 2. responsiveDimensionsProviderの必須使用

全ての画面・Widgetで`responsiveDimensionsProvider`を経由してデバイス情報にアクセスします。

**使用方法**:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/provider/responsive_dimensions_provider.dart';

class MyWidget extends ConsumerWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Providerから取得
    final dimensions = ref.watch(responsiveDimensionsProvider);

    // 計算値を使用
    return Container(
      width: dimensions.width * 0.8,
      padding: EdgeInsets.symmetric(horizontal: dimensions.marginHorizontal),
      child: Text('Hello'),
    );
  }
}
```

### 3. デバイス判定基準

**ブレークポイント**:
- **狭い端末（Narrow Device）**: `width < 384px`
- **通常端末**: `width >= 384px`
- **タブレット（将来対応）**: `width >= 600px`

**判定の使用**:
```dart
final dimensions = ref.watch(responsiveDimensionsProvider);

if (dimensions.isNarrowDevice) {
  // 狭い端末用のUI
  return CompactLayout();
} else {
  // 通常端末用のUI
  return StandardLayout();
}
```

---

## 🛠️ 実装パターン

### パターン1: ConsumerWidgetでの使用（推奨）

**親Widgetで一度取得し、子Widgetにプロップスで渡す**:

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

// 子Widget: StatelessWidgetまたはStatefulWidgetで受け取る
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
        SizedBox(height: spacing), // Providerから渡された値を使用
        Text(product.name),
      ],
    );
  }
}
```

**利点**:
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
    // ConsumerウィジェットでラップしてProviderにアクセス
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

### パターン3: BottomSheetやDialog内での使用

```dart
void showCustomBottomSheet(BuildContext context, WidgetRef ref) {
  // BottomSheet表示前にProviderから値取得
  final dimensions = ref.read(responsiveDimensionsProvider);

  showModalBottomSheet(
    context: context,
    builder: (context) => Container(
      padding: EdgeInsets.symmetric(
        horizontal: dimensions.bottomSheetPaddingHorizontal,
        vertical: 20,
      ),
      constraints: BoxConstraints(
        maxWidth: dimensions.bottomSheetMaxWidth, // タブレット対応
      ),
      child: Column(
        children: [
          Text('BottomSheet Content'),
          SizedBox(height: dimensions.sectionSpacing),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    ),
  );
}
```

### パターン4: GridViewでの列数調整

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

---

## 📐 ResponsiveDimensionsProvider提供値

### 基本値

```dart
final dimensions = ref.watch(responsiveDimensionsProvider);

// デバイスサイズ
dimensions.width        // double: デバイス幅
dimensions.height       // double: デバイス高さ

// デバイス判定
dimensions.isNarrowDevice  // bool: width < 384px
dimensions.isTablet        // bool: width >= 600px (将来対応)
dimensions.isLandscape     // bool: width > height (将来対応)
```

### グリッドレイアウト関連

```dart
dimensions.gridCrossAxisCount     // int: 2 (狭い) / 3 (通常)
dimensions.gridCrossAxisSpacing   // double: 8.0 / 10.0
dimensions.gridMainAxisSpacing    // double: 20.0 / 25.0
dimensions.gridChildAspectRatio   // double: 0.7 / 0.75
```

### マージン・パディング関連

```dart
dimensions.marginHorizontal   // double: 12.0 / 15.0
dimensions.cardSpacing        // double: 10.0 / 15.0
dimensions.sectionSpacing     // double: 20.0 / 30.0
```

### 画像・アイコンサイズ関連

```dart
dimensions.imageSizeFactor     // double: 0.95 / 1.0
dimensions.productImageSize    // double: 110.0 / 125.0
dimensions.iconSize            // double: 20.0 / 24.0
dimensions.svgWidthFactor      // double: 0.25 / 0.30
```

### ボタン・インタラクティブ要素関連

```dart
dimensions.fabHeight                // double: 40.0 / 45.0
dimensions.fabWidth                 // double: 110.0 / 128.0
dimensions.buttonMinHeight          // double: 48.0 / 60.0
dimensions.buttonPaddingHorizontal  // double: 16.0 / 20.0
```

### テキスト・フォントサイズ関連

```dart
dimensions.headerFontSize   // double: 24.0 / 28.0
dimensions.titleFontSize    // double: 16.0 / 18.0
dimensions.bodyFontSize     // double: 14.0 / 16.0
dimensions.captionFontSize  // double: 11.0 / 12.0
```

### BottomSheet・Dialog関連

```dart
dimensions.bottomSheetPaddingHorizontal  // double: 20.0 / 25.0
dimensions.dialogInsetHorizontal         // double: 12.0 / 16.0
dimensions.bottomSheetMaxWidth           // double: 600.0 (タブレット) / width
```

---

## 🔄 置き換えパターン集

### パターン1: 固定値からレスポンシブ値へ

**Before**:
```dart
Container(
  width: 125,  // 固定値
  height: 125,
  child: Image.network(imageUrl),
)
```

**After**:
```dart
final dimensions = ref.watch(responsiveDimensionsProvider);

Container(
  width: dimensions.productImageSize,  // 110.0 / 125.0
  height: dimensions.productImageSize,
  child: Image.network(imageUrl),
)
```

### パターン2: MediaQuery計算からProvider計算値へ

**Before**:
```dart
SizedBox(
  width: MediaQuery.sizeOf(context).width * 0.4,
  child: MyWidget(),
)
```

**After**:
```dart
final dimensions = ref.watch(responsiveDimensionsProvider);

SizedBox(
  width: dimensions.width * 0.4,
  child: MyWidget(),
)
```

### パターン3: 条件分岐からProvider判定へ

**Before**:
```dart
final width = MediaQuery.sizeOf(context).width;

GridView(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: width < 400 ? 2 : 3,  // 独自判定
  ),
)
```

**After**:
```dart
final dimensions = ref.watch(responsiveDimensionsProvider);

GridView(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: dimensions.gridCrossAxisCount,  // 統一判定
  ),
)
```

### パターン4: 複数のMediaQuery呼び出しを統一

**Before**:
```dart
Widget build(BuildContext context) {
  return Column(
    children: [
      SizedBox(width: MediaQuery.sizeOf(context).width * 0.8),
      SizedBox(height: MediaQuery.sizeOf(context).height * 0.1),
      Container(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.sizeOf(context).width < 380 ? 12.0 : 15.0,
        ),
      ),
    ],
  );
}
```

**After**:
```dart
Widget build(BuildContext context, WidgetRef ref) {
  final dimensions = ref.watch(responsiveDimensionsProvider);

  return Column(
    children: [
      SizedBox(width: dimensions.width * 0.8),
      SizedBox(height: dimensions.height * 0.1),
      Container(
        padding: EdgeInsets.symmetric(
          horizontal: dimensions.marginHorizontal,
        ),
      ),
    ],
  );
}
```

---

## 🚫 アンチパターン

### ❌ アンチパターン1: 子Widget内で毎回Provider取得

```dart
// ❌ 避ける: GridViewの各アイテムでProviderアクセス
class ItemCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 各カードで毎回Providerを読み込み（非効率）
    final dimensions = ref.watch(responsiveDimensionsProvider);
    return Container(width: dimensions.width * 0.3);
  }
}
```

**修正方法**: 親で一度取得し、プロップスで渡す（パターン1参照）

### ❌ アンチパターン2: 固定値のハードコード

```dart
// ❌ 避ける: デバイスサイズを考慮しない固定値
SizedBox(height: 15), // 全デバイスで同じ
Container(width: 128), // 全デバイスで同じ
```

**修正方法**: Providerの計算値を使用

### ❌ アンチパターン3: デバイス判定の独自実装

```dart
// ❌ 避ける: 独自のブレークポイント判定
final isSmall = MediaQuery.sizeOf(context).width < 390; // 独自基準
final isTiny = MediaQuery.sizeOf(context).width < 360;  // 独自基準
```

**修正方法**: `dimensions.isNarrowDevice`を使用

### ❌ アンチパターン4: MediaQueryとProvider混在

```dart
// ❌ 避ける: MediaQueryとProviderの混在
final dimensions = ref.watch(responsiveDimensionsProvider);
final width = MediaQuery.sizeOf(context).width; // MediaQuery直接使用

Container(
  width: dimensions.isNarrowDevice ? width * 0.9 : width * 0.8,
)
```

**修正方法**: 全てProviderから取得

---

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
- [ ] 動作確認を3つのデバイスサイズ（360px、384px、414px）で実施した

---

## 🧪 テスト手法

### 1. デバイスサイズ別テスト

**テスト対象サイズ**:
- **360px**: 狭い端末（Galaxy S8など）
- **384px**: ブレークポイント境界
- **414px**: 標準端末（iPhone 11 Proなど）
- **600px以上**: タブレット（将来対応）

**テスト方法**:
```bash
# Flutterエミュレータで異なるサイズを起動
flutter emulators --launch <emulator_id>

# または、DevToolsでサイズ変更
# DevTools > Layout Explorer > Resize
```

### 2. FlutterのDevToolsを使用

1. **Widget Inspector**: Widget階層とサイズを確認
2. **Performance Overlay**: フレームレート確認（60fps維持）
3. **Layout Explorer**: 各Widgetのサイズ・制約を確認

### 3. ゴールデンテスト（スナップショットテスト）

```dart
testWidgets('ResponsiveWidget renders correctly on narrow device', (tester) async {
  // 360px幅でテスト
  tester.binding.window.physicalSizeTestValue = Size(360, 800);
  tester.binding.window.devicePixelRatioTestValue = 1.0;

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: MyResponsiveWidget(),
      ),
    ),
  );

  // ゴールデンファイルと比較
  await expectLater(
    find.byType(MyResponsiveWidget),
    matchesGoldenFile('golden/my_widget_narrow.png'),
  );
});
```

---

## 🔧 Providerへの値追加方法

新しいレスポンシブ値が必要になった場合の追加手順:

### Step 1: ResponsiveDimensionsクラスに追加

```dart
// lib/provider/responsive_dimensions_provider.dart

class ResponsiveDimensions {
  // 既存のプロパティ...

  /// 新しい計算値を追加
  /// カード間のマージン（狭い端末では8.0、通常は12.0）
  double get cardMargin => isNarrowDevice ? 8.0 : 12.0;
}
```

### Step 2: 使用箇所で利用

```dart
final dimensions = ref.watch(responsiveDimensionsProvider);

Container(
  margin: EdgeInsets.all(dimensions.cardMargin),
  child: MyCard(),
)
```

### Step 3: ドキュメント更新

このガイドラインの「提供値」セクションに追加した値を記載。

---

## 📊 パフォーマンス考慮事項

### 1. Providerアクセスの最小化

```dart
// ✅ 良い例: 親で一度だけ取得
class ParentWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dimensions = ref.watch(responsiveDimensionsProvider);

    return Column(
      children: List.generate(
        100,
        (index) => ChildWidget(spacing: dimensions.cardSpacing),
      ),
    );
  }
}

// ❌ 悪い例: 各子Widgetで取得
class ChildWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dimensions = ref.watch(responsiveDimensionsProvider);
    // 100個のWidgetがそれぞれProviderアクセス（非効率）
    return Container(margin: EdgeInsets.all(dimensions.cardSpacing));
  }
}
```

### 2. 計算値のキャッシュ

現在のProviderは`getter`で計算値を提供していますが、パフォーマンス上の問題が発生した場合は`late final`でキャッシュを検討:

```dart
class ResponsiveDimensions {
  const ResponsiveDimensions({required this.width, required this.height});

  final double width;
  final double height;

  // キャッシュ版（必要に応じて）
  late final bool isNarrowDevice = width < 384;
  late final double imageSizeFactor = isNarrowDevice ? 0.95 : 1.0;
}
```

### 3. 不要な再構築の回避

```dart
// select修飾子で必要な値のみ監視（高度な最適化）
final isNarrow = ref.watch(
  responsiveDimensionsProvider.select((d) => d.isNarrowDevice),
);
// isNarrowDeviceが変更された時のみ再構築
```

---

## 📚 参考実装

### リファレンス実装

- **lib/screens/starbucks_user_side/mobile_order_pay/tab_order/products.dart**
  - 既存の成功実装
  - _ProductGridクラスでのConsumerWidget使用
  - 親での一度取得→子へのプロップス渡し

### 学習リソース

- [Riverpod公式ドキュメント](https://riverpod.dev/)
- [Flutter レスポンシブデザイン](https://docs.flutter.dev/ui/layout/responsive)
- プロジェクト内: `.claude/rules/flutter/implementation-guidelines.md`

---

## 🎯 まとめ

### 重要ポイント

1. **MediaQuery直接使用は禁止** → `responsiveDimensionsProvider`を使用
2. **親で一度取得** → 子Widgetにプロップスで渡す
3. **デバイス判定はProviderに集約** → `isNarrowDevice`を使用
4. **固定値を避ける** → Provider計算値を使用
5. **テストは3サイズで実施** → 360px、384px、414px

### 実装時の基本フロー

1. ConsumerWidgetまたはConsumer使用
2. `ref.watch(responsiveDimensionsProvider)`で取得
3. 必要な計算値を抽出
4. 子Widgetにプロップスで渡す
5. 複数デバイスサイズでテスト

このガイドラインに従うことで、一貫性のある保守性の高いレスポンシブデザインを実現できます。
