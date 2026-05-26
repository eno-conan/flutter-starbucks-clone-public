// レスポンシブWidget実装テンプレート
// このファイルは、responsiveDimensionsProviderを使ったWidget実装の
// ベストプラクティスを示すテンプレートです。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:app/provider/responsive_dimensions_provider.dart';

// ============================================
// テンプレート1: シンプルなConsumerWidget
// ============================================
class ResponsiveWidgetTemplate extends ConsumerWidget {
  const ResponsiveWidgetTemplate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Providerから一度だけ取得
    final dimensions = ref.watch(responsiveDimensionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Responsive Template'),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: dimensions.marginHorizontal, // 12.0 or 15.0
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー
            Text(
              'Header',
              style: TextStyle(
                fontSize: dimensions.headerFontSize, // 24.0 or 28.0
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: dimensions.sectionSpacing), // 20.0 or 30.0

            // タイトル
            Text(
              'Title',
              style: TextStyle(fontSize: dimensions.titleFontSize), // 16.0 or 18.0
            ),
            SizedBox(height: dimensions.cardSpacing), // 10.0 or 15.0

            // ボディ
            Text(
              'Body text',
              style: TextStyle(fontSize: dimensions.bodyFontSize), // 14.0 or 16.0
            ),
            SizedBox(height: dimensions.sectionSpacing),

            // ボタン
            SizedBox(
              height: dimensions.buttonMinHeight, // 48.0 or 60.0
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Button'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// テンプレート2: グリッドレイアウト
// ============================================
class ResponsiveGridTemplate extends ConsumerWidget {
  const ResponsiveGridTemplate({super.key, required this.items});
  final List<String> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dimensions = ref.watch(responsiveDimensionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Responsive Grid'),
      ),
      body: GridView.builder(
        padding: EdgeInsets.symmetric(
          horizontal: dimensions.marginHorizontal,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: dimensions.gridCrossAxisCount, // 2 or 3
          crossAxisSpacing: dimensions.gridCrossAxisSpacing, // 8.0 or 10.0
          mainAxisSpacing: dimensions.gridMainAxisSpacing, // 20.0 or 25.0
          childAspectRatio: dimensions.gridChildAspectRatio, // 0.7 or 0.75
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          // 子Widgetにプロップスで渡す
          return ResponsiveGridItemTemplate(
            title: items[index],
            imageSize: dimensions.productImageSize, // 110.0 or 125.0
            spacing: dimensions.cardSpacing, // 10.0 or 15.0
          );
        },
      ),
    );
  }
}

// グリッドアイテム（StatelessWidget）
class ResponsiveGridItemTemplate extends StatelessWidget {
  const ResponsiveGridItemTemplate({
    super.key,
    required this.title,
    required this.imageSize,
    required this.spacing,
  });

  final String title;
  final double imageSize;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          // 画像
          Container(
            height: imageSize,
            width: double.infinity,
            color: Colors.grey[300],
            child: const Icon(Icons.image, size: 48),
          ),
          SizedBox(height: spacing),
          // タイトル
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ============================================
// テンプレート3: 条件分岐レイアウト
// ============================================
class ResponsiveConditionalTemplate extends ConsumerWidget {
  const ResponsiveConditionalTemplate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dimensions = ref.watch(responsiveDimensionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conditional Layout'),
      ),
      body: dimensions.isNarrowDevice
          ? _buildCompactLayout(dimensions)
          : _buildStandardLayout(dimensions),
    );
  }

  // 狭い端末用レイアウト
  Widget _buildCompactLayout(ResponsiveDimensions dimensions) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: dimensions.marginHorizontal),
      child: Column(
        children: [
          Text(
            'Compact Layout',
            style: TextStyle(fontSize: dimensions.headerFontSize),
          ),
          SizedBox(height: dimensions.sectionSpacing),
          // 1列レイアウト
          ListView(
            shrinkWrap: true,
            children: [
              _buildCard(dimensions),
              SizedBox(height: dimensions.cardSpacing),
              _buildCard(dimensions),
            ],
          ),
        ],
      ),
    );
  }

  // 通常端末用レイアウト
  Widget _buildStandardLayout(ResponsiveDimensions dimensions) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: dimensions.marginHorizontal),
      child: Column(
        children: [
          Text(
            'Standard Layout',
            style: TextStyle(fontSize: dimensions.headerFontSize),
          ),
          SizedBox(height: dimensions.sectionSpacing),
          // 2列レイアウト
          Row(
            children: [
              Expanded(child: _buildCard(dimensions)),
              SizedBox(width: dimensions.cardSpacing),
              Expanded(child: _buildCard(dimensions)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCard(ResponsiveDimensions dimensions) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(dimensions.marginHorizontal),
        child: Text(
          'Card Content',
          style: TextStyle(fontSize: dimensions.bodyFontSize),
        ),
      ),
    );
  }
}

// ============================================
// テンプレート4: StatefulWidgetでの使用
// ============================================
class ResponsiveStatefulTemplate extends StatefulWidget {
  const ResponsiveStatefulTemplate({super.key});

  @override
  State<ResponsiveStatefulTemplate> createState() =>
      _ResponsiveStatefulTemplateState();
}

class _ResponsiveStatefulTemplateState
    extends State<ResponsiveStatefulTemplate> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    // ConsumerでラップしてProviderにアクセス
    return Consumer(
      builder: (context, ref, child) {
        final dimensions = ref.watch(responsiveDimensionsProvider);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Stateful Template'),
          ),
          body: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: dimensions.marginHorizontal,
            ),
            child: Column(
              children: [
                Text(
                  'Selected: $_selectedIndex',
                  style: TextStyle(fontSize: dimensions.titleFontSize),
                ),
                SizedBox(height: dimensions.sectionSpacing),
                // ボタン
                SizedBox(
                  height: dimensions.buttonMinHeight,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedIndex++;
                      });
                    },
                    child: const Text('Increment'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================
// テンプレート5: BottomSheet
// ============================================
void showResponsiveBottomSheetTemplate(BuildContext context, WidgetRef ref) {
  // BottomSheet表示前にProviderから値取得
  final dimensions = ref.read(responsiveDimensionsProvider);

  showModalBottomSheet(
    context: context,
    builder: (context) => Container(
      padding: EdgeInsets.symmetric(
        horizontal: dimensions.bottomSheetPaddingHorizontal, // 20.0 or 25.0
        vertical: 20,
      ),
      constraints: BoxConstraints(
        maxWidth: dimensions.bottomSheetMaxWidth, // タブレット: 600.0
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'BottomSheet Title',
            style: TextStyle(
              fontSize: dimensions.titleFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: dimensions.sectionSpacing),
          Text(
            'BottomSheet content',
            style: TextStyle(fontSize: dimensions.bodyFontSize),
          ),
          SizedBox(height: dimensions.cardSpacing),
          SizedBox(
            height: dimensions.buttonMinHeight,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    ),
  );
}

// ============================================
// テンプレート6: Dialog
// ============================================
void showResponsiveDialogTemplate(BuildContext context, WidgetRef ref) {
  final dimensions = ref.read(responsiveDimensionsProvider);

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: dimensions.dialogInsetHorizontal, // 12.0 or 16.0
        vertical: 24.0,
      ),
      contentPadding: EdgeInsets.all(dimensions.marginHorizontal),
      title: Text(
        'Dialog Title',
        style: TextStyle(fontSize: dimensions.titleFontSize),
      ),
      content: Text(
        'Dialog content',
        style: TextStyle(fontSize: dimensions.bodyFontSize),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            // アクション実行
            Navigator.pop(context);
          },
          child: const Text('Confirm'),
        ),
      ],
    ),
  );
}

// ============================================
// テンプレート7: 親で取得→子に渡すパターン
// ============================================

// 親Widget: Providerで一度取得
class ParentWidgetTemplate extends ConsumerWidget {
  const ParentWidgetTemplate({super.key, required this.items});
  final List<String> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 一度だけProvider取得
    final dimensions = ref.watch(responsiveDimensionsProvider);

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: dimensions.marginHorizontal),
      itemCount: items.length,
      itemBuilder: (context, index) {
        // 子Widgetにプロップスで渡す
        return ChildWidgetTemplate(
          title: items[index],
          titleFontSize: dimensions.titleFontSize,
          bodyFontSize: dimensions.bodyFontSize,
          cardSpacing: dimensions.cardSpacing,
        );
      },
    );
  }
}

// 子Widget: StatelessWidgetで受け取る
class ChildWidgetTemplate extends StatelessWidget {
  const ChildWidgetTemplate({
    super.key,
    required this.title,
    required this.titleFontSize,
    required this.bodyFontSize,
    required this.cardSpacing,
  });

  final String title;
  final double titleFontSize;
  final double bodyFontSize;
  final double cardSpacing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(cardSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: titleFontSize),
            ),
            SizedBox(height: cardSpacing),
            Text(
              'Body text',
              style: TextStyle(fontSize: bodyFontSize),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// 使用例
// ============================================

// アプリのエントリーポイント
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'Responsive Template',
        home: ResponsiveWidgetTemplate(),
      ),
    );
  }
}
