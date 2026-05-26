# デバイスブレークポイント定義

このドキュメントは、プロジェクトで使用するデバイスサイズのブレークポイントと、各サイズでの推奨UI設計を定義します。

## 📱 ブレークポイント定義

### 基本ブレークポイント

| 分類 | 幅の範囲 | 主なデバイス | `isNarrowDevice` |
|-----|---------|-------------|-----------------|
| **狭い端末** | `< 384px` | Galaxy S8, iPhone SE | `true` |
| **通常端末** | `>= 384px` | iPhone 11 Pro, Pixel 5 | `false` |
| **タブレット**（将来対応） | `>= 600px` | iPad mini, Galaxy Tab | `false` |

### 具体的なデバイス例

| デバイス | 幅 (px) | 高さ (px) | 分類 |
|---------|---------|----------|------|
| iPhone SE (1st gen) | 320 | 568 | 狭い端末 |
| Galaxy S8 | 360 | 740 | 狭い端末 |
| **境界値** | **384** | - | **ブレークポイント** |
| iPhone 11 Pro | 375 | 812 | 通常端末（境界付近） |
| iPhone 12/13 | 390 | 844 | 通常端末 |
| Pixel 5 | 393 | 851 | 通常端末 |
| iPhone 14 Pro Max | 430 | 932 | 通常端末 |
| iPad mini | 744 | 1133 | タブレット（将来対応） |

## 🎨 ブレークポイント別UI設計

### 狭い端末（< 384px）

**設計方針:**
- コンパクトなレイアウト
- マージン・パディングを最小化
- フォントサイズを若干小さく
- グリッドは2列

**具体的な値:**
```dart
dimensions.marginHorizontal = 12.0
dimensions.gridCrossAxisCount = 2
dimensions.productImageSize = 110.0
dimensions.headerFontSize = 24.0
dimensions.bodyFontSize = 14.0
```

**推奨UI:**
- ナビゲーションバーのアイコンサイズ: 20px
- ボタンの最小高さ: 48px
- カード間のスペース: 10px
- セクション間のスペース: 20px

### 通常端末（>= 384px）

**設計方針:**
- 標準的なレイアウト
- 適度なマージン・パディング
- 標準フォントサイズ
- グリッドは3列

**具体的な値:**
```dart
dimensions.marginHorizontal = 15.0
dimensions.gridCrossAxisCount = 3
dimensions.productImageSize = 125.0
dimensions.headerFontSize = 28.0
dimensions.bodyFontSize = 16.0
```

**推奨UI:**
- ナビゲーションバーのアイコンサイズ: 24px
- ボタンの最小高さ: 60px
- カード間のスペース: 15px
- セクション間のスペース: 30px

### タブレット（>= 600px）- 将来対応

**設計方針:**
- 広いレイアウト
- 最大幅を設定してコンテンツを中央配置
- 大きなフォントサイズ
- グリッドは4列以上

**具体的な値（予定）:**
```dart
dimensions.marginHorizontal = 24.0
dimensions.gridCrossAxisCount = 4
dimensions.productImageSize = 150.0
dimensions.headerFontSize = 32.0
dimensions.bodyFontSize = 18.0
dimensions.bottomSheetMaxWidth = 600.0 // コンテンツの最大幅
```

## 🧪 テスト用デバイスサイズ

### 必須テストサイズ

開発・テスト時には以下の3つのサイズで動作確認を行ってください:

1. **360px**: 狭い端末の代表（Galaxy S8）
2. **384px**: ブレークポイント境界値
3. **414px**: 通常端末の代表（iPhone 11 Pro Max相当）

### Flutterエミュレータでのテスト

```bash
# iOS Simulator
flutter run -d "iPhone SE (1st generation)"  # 320px
flutter run -d "iPhone 11 Pro"               # 375px
flutter run -d "iPhone 14 Pro Max"           # 430px

# Android Emulator
flutter run -d emulator-5554  # Galaxy S8 (360px)
flutter run -d emulator-5556  # Pixel 5 (393px)
```

### DevToolsでのサイズ変更

1. アプリ起動後、DevToolsを開く
2. "Layout Explorer" タブを選択
3. デバイスサイズを手動で変更:
   - 360 x 740 (狭い端末)
   - 384 x 800 (境界値)
   - 414 x 896 (通常端末)

## 📐 ブレークポイント別の値一覧

### グリッドレイアウト

| 値 | 狭い端末 | 通常端末 | タブレット（予定） |
|----|---------|---------|------------------|
| `gridCrossAxisCount` | 2 | 3 | 4 |
| `gridCrossAxisSpacing` | 8.0 | 10.0 | 12.0 |
| `gridMainAxisSpacing` | 20.0 | 25.0 | 30.0 |
| `gridChildAspectRatio` | 0.7 | 0.75 | 0.8 |

### マージン・パディング

| 値 | 狭い端末 | 通常端末 | タブレット（予定） |
|----|---------|---------|------------------|
| `marginHorizontal` | 12.0 | 15.0 | 24.0 |
| `cardSpacing` | 10.0 | 15.0 | 20.0 |
| `sectionSpacing` | 20.0 | 30.0 | 40.0 |

### 画像・アイコンサイズ

| 値 | 狭い端末 | 通常端末 | タブレット（予定） |
|----|---------|---------|------------------|
| `imageSizeFactor` | 0.95 | 1.0 | 1.0 |
| `productImageSize` | 110.0 | 125.0 | 150.0 |
| `iconSize` | 20.0 | 24.0 | 28.0 |

### ボタン・インタラクティブ要素

| 値 | 狭い端末 | 通常端末 | タブレット（予定） |
|----|---------|---------|------------------|
| `fabHeight` | 40.0 | 45.0 | 50.0 |
| `fabWidth` | 110.0 | 128.0 | 140.0 |
| `buttonMinHeight` | 48.0 | 60.0 | 72.0 |
| `buttonPaddingHorizontal` | 16.0 | 20.0 | 24.0 |

### テキスト・フォントサイズ

| 値 | 狭い端末 | 通常端末 | タブレット（予定） |
|----|---------|---------|------------------|
| `headerFontSize` | 24.0 | 28.0 | 32.0 |
| `titleFontSize` | 16.0 | 18.0 | 20.0 |
| `bodyFontSize` | 14.0 | 16.0 | 18.0 |
| `captionFontSize` | 11.0 | 12.0 | 13.0 |

### BottomSheet・Dialog

| 値 | 狭い端末 | 通常端末 | タブレット（予定） |
|----|---------|---------|------------------|
| `bottomSheetPaddingHorizontal` | 20.0 | 25.0 | 30.0 |
| `dialogInsetHorizontal` | 12.0 | 16.0 | 20.0 |
| `bottomSheetMaxWidth` | width | width | 600.0 |

## 🔧 新しいブレークポイントの追加方法

将来的にタブレット対応などで新しいブレークポイントを追加する場合:

### Step 1: ResponsiveDimensionsクラスを更新

```dart
// lib/provider/responsive_dimensions_provider.dart

class ResponsiveDimensions {
  const ResponsiveDimensions({required this.width, required this.height});

  final double width;
  final double height;

  // 既存のブレークポイント
  bool get isNarrowDevice => width < 384;

  // 新規ブレークポイント追加
  bool get isTablet => width >= 600;
  bool get isLandscape => width > height;

  // 値を3段階に拡張
  double get marginHorizontal {
    if (isTablet) return 24.0;
    if (isNarrowDevice) return 12.0;
    return 15.0;
  }
}
```

### Step 2: テストケースを追加

```dart
testWidgets('Tablet layout test', (tester) async {
  tester.binding.window.physicalSizeTestValue = Size(600, 1024);
  tester.binding.window.devicePixelRatioTestValue = 1.0;

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(home: MyResponsiveWidget()),
    ),
  );

  // タブレット用レイアウトの確認
  expect(find.byType(TabletLayout), findsOneWidget);
});
```

### Step 3: ドキュメント更新

- このファイル（device-breakpoints.md）に新しいブレークポイントの定義を追加
- SKILL.mdの提供値セクションを更新

## 🎯 ブレークポイント選定の理由

### なぜ384pxなのか?

1. **現実的なデバイス分布**: 360px（Galaxy S8）と390px（iPhone 12）の中間
2. **十分なマージン**: 360px端末でも余裕を持ったレイアウトが可能
3. **グリッド列数の変更に最適**: 2列→3列への切り替えに適したサイズ
4. **将来の拡張性**: タブレット対応（600px）への段階的な拡張が容易

### なぜ600pxをタブレット境界にするのか?

1. **Material Design基準**: Googleの推奨ブレークポイント
2. **iPad miniサイズ**: 744px（最小のタブレット）よりも十分小さい
3. **業界標準**: 多くのレスポンシブフレームワークが採用

## 📚 参考資料

- [Material Design レスポンシブレイアウトガイド](https://m3.material.io/foundations/layout/applying-layout/window-size-classes)
- [Flutter デバイスサイズ一覧](https://docs.flutter.dev/ui/layout/responsive)
- プロジェクト内: `lib/provider/responsive_dimensions_provider.dart`

---

**このブレークポイント定義に従うことで、一貫性のあるレスポンシブデザインを実現できます。**
