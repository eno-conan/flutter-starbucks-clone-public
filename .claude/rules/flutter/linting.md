---
description: Lintルール解説（analysis_options.yaml準拠）
---

# analysis_options.yamlに基づく重要なルール

## 📋 必須遵守項目（linter rulesから抽出）

### 1. コンストラクターとパラメーター関連
```dart
// ✅ 良い例：Keyを適切に使用
class CustomWidget extends StatelessWidget {
  const CustomWidget({super.key, required this.title});
  final String title;
}

// ✅ 良い例：super parametersを使用（use_super_parameters）
class ChildWidget extends ParentWidget {
  const ChildWidget({
    super.key,
    super.title, // super parametersを使用
    required this.description,
  });
  final String description;
}

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

### 2. 戻り値の型宣言（always_declare_return_types）
```dart
// ✅ 良い例：戻り値の型を明示
Widget buildHeader() {
  return Container(child: Text('Header'));
}

Future<String> fetchData() async {
  return await api.getData();
}

void processData() {
  // 処理
}

// ❌ 悪い例：戻り値の型が未指定
buildHeader() { // 戻り値の型が不明
  return Container(child: Text('Header'));
}
```

### 3. const関連のルール
```dart
// ✅ 良い例：constコンストラクターと不変オブジェクト
class ImmutableWidget extends StatelessWidget {
  const ImmutableWidget({super.key, required this.data});
  final String data;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        Text('Static text'), // const
        SizedBox(height: 16), // const
      ],
    );
  }
}

// ✅ 良い例：constコンストラクターが使えるimmutableクラス
const widget = ImmutableWidget(data: 'test');

// ❌ 悪い例：constを使わない
final widget = ImmutableWidget(data: 'test'); // newが暗黙的
```

### 4. パッケージインポート（always_use_package_imports）
```dart
// ✅ 良い例：package importを使用
import 'package:flutter/material.dart';
import 'package:my_app/models/user.dart';
import 'package:my_app/widgets/custom_button.dart';

// ❌ 悪い例：相対importを使用
import '../models/user.dart'; // 相対パス
import '../../widgets/custom_button.dart'; // 相対パス
```

### 5. 文字列とクォート（prefer_single_quotes）
```dart
// ✅ 良い例：シングルクォートを使用
const String message = 'Hello World';
const String interpolated = 'Welcome ${user.name}';
const String withEscape = 'Don\'t forget';

// ❌ 悪い例：ダブルクォートを使用（特別な理由がない限り）
const String message = "Hello World";
```

### 6. 制御フロー（curly_braces_in_flow_control_structures）
```dart
// ✅ 良い例：if文に中括弧を使用
if (condition) {
  doSomething();
}

for (final item in items) {
  processItem(item);
}

// ❌ 悪い例：中括弧なし
if (condition)
  doSomething(); // 中括弧がない
```

### 7. Widget特有のルール
```dart
// ✅ 良い例：SizedBoxを適切に使用（sized_box_for_whitespace）
Widget build(BuildContext context) {
  return Column(
    children: [
      Text('Content'),
      const SizedBox(height: 16), // 空白にはSizedBoxを使用
      Text('More content'),
    ],
  );
}

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

// ✅ 良い例：ColoredBoxを使用（use_colored_box）
ColoredBox(
  color: Colors.red,
  child: Text('Colored text'),
)

// ❌ 悪い例：色だけのためにContainerを使用
Container(
  color: Colors.red,
  child: Text('Colored text'),
)
```

### 8. 非同期処理とContext（use_build_context_synchronously）
```dart
// ✅ 良い例：非同期処理後のContext使用時はmountedをチェック
Future<void> _handleSubmit() async {
  await Future<void>.delayed(Duration(seconds: 1));

  if (!mounted) return; // mountedチェック

  Navigator.of(context).pop();
}

// ❌ 悪い例：非同期処理後に直接Contextを使用
Future<void> _handleSubmit() async {
  await Future<void>.delayed(Duration(seconds: 1));
  Navigator.of(context).pop(); // 危険：contextが無効な可能性
}
```

### 9. ファイル名とクラス名（file_names, camel_case_types）
```dart
// ✅ 良い例：ファイル名とクラス名
// ファイル名: user_profile_screen.dart
class UserProfileScreen extends StatelessWidget {
  // 実装
}

// ファイル名: api_service.dart
class ApiService {
  // 実装
}

// ❌ 悪い例
// ファイル名: UserProfile.dart (大文字始まりは避ける)
// ファイル名: api-service.dart (ハイフンは避ける)
```

### 10. 避けるべきパターン
```dart
// ❌ 避けるべき：printの使用（avoid_print）
void debugInfo() {
  print('Debug info'); // 本番環境では避ける
}

// ✅ 良い例：適切なログ使用
void debugInfo() {
  debugPrint('Debug info'); // Flutter開発時
  // または適切なログライブラリを使用
}

// ❌ 避けるべき：不要なnull初期化（avoid_init_to_null）
String? name = null; // 冗長

// ✅ 良い例
String? name; // nullがデフォルト

// ❌ 避けるべき：不要なContainer（avoid_unnecessary_containers）
Container(
  child: Text('Hello'),
) // Containerが不要

// ✅ 良い例
Text('Hello') // 直接使用
```

## 🚨 よくある違反パターンと対策

### パターン1: フォーマット関連
- **page_width: 100**: 1行は100文字以内
- **eol_at_end_of_file**: ファイル末尾に改行を入れる
- **sort_child_properties_last**: childプロパティは最後に配置

```dart
// ✅ 良い例：childを最後に配置
Container(
  padding: .all(16),
  decoration: BoxDecoration(color: Colors.blue),
  child: Text('Content'), // childは最後
)
```

### パターン2: 命名とimport
- **library_prefixes**: import時のプレフィックスはlowerCamelCase
- **directives_ordering**: import文の順序を守る

```dart
// ✅ 良い例：importの順序
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // プレフィックスはlowerCamelCase

import 'package:my_app/models/user.dart';
import 'package:my_app/services/api_service.dart';
```

### パターン3: オーバーライドとアノテーション
```dart
// ✅ 良い例：@overrideを必ず付ける（annotate_overrides）
class CustomWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
```

これらのルールを遵守することで、linterエラーを最小限に抑え、一貫性のある高品質なFlutterコードを生成できます。
