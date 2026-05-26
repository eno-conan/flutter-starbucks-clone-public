# BottomSheet・Dialog レスポンシブパターン

このドキュメントは、BottomSheetやDialogをレスポンシブに実装するパターンを説明します。

## 📋 基本パターン

### パターン1: レスポンシブBottomSheet

**使用場面**: モーダル表示、フォーム入力、選択UI

```dart
void showResponsiveBottomSheet(BuildContext context, WidgetRef ref) {
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
        maxWidth: dimensions.bottomSheetMaxWidth, // タブレット: 600.0, スマホ: width
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'BottomSheet Title',
            style: TextStyle(fontSize: dimensions.titleFontSize), // 16.0 or 18.0
          ),
          SizedBox(height: dimensions.sectionSpacing), // 20.0 or 30.0
          // コンテンツ
          Text('Content here'),
          SizedBox(height: dimensions.cardSpacing), // 10.0 or 15.0
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

### パターン2: レスポンシブDialog

**使用場面**: 確認ダイアログ、警告表示

```dart
void showResponsiveDialog(BuildContext context, WidgetRef ref) {
  final dimensions = ref.read(responsiveDimensionsProvider);

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: dimensions.dialogInsetHorizontal, // 12.0 or 16.0
        vertical: 24.0,
      ),
      contentPadding: EdgeInsets.all(dimensions.marginHorizontal), // 12.0 or 15.0
      title: Text(
        'Confirmation',
        style: TextStyle(fontSize: dimensions.titleFontSize), // 16.0 or 18.0
      ),
      content: Text(
        'Are you sure?',
        style: TextStyle(fontSize: dimensions.bodyFontSize), // 14.0 or 16.0
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            // アクション実行
            Navigator.pop(context);
          },
          child: Text('Confirm'),
        ),
      ],
    ),
  );
}
```

### パターン3: スクロール可能なBottomSheet

**使用場面**: 長いコンテンツ、リスト選択

```dart
void showScrollableBottomSheet(BuildContext context, WidgetRef ref) {
  final dimensions = ref.read(responsiveDimensionsProvider);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // 重要: 高さを制御可能にする
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.6, // 初期高さ（画面の60%）
      minChildSize: 0.3, // 最小高さ
      maxChildSize: 0.9, // 最大高さ
      expand: false,
      builder: (context, scrollController) => Container(
        padding: EdgeInsets.symmetric(
          horizontal: dimensions.bottomSheetPaddingHorizontal,
        ),
        child: ListView.builder(
          controller: scrollController,
          itemCount: 20,
          itemBuilder: (context, index) => ListTile(
            title: Text('Item $index'),
            onTap: () {
              // アイテム選択
              Navigator.pop(context);
            },
          ),
        ),
      ),
    ),
  );
}
```

## 🎨 高度なパターン

### パターン1: タブレット対応BottomSheet

**タブレットでは幅を制限し、中央に配置:**

```dart
void showTabletAwareBottomSheet(BuildContext context, WidgetRef ref) {
  final dimensions = ref.read(responsiveDimensionsProvider);

  showModalBottomSheet(
    context: context,
    builder: (context) => Center(
      child: Container(
        // タブレットでは最大600px、スマホでは画面幅
        width: dimensions.bottomSheetMaxWidth,
        padding: EdgeInsets.symmetric(
          horizontal: dimensions.bottomSheetPaddingHorizontal,
          vertical: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Responsive BottomSheet',
              style: TextStyle(
                fontSize: dimensions.headerFontSize, // 24.0 or 28.0 or 32.0
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: dimensions.sectionSpacing),
            Text(
              'This sheet adapts to device size.',
              style: TextStyle(fontSize: dimensions.bodyFontSize),
            ),
            SizedBox(height: dimensions.cardSpacing),
            SizedBox(
              height: dimensions.buttonMinHeight, // 48.0 or 60.0
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
```

### パターン2: ConsumerWidgetとして定義

**再利用可能なBottomSheetWidget:**

```dart
class ResponsiveSelectionSheet extends ConsumerWidget {
  const ResponsiveSelectionSheet({
    super.key,
    required this.items,
    required this.onItemSelected,
  });

  final List<String> items;
  final ValueChanged<String> onItemSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dimensions = ref.watch(responsiveDimensionsProvider);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dimensions.bottomSheetPaddingHorizontal,
        vertical: 20,
      ),
      constraints: BoxConstraints(
        maxWidth: dimensions.bottomSheetMaxWidth,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Select an option',
            style: TextStyle(
              fontSize: dimensions.titleFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: dimensions.cardSpacing),
          ...items.map((item) => ListTile(
            title: Text(item),
            onTap: () {
              onItemSelected(item);
              Navigator.pop(context);
            },
          )),
        ],
      ),
    );
  }
}

// 使用例
void showSelectionSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    builder: (context) => ResponsiveSelectionSheet(
      items: ['Option 1', 'Option 2', 'Option 3'],
      onItemSelected: (item) {
        LoggerService.info('Selected: $item');
      },
    ),
  );
}
```

### パターン3: フォーム入力用BottomSheet

**入力フォームをレスポンシブに表示:**

```dart
class ResponsiveFormSheet extends ConsumerStatefulWidget {
  const ResponsiveFormSheet({super.key});

  @override
  ConsumerState<ResponsiveFormSheet> createState() =>
      _ResponsiveFormSheetState();
}

class _ResponsiveFormSheetState extends ConsumerState<ResponsiveFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dimensions = ref.watch(responsiveDimensionsProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: dimensions.bottomSheetPaddingHorizontal,
        right: dimensions.bottomSheetPaddingHorizontal,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20, // キーボード対応
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enter your information',
              style: TextStyle(
                fontSize: dimensions.titleFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: dimensions.cardSpacing),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            SizedBox(height: dimensions.cardSpacing),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                return null;
              },
            ),
            SizedBox(height: dimensions.sectionSpacing),
            SizedBox(
              height: dimensions.buttonMinHeight,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // フォーム送信処理
                    Navigator.pop(context);
                  }
                },
                child: Text('Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

## 🛠️ BottomSheet表示のヘルパー関数

### ヘルパークラスの作成

```dart
class ResponsiveSheetHelper {
  /// レスポンシブなBottomSheetを表示
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetRef ref,
    required Widget child,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    final dimensions = ref.read(responsiveDimensionsProvider);

    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      builder: (context) => Container(
        padding: EdgeInsets.symmetric(
          horizontal: dimensions.bottomSheetPaddingHorizontal,
          vertical: 20,
        ),
        constraints: BoxConstraints(
          maxWidth: dimensions.bottomSheetMaxWidth,
        ),
        child: child,
      ),
    );
  }

  /// レスポンシブなDialogを表示
  static Future<T?> showDialog<T>({
    required BuildContext context,
    required WidgetRef ref,
    required Widget child,
    bool barrierDismissible = true,
  }) {
    final dimensions = ref.read(responsiveDimensionsProvider);

    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: dimensions.dialogInsetHorizontal,
        vertical: 24.0,
      ),
      contentPadding: EdgeInsets.all(dimensions.marginHorizontal),
      content: child,
    ) as Future<T?>;
  }
}

// 使用例
void showMyBottomSheet(BuildContext context, WidgetRef ref) {
  ResponsiveSheetHelper.show(
    context: context,
    ref: ref,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Content'),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close'),
        ),
      ],
    ),
  );
}
```

## 🚨 よくある問題と対処法

### 問題1: キーボードでBottomSheetが隠れる

**症状**: TextFieldにフォーカスするとキーボードがBottomSheetを隠す

**対処法:**
```dart
Padding(
  padding: EdgeInsets.only(
    left: dimensions.bottomSheetPaddingHorizontal,
    right: dimensions.bottomSheetPaddingHorizontal,
    top: 20,
    bottom: MediaQuery.of(context).viewInsets.bottom + 20, // キーボード対応
  ),
  child: Form(...),
)
```

### 問題2: タブレットでBottomSheetが横幅いっぱいに広がる

**症状**: タブレットでBottomSheetが見づらい

**対処法:**
```dart
// 最大幅を設定
Container(
  constraints: BoxConstraints(
    maxWidth: dimensions.bottomSheetMaxWidth, // タブレット: 600.0
  ),
  child: ...,
)
```

### 問題3: ref.watchがBottomSheet内で使えない

**症状**: showModalBottomSheetのbuilder内でref.watchにアクセスできない

**対処法1: ref.readを使用（表示前に取得）**
```dart
void showSheet(BuildContext context, WidgetRef ref) {
  final dimensions = ref.read(responsiveDimensionsProvider);

  showModalBottomSheet(
    context: context,
    builder: (context) => Container(
      padding: EdgeInsets.all(dimensions.marginHorizontal),
      child: ...,
    ),
  );
}
```

**対処法2: ConsumerWidgetとして定義**
```dart
class MySheet extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dimensions = ref.watch(responsiveDimensionsProvider);
    return Container(...);
  }
}

// 使用時
showModalBottomSheet(
  context: context,
  builder: (context) => MySheet(),
);
```

## ✅ チェックリスト

BottomSheet・Dialog実装時の確認項目:

- [ ] `responsiveDimensionsProvider`を使用している
- [ ] `ref.read()`または`ConsumerWidget`でProviderにアクセス
- [ ] `bottomSheetPaddingHorizontal`でパディングを指定
- [ ] `bottomSheetMaxWidth`でタブレット対応の最大幅を指定
- [ ] フォーム入力時はキーボード対応のパディング設定
- [ ] 狭い端末（360px）と通常端末（414px）で動作確認

---

**このパターンに従うことで、デバイスサイズに応じた美しいBottomSheet・Dialogを実現できます。**
