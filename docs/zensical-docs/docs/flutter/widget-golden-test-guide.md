# Widget Golden Test ガイド

## 概要

Golden Test（Visual Regression Test）は、Widget のスナップショット（PNG）を事前に記録し、
以降の変更で見た目が壊れていないかを自動検証する手法です。

---

## `loadFonts()` パターン

Golden Test では実際のフォントを読み込まないと日本語が豆腐（□□□）になります。
テストファイルの先頭で `loadFonts()` を呼ぶことで正しいフォントを利用できます。

```dart
import 'package:flutter/services.dart';

Future<void> loadFonts() async {
  // MaterialIcons
  final materialIcons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  // NotoSansJP（日本語フォント）
  final notoSansJp = FontLoader('NotoSansJP')
    ..addFont(rootBundle.load('assets/fonts/NotoSansJP/NotoSansJP-Regular.otf'))
    ..addFont(rootBundle.load('assets/fonts/NotoSansJP/NotoSansJP-Bold.otf'));
  // Roboto
  final roboto = FontLoader('Roboto')
    ..addFont(rootBundle.load('assets/fonts/Roboto/Roboto-Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Roboto/Roboto-Bold.ttf'));

  await materialIcons.load();
  await notoSansJp.load();
  await roboto.load();
}
```

**使用フォントパス**（`pubspec.yaml` に定義済みのパスを使用）:

| フォント名 | パス |
|---|---|
| MaterialIcons | `fonts/MaterialIcons-Regular.otf` |
| NotoSansJP Regular | `assets/fonts/NotoSansJP/NotoSansJP-Regular.otf` |
| NotoSansJP Bold | `assets/fonts/NotoSansJP/NotoSansJP-Bold.otf` |
| Roboto Regular | `assets/fonts/Roboto/Roboto-Regular.ttf` |
| Roboto Bold | `assets/fonts/Roboto/Roboto-Bold.ttf` |

---

## テスト実装パターン

### GoRouter のモック

```dart
import 'package:go_router/go_router.dart';
import 'package:mockito/mockito.dart';

class MockGoRouter extends Mock implements GoRouter {}
```

### 画面の生成ヘルパー

```dart
Widget createScreen() => const ProviderScope(child: MaterialApp(home: Home()));
```

Riverpod を使用している場合は `ProviderScope` でラップします。

### テストケースの実装

```dart
testWidgets('Golden Test for Widget', (WidgetTester tester) async {
  // 1. フォント読み込み（日本語を正しく表示するため必須）
  await loadFonts();

  // 2. 画面サイズを固定（iPhone 14 Pro の物理ピクセル）
  tester.view.physicalSize = const Size(1179, 2556);

  // 3. シャドウを有効化（より実機に近いスクリーンショット）
  debugDisableShadows = false;

  await tester.pumpWidget(createScreen());

  // 4. ゴールデンファイルと比較（または生成）
  await expectLater(
    find.byType(Home),
    matchesGoldenFile('goldens/top_page.png'),
  );

  // 5. シャドウの設定を元に戻す（他のテストへの影響を防ぐ）
  debugDisableShadows = true;
}, tags: 'golden');
```

---

## 実行コマンド

### ゴールデンファイルの生成（初回・更新時）

```bash
flutter test test/path/to/widget_test.dart --tags golden --update-goldens
```

### ゴールデンファイルとの比較（CI・検証時）

```bash
flutter test test/path/to/widget_test.dart --tags golden
```

---

## `goldens/` フォルダの配置ルール

- テストファイルと同じディレクトリに `goldens/` フォルダを作成する
- 生成された PNG ファイルは git で管理する（`.gitignore` から除外）
- ファイル名はテスト対象が分かる名前にする（例: `top_page.png`）

```
test/
  starbucks/
    top/
      top_page_test.dart
      goldens/
        top_page.png        ← git 管理対象
```

---

## ハマりポイント

| 問題 | 原因 | 対処法 |
|---|---|---|
| 日本語が豆腐（□□□）になる | `loadFonts()` を呼んでいない | テストの先頭で `await loadFonts()` を呼ぶ |
| デバイスサイズが変わると差分が出る | `physicalSize` が未設定 | `tester.view.physicalSize` で固定サイズを指定する |
| 他のテストでシャドウが消える | `debugDisableShadows = false` を元に戻していない | テスト終了前に `debugDisableShadows = true` に戻す |
| ゴールデンファイルが見つからない | 初回実行時はファイルが存在しない | `--update-goldens` で先に生成する |
| フォントパスが見つからない | `pubspec.yaml` の `flutter.fonts` の定義と一致していない | `pubspec.yaml` のパスを確認して合わせる |
