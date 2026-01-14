---
paths:
  - "lib/**/*.dart"
  - "lib/screens/**/*"
  - "lib/shared/widgets/**/*"
---

# アンチパターン・避けるべき実装

## ❌ 避けるべき実装パターン

### 1. Riverpod初期化の問題
```dart
@override
void initState() {
  super.initState();
  
  // ❌ initState内でref.watch()を直接使用するとエラーが発生
  final someProvider = ref.watch(someProvider);
  
  // ❌ initState内でのref.watch()を含む処理
  _checkSomething(); // 内部でref.watch()を使用している場合
}
```

## ❌ アンチパターン（避けるべき書き方）

### 1. コードの可読性・保守性に関するアンチパターン

**ハードコーディング**
```dart
// ❌ 悪い例
Widget build(BuildContext context) {
  return Container(
    height: 200,
    width: 300,
    color: Color(0xFF4A90E2),
    padding: .all(16),
  );
}
```

**マジックナンバーの乱用**
```dart
// ❌ 悪い例
for (int i = 0; i < items.length; i++) {
  if (items[i].priority > 5) { // 5の意味が不明
    processHighPriorityItem(items[i]);
  }
}
```

**過度にネストした条件分岐**
```dart
// ❌ 悪い例
if (user != null) {
  if (user.isActive) {
    if (user.hasPermission) {
      if (user.isVerified) {
        return AdminPanel();
      }
    }
  }
}
return UnauthorizedView();
```

### 2. State管理・パフォーマンスに関するアンチパターン

**Widgetを返すメソッドの使用**
```dart
// ❌ 悪い例：Widgetを返すメソッド
class MyPage extends ConsumerWidget {
  Widget _buildQRCode() {
    final authAsync = ref.watch(authStateProvider);
    
    return authAsync.when(
      loading: () => const CircularProgressIndicator(),
      error: (error, _) => const Icon(Icons.error),
      data: (user) => QrImageView(data: user.id),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: _buildQRCode(), // ❌ パフォーマンス上の問題
    );
  }
}
```

**理由**：
- Widgetを返すメソッドは、Flutterのウィジェットツリーの最適化を妨げる
- `const`コンストラクタが使えず、不要な再構築が発生する
- Widgetツリーの差分検出が非効率になる
- メモリ使用量が増加する可能性がある

**正しい実装**：
```dart
// ✅ 良い例：StatelessWidget/ConsumerWidgetとして定義
class QRCodeWidget extends ConsumerWidget {
  const QRCodeWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);
    
    return authAsync.when(
      loading: () => const CircularProgressIndicator(),
      error: (error, _) => const Icon(Icons.error),
      data: (user) => QrImageView(data: user.id),
    );
  }
}

// 使用時
const QRCodeWidget() // constが使える
```

**BuildContextの不適切な使用**
```dart
// ❌ 悪い例：非同期処理後にBuildContextを使用
Future<void> _loadData() async {
  await Future<void>.delayed(Duration(seconds: 2));
  if (mounted) {
    Navigator.of(context).pushNamed('/home'); // contextが無効になっている可能性
  }
}
```

**不必要なsetStateの呼び出し**
```dart
// ❌ 悪い例
void _updateCounter() {
  setState(() {
    counter += 1;
  });
  // 他の処理...
  setState(() {
    // 何も変更していない
  });
}
```

**GlobalKeyの乱用**
```dart
// ❌ 悪い例
final GlobalKey<FormState> _formKey1 = GlobalKey<FormState>();
final GlobalKey<FormState> _formKey2 = GlobalKey<FormState>();
final GlobalKey<FormState> _formKey3 = GlobalKey<FormState>();
// GlobalKeyが多すぎる
```

### 3. エラーハンドリングに関するアンチパターン

**例外の適切でない処理**
```dart
// ❌ 悪い例
try {
  final result = await api.fetchData();
  return result;
} catch (e) {
  print(e); // ログだけで何もしない
  return null; // nullを返す
}
```

**型チェックの不備**
```dart
// ❌ 悪い例
dynamic data = await fetchData();
String name = data['name']; // 型が保証されていない
```

### 4. 一般的な避けるべきパターン

**printの使用**
```dart
// ❌ 避けるべき：printの使用（avoid_print）
void debugInfo() {
  print('Debug info'); // 本番環境では避ける
}
```

**不要なnull初期化**
```dart
// ❌ 避けるべき：不要なnull初期化（avoid_init_to_null）
String? name = null; // 冗長
```

**不要なContainer**
```dart
// ❌ 避けるべき：不要なContainer（avoid_unnecessary_containers）
Container(
  child: Text('Hello'),
) // Containerが不要
```

**空白にContainerを使用**
```dart
// ❌ 悪い例：空白にContainerを使用
Widget build(BuildContext context) {
  return Column(
    children: [
      Text('Content'),
      Container(height: 16), // 空白にContainerは非効率
      Text('More content'),
    ],
  );
}
```

**色だけのためにContainerを使用**
```dart
// ❌ 悪い例：色だけのためにContainerを使用
Container(
  color: Colors.red,
  child: Text('Colored text'),
)
```

**非同期処理後に直接Contextを使用**
```dart
// ❌ 悪い例：非同期処理後に直接Contextを使用
Future<void> _handleSubmit() async {
  await Future<void>.delayed(Duration(seconds: 1));
  Navigator.of(context).pop(); // 危険：contextが無効な可能性
}
```

**戻り値の型が未指定**
```dart
// ❌ 悪い例：戻り値の型が未指定
buildHeader() { // 戻り値の型が不明
  return Container(child: Text('Header'));
}
```

**constを使わない**
```dart
// ❌ 悪い例：constを使わない
final widget = ImmutableWidget(data: 'test'); // newが暗黙的
```

**相対importを使用**
```dart
// ❌ 悪い例：相対importを使用
import '../models/user.dart'; // 相対パス
import '../../widgets/custom_button.dart'; // 相対パス
```

**ダブルクォートを使用（特別な理由がない限り）**
```dart
// ❌ 悪い例：ダブルクォートを使用（特別な理由がない限り）
const String message = "Hello World";
```

**中括弧なしの制御フロー**
```dart
// ❌ 悪い例：中括弧なし
if (condition)
  doSomething(); // 中括弧がない
```

**不適切なファイル名**
```dart
// ❌ 悪い例
// ファイル名: UserProfile.dart (大文字始まりは避ける)
// ファイル名: api-service.dart (ハイフンは避ける)
```

**従来の書き方（super parameters未使用）**
```dart
// ❌ 悪い例：従来の書き方
class OldChildWidget extends ParentWidget {
  const OldChildWidget({
    Key? key,
    required String title,
    required this.description,
  }) : super(key: key, title: title); // 冗長
  final String description;
}
```

### 5. Sliverウィジェットに関するアンチパターン

**SliverウィジェットをRenderBox系の親に配置**
```dart
// ❌ 悪い例：SliverGridを通常のWidgetツリーに配置
Widget build(BuildContext context) {
  return Column(
    children: [
      Text('タイトル'),
      SliverGrid( // ❌ RenderRepaintBoundary expected RenderBox but received RenderSliverGrid
        delegate: SliverChildBuilderDelegate(
          (context, index) => ProductCard(product: products[index]),
          childCount: products.length,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
        ),
      ),
    ],
  );
}
```

**解決策：Sliverウィジェットは必ずScrollable内で使用**
```dart
// ✅ 良い例：CustomScrollViewまたはNestedScrollView内で使用
Widget build(BuildContext context) {
  return CustomScrollView(
    slivers: [
      SliverAppBar(
        title: Text('商品一覧'),
        floating: true,
      ),
      SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, index) => ProductCard(product: products[index]),
          childCount: products.length,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
        ),
      ),
    ],
  );
}
```

**RepaintBoundaryでSliverをラップしない**
```dart
// ❌ 悪い例：RepaintBoundaryでSliverを直接ラップ
RepaintBoundary(
  child: SliverGrid(...), // ❌ エラーの原因
)
```

**Sliverと通常のWidgetを混在させない**
```dart
// ❌ 悪い例：SliverList内に通常のWidgetを直接配置
SliverList(
  delegate: SliverChildListDelegate([
    Container(height: 100), // ❌ 通常のWidgetを直接配置
    ProductCard(),
  ]),
)

// ✅ 良い例：SliverToBoxAdapterを使用
SliverList(
  delegate: SliverChildListDelegate([
    SliverToBoxAdapter(
      child: Container(height: 100), // ✅ SliverToBoxAdapterでラップ
    ),
    SliverToBoxAdapter(
      child: ProductCard(),
    ),
  ]),
)
```

**エラーパターンの理解**
- `RenderRepaintBoundary expected a child of type RenderBox but received a child of type RenderSliverGrid`
- このエラーは、Sliverウィジェット（SliverGrid、SliverList等）を通常のWidget階層に配置した時に発生
- SliverウィジェットはScrollableなWidget（CustomScrollView、NestedScrollView等）内でのみ使用可能
- RepaintBoundaryやKeepAlive等の一般的なWidgetでSliverを直接ラップするとエラーが発生

### 理由と背景

これらのアンチパターンを避ける理由：

1. **保守性**: コードの理解と修正が困難になる
2. **パフォーマンス**: 不必要な処理やリソース消費を引き起こす
3. **安全性**: 実行時エラーやメモリリークの原因となる
4. **一貫性**: プロジェクト全体のコード品質が低下する
5. **テスタビリティ**: テストが困難または不可能になる